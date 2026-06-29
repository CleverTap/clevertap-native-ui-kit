# Native Display SDK - Happy Flow

This doc traces a complete journey: the user does something in the host app,
the CleverTap backend sends back a native-display unit, and the SDK renders
it on screen. We walk it step by step, naming the classes and methods at
each hop.

If you haven't read `ARCHITECTURE.md` yet, skim it first - this doc assumes
you know the major modules (Bridge, Renderer, Placement, etc.).

---

## Setup (one-time, app boot)

Before any unit can render, the host app has to wire two pieces together:
the CleverTap RN SDK (`clevertap-react-native`) and our SDK.

### Step 0a - host app imports the SDKs

```ts
// App.tsx
import CleverTap from 'clevertap-react-native';
import {
  NativeDisplayBridge,
  NativeDisplayView,
} from '@clevertap/native-display-sdk';
```

### Step 0b - host binds the bridge to CleverTap

```ts
useEffect(() => {
  NativeDisplayBridge.shared.bind(CleverTap);
  NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap);
}, []);
```

**What `bind()` does** (in `bridge/NativeDisplayBridge.ts`):

1. Stores the `CleverTap` reference on `this._cleverTap`.
2. Verifies it exposes `addListener`, `pushDisplayUnitViewedEventForID`,
   `pushDisplayUnitClickedEventForID`. Warns if any are missing.
3. Calls `CleverTap.addListener('CleverTapDisplayUnitsLoaded', handler)` so
   future units arriving from the network will fire our handler.

**What `fetchNativeDisplays()` does:**

1. Calls `CleverTap.getAllDisplayUnits()` which is async with a callback.
2. CleverTap returns an array of any units it has already cached locally
   (e.g. delivered before our handler was attached).
3. We extract the raw JSON strings and feed them into `processDisplayUnits()`
   - same code path as live network events take.

After Step 0, the bridge is connected and listening. Nothing renders yet.

---

## Phase 1 - User fires an event, backend responds

The app needs to tell CleverTap something happened. CleverTap's backend
decides whether to send a unit back. This is all standard CleverTap usage,
not our SDK.

### Step 1 - host fires an event

```ts
CleverTap.recordEvent('SomeUserAction', { foo: 'bar' });
```

The CleverTap RN SDK forwards this to the native iOS/Android CleverTap SDK,
which sends it to the CleverTap backend.

### Step 2 - backend evaluates campaigns

Server-side, your campaign configuration says "when `SomeUserAction` fires,
deliver native-display unit X to slot `home_banner`." The backend assembles
a JSON payload that looks something like:

```json
{
  "wzrk_id": "1234567890_20260522",
  "slot_id": "home_banner",
  "native_display_config": {
    "version": "1.0",
    "theme": { "id": "default" },
    "root": {
      "type": "container",
      "id": "root",
      "containerType": "box",
      "layout": { "width": {"value": 100, "unit": "percent"}, ... },
      "children": [...]
    }
  }
}
```

It ships this back over the wire.

### Step 3 - CleverTap native SDK receives the unit

The native CleverTap SDK on iOS/Android parses the server response, finds
the `native_display_config`, and emits a JS-side event called
`CleverTapDisplayUnitsLoaded` carrying the unit (or units).

This event hits **our handler** that was registered in Step 0b.

---

## Phase 2 - Bridge ingests and caches the unit

### Step 4 - bridge receives the event

`NativeDisplayBridge._handleCleverTapDisplayUnitsEvent(event)` runs:

1. Pulls `event.displayUnits` (or treats `event` as an array directly,
   depending on which CT SDK version is in use).
2. Calls `_extractJsonStrings()` to normalize each entry to a string.
3. Calls `processDisplayUnits(jsonStrings)`.

### Step 5 - bridge parses each unit

`processDisplayUnits()` defers the work to the next idle moment via
`deferToIdleAsync()` (so it doesn't block the JS thread mid-frame), then:

```ts
for (const json of jsonStrings) {
  const unit = this._parser.tryParse(json);
  if (unit) units.push(unit);
}
```

`NativeDisplayConfigParser.tryParse()` (`bridge/NativeDisplayConfigParser.ts`)
does the heavy lifting:

1. `JSON.parse(jsonString)` → raw object.
2. Pull `wzrk_id` → that's our `unitId`. Bail if missing.
3. Pull optional `slot_id` and any `custom_kv` extras.
4. **Try three parsing strategies in order**:
   - **Strategy 1**: object has a `native_display_config` key →
     `parseNativeDisplayConfig(obj.native_display_config)` then
     `toResolvedConfig()`.
   - **Strategy 2**: object has `custom_kv.nd_config` as a JSON string →
     parse that string, then do the same.
   - **Strategy 3**: object has `root` at the top level → treat the whole
     thing as a bare config.

   First strategy that doesn't throw wins.
5. Call `StyleResolver.resolveAll(root)` to **pre-compute every node's
   final style**:
   - For each node in the tree, merge `theme.defaultStyle` → matching
     `StyleClass` → inline `style`.
   - Apply `cascadingOnly()` propagation from parent to child so text
     properties inherit but layout properties don't.
   - Build `Record<nodeId, Style>` for the renderer to look up later.
6. Return `NativeDisplayUnit { unitId, config, resolvedStyles, slotId,
   customExtras, rawJson }`.

### Step 6 - bridge caches and notifies

Back in `processDisplayUnits()`:

```ts
for (const unit of units) this._cache.put(unit);
this._notifyListeners(units);
```

`NativeDisplayUnitCache.put()` indexes the unit by `unitId`.
`_notifyListeners()` calls every registered listener's
`onNativeDisplaysLoaded(units)`.

There are typically two kinds of listeners at this point:

- **`NativeDisplaySlotManager`** (registered in its constructor, always
  present).
- **Host app callbacks** if the host registered any (e.g. our example
  app's `TestConfigBrowserScreen` registers one to know when a unit it
  asked for has finished parsing).

---

## Phase 3 - Slot manager routes the unit

### Step 7 - slot manager indexes by slotId

`NativeDisplaySlotManager.onNativeDisplaysLoaded(units)`
(`placement/NativeDisplaySlotManager.ts`):

```ts
for (const unit of units) {
  if (!unit.slotId) continue;
  this._unitIndex.set(unit.slotId, unit);
  const observers = this._slots.get(unit.slotId);
  if (observers) {
    for (const observer of observers) observer.onUnitAvailable(unit);
  }
}
```

Two cases:

- The host has already mounted a `<NativeDisplaySlot slotId="home_banner"/>`
  somewhere - its observer fires immediately.
- The host hasn't mounted that slot yet - the unit sits in `_unitIndex`. If
  a slot mounts later, `registerSlot()` will replay the cached unit to it
  on registration.

### Step 8 - NativeDisplaySlot observer reacts

The `<NativeDisplaySlot>` component registered an observer at mount time.
That observer (`onUnitAvailable`) sets local state with the new unit. React
re-renders the slot, and the slot's JSX returns:

```tsx
<NativeDisplayView unit={this.state.unit} ... />
```

If your host code isn't using slots and is just driving a `<NativeDisplayView
unit={...} />` directly from somewhere else (e.g. our `Browser` tab does
this via the bridge listener), the same `NativeDisplayView` is mounted -
just by a different path.

---

## Phase 4 - NativeDisplayView prepares the render

### Step 9 - measure root size

`NativeDisplayView` (`renderer/NativeDisplayView.tsx`) does **two-phase
measurement**:

- **First render**: returns an empty `<View>` with an `onLayout` listener.
  No content yet; we just want to know how wide the host gave us.
- **`onLayout` fires**: calls `handleLayout()` which captures
  `event.nativeEvent.layout.width` and `.height`, sets local state.
- **Second render**: now we know `rootSize`. The View gets an explicit
  `width: rootSize.width` style (so children can resolve percent widths
  against a definite parent) and renders the actual content.

The host can short-circuit measurement by passing
`availableSize={{width, height}}` directly.

### Step 10 - fire "Notification Viewed"

Once `rootSize` is known and there's a `root` to render, a `useEffect` fires
exactly once:

```ts
NativeDisplayBridge.shared.pushViewedEvent(unitId);
actionListener?.onDisplayUnitViewed?.(unitId);
actionListener?.onTrackEvent?.('Notification Viewed', undefined);
```

The bridge forwards to `CleverTap.pushDisplayUnitViewedEventForID(unitId)`
which records the impression on the backend.

### Step 11 - construct the action handler

```ts
const actionHandler = new ActionHandler(
  actionListener,           // host's high-level listener
  componentListener,        // host's low-level listener
  unitId ? NativeDisplayBridge.shared : null,  // for pushClickedEvent
  unitId,
);
```

One `ActionHandler` instance per render, passed down through the tree.

### Step 12 - wire contexts and render the tree

The component returns:

```tsx
<View style={[{ width: rootSize.width }, style]} onLayout={...}>
  <RenderErrorBoundary key={unitId}>
    <RootSizeProvider size={rootSize}>
      <FontProvider fontResolver={fontResolver}>
        <VariablesProvider variables={variables}>
          <RenderNode
            node={root}
            resolvedStyles={resolvedStyles}
            actionHandler={actionHandler}
          />
        </VariablesProvider>
      </FontProvider>
    </RootSizeProvider>
  </RenderErrorBoundary>
</View>
```

Everything below `RenderErrorBoundary` can throw without crashing the host.

---

## Phase 5 - Recursive node rendering

### Step 13 - RenderNode dispatches by node type

`RenderNode` (`renderer/RenderNode.tsx`) for each node:

1. **Check visibility.** If `node.visible` is a templated boolean
   expression (e.g. `"{{userType == 'premium'}}"`), run
   `VariableEvaluator.evaluateBoolean()`. If it returns false, return
   `null` and skip the subtree.
2. **Look up the pre-resolved style.** `resolvedStyles[node.id]` was
   computed back in Step 5.
3. **Fire lifecycle action** if `node.actions.onAppear` is set
   (`ActionHandler.handleLifecycle()`). Mirror on unmount for `onDisappear`.
4. **Dispatch to the right component**:
   - **Container?** → `<VerticalContainer>`, `<HorizontalContainer>`,
     `<BoxContainer>`, or `<GalleryContainer>`.
   - **Element?** → `<TextElement>`, `<ImageElement>`, `<ButtonElement>`,
     `<VideoElement>`, `<HtmlElement>`, `<SpacerElement>`, `<DividerElement>`.
5. **Wrap in EntranceAnimation** if `node.animation` is set (and not
   `"none"`).
6. **For elements only**: wrap in `<BackgroundRenderer>` if the style has a
   `background`. (Containers paint their own background internally so it's
   clipped to the container's bounds.)
7. **Apply offset transform** for any non-zero `dp`-unit offset on a non-BOX
   child (BoxContainer handles percent offsets explicitly; non-BOX
   containers can only use dp offsets, applied as a CSS-style translate).

### Step 14 - Container renders its children

Example: `VerticalContainer`. It:

1. Reads `useRootSize()` and `useParentSize()` to know what its width and
   height should resolve to.
2. Reads `useState(measuredHeight)` to remember its own height after
   `onLayout` fires (used for the absolute-positioned background).
3. Computes `layoutStyle` via `resolveLayoutStyle(layout, rootHeight)` -
   that's the React Native style object derived from the JSON's `layout`
   field (padding, dimensions, arrangement, etc).
4. Computes `nodeStyle` via `resolveNodeStyle(resolvedStyle, rootHeight)` -
   the visual style derived from the pre-resolved Style (border, shadow,
   bg color, etc).
5. Builds a children list, interleaving any `dividerConfig` lines between
   them.
6. Renders:
   ```tsx
   <View onLayout={handleContainerLayout} style={[...]}>
     {background && <BackgroundRenderer .../>}
     {children.map(child => <RenderNode node={child} .../>)}
   </View>
   ```
7. Each child re-enters `RenderNode` and the recursion continues.

(Box and Gallery have more elaborate internal logic - Box pre-computes
absolute pixel positions for its children based on percent offsets,
Gallery wires up a `FlatList` with snap intervals and peek padding.)

### Step 15 - Element renders the leaf

Example: a `<TextElement>` is reached.

1. Splits the resolved style into `viewStyle` (border, bg, shadow) and
   `textStyle` (color, font, alignment) via `splitNodeStyle()`.
2. Looks up the actual font name to use via `useFontContext()` + the
   host-supplied `fontResolver`.
3. Templates the text content - if it contains `{{varName}}`, runs
   `VariableEvaluator.evaluateString()` to substitute.
4. Renders `<View style={viewStyle}><Text style={textStyle}>...</Text></View>`.

`<ImageElement>` checks `optionalDeps.getExpoImage()` first (preferred when
Expo is detected), falls back to `getFastImage()`, falls back to RN's
built-in `<Image>`.

`<ButtonElement>` renders a `<Pressable>` wrapped around the text. Its
`onPress` handler:

1. Calls `actionHandler.fireClickedEvent(nodeId)` to always record the
   click event, regardless of whether there's an action defined.
2. If there's an action, calls `actionHandler.handle(action, nodeId,
   'click')`.

---

## Phase 6 - User taps a button

### Step 16 - press fires the action handler

`<Pressable>` fires `onPress`. `ButtonElement.handlePress()`:

```ts
actionHandler.fireClickedEvent(nodeId);
if (action) actionHandler.handle(action, nodeId, 'click');
```

### Step 17 - fireClickedEvent broadcasts

`ActionHandler.fireClickedEvent(nodeId)` (`handler/ActionHandler.ts`):

```ts
this.bridge?.pushClickedEvent(this.unitId);
this.actionListener?.onDisplayUnitClicked?.(this.unitId);
this.actionListener?.onTrackEvent('Notification Clicked', { nodeId });
```

- The bridge forwards to
  `CleverTap.pushDisplayUnitClickedEventForID(unitId)` (analytics).
- The host's `actionListener` (if registered) is notified twice: once with
  the unit-level click, once with the generic track-event format.

### Step 18 - handle() dispatches the configured action

`ActionHandler.handle(action, nodeId, interactionType)`:

1. **Component listener short-circuit.** If the host registered a
   `componentListener` and it expressed interest in this node, give it
   first dibs. If `onComponentInteraction()` returns true, the action is
   consumed and we stop.
2. **Dispatch by action type** in `_dispatch()`:

   | `action.type` | Behavior |
   |---|---|
   | `open_url` | Calls `resolveOpenUrl()` to pick the per-platform URL. Validates scheme (only `http`, `https`, `tel`, `mailto`). If the host's `actionListener.onOpenUrl()` returns true, stop. Else `Linking.openURL(url)`. |
   | `custom` | Calls `actionListener.onCustomAction(key, value, metadata)`. The host decides what to do. |
   | `navigate` | Calls `actionListener.onNavigate(destination, params)`. |
   | `event` | Calls `actionListener.onTrackEvent(eventName, properties)`. |
   | `composite` | Recursively dispatches every sub-action in `action.actions`. |

The user's tap has now caused all the right side effects: an analytics
event, optionally a deep-link open, and optionally a host callback. The
rendered UI itself doesn't change unless the host explicitly does something
in response.

---

## Full call chain summary

Here's the same flow as a single chain of "who calls what":

```
1.  Host                       CleverTap.recordEvent('foo')
2.  CleverTap network          →→→ to backend, evaluates campaign
3.  CleverTap native SDK       receives unit, emits 'CleverTapDisplayUnitsLoaded'
4.  NativeDisplayBridge        ._handleCleverTapDisplayUnitsEvent(event)
5.                             .processDisplayUnits([json,...])
6.                                deferToIdleAsync(() => {
7.                                  NativeDisplayConfigParser.tryParse(json)
8.                                    → tryParseNativeDisplayConfig | _tryParseFromCustomKv | _tryParseAsRootConfig
9.                                    StyleResolver.resolveAll(root)
10.                                 NativeDisplayUnitCache.put(unit)
11.                                 _notifyListeners([unit])
12.                                })
13. NativeDisplaySlotManager   .onNativeDisplaysLoaded([unit])
14.                            .observer.onUnitAvailable(unit)
15. <NativeDisplaySlot>        setState(unit), re-renders
16. <NativeDisplayView>        first render returns empty <View onLayout/>
17.                            onLayout fires, captures rootSize
18.                            second render with width=rootSize.width
19.                            useEffect: bridge.pushViewedEvent(unitId)
                                          + listener.onDisplayUnitViewed
                                          + listener.onTrackEvent('Notification Viewed')
20.                            new ActionHandler(...)
21.                            <RenderNode node={root} .../>
22. <RenderNode>               (for each node, recursive)
23.                              VariableEvaluator.evaluateBoolean(node.visible)
24.                              resolvedStyles[node.id]
25.                              ActionHandler.handleLifecycle(onAppear) if any
26.                              dispatch to <Container> or <Element>
27. <VerticalContainer> etc.   reads useRootSize, useParentSize, useState(measuredHeight)
28.                            resolveLayoutStyle, resolveNodeStyle
29.                            renders <View>, recursively renders children
30. <TextElement> etc.         splitNodeStyle, useFontContext.resolveFont
31.                            VariableEvaluator.evaluateString(text)
32.                            renders <View><Text>...</Text></View>
33. <ButtonElement>            <Pressable onPress={handlePress}>
─── user taps ───
34. handlePress                ActionHandler.fireClickedEvent(nodeId)
35. ActionHandler              bridge.pushClickedEvent(unitId)
                               listener.onDisplayUnitClicked + onTrackEvent
36. ActionHandler              .handle(action, nodeId, 'click')
37.                            componentListener.onComponentInteraction (short-circuit?)
38.                            _dispatch(action) → Linking.openURL / listener callbacks
```

That's the entire happy path.

---

## Where errors get caught

The flow above assumes everything works. Three places quietly absorb
failures so the host app doesn't crash:

| Where | What it catches | What you see |
|---|---|---|
| `NativeDisplayConfigParser.tryParse()` | Malformed JSON, unknown fields, type mismatches. | `console.warn`; returns `null`; the unit is dropped. |
| `_notifyListeners()` in the bridge | Listeners that throw. | `console.error`; other listeners still get called. |
| `RenderErrorBoundary` around the tree | Any render-time error inside the tree (bad node type, null-deref, etc). | `console.error`; the affected unit becomes an empty `<View>`; the rest of the app keeps running. |

A bad payload from the server cannot take down the host app.

---

## Quick sanity check - what would you change to add a new node type?

Walk through your understanding by tracing the changes for "add a `lottie`
element type":

1. **Model**: in `models/NativeDisplayNode.ts`, add `'lottie'` to the
   `ElementType` union.
2. **Optional dep**: in `optional/optionalDeps.ts`, add `getLottie()` that
   `tryLoad()`s `lottie-react-native`.
3. **Renderer**: create `renderer/elements/LottieElement.tsx`. Take `node`
   and `resolvedStyle`. Use the optional dep, fall back to a placeholder if
   missing.
4. **Dispatch**: in `renderer/RenderNode.tsx`, add a `case 'lottie':` in
   the element switch.
5. **PeerDep**: add `lottie-react-native` to `peerDependencies` and
   `peerDependenciesMeta` (as optional).
6. **Done.** Parser, bridge, slot manager, action handler, all stay
   unchanged - they don't know or care about specific node types.

If you can answer that confidently, you understand the SDK.
