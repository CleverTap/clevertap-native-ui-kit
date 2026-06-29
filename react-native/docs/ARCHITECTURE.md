# Native Display SDK - Architecture

This doc walks through how the SDK is organized. Read it once and you'll know
where every responsibility lives and why each module exists. No prior knowledge
of the SDK assumed.

## What this SDK actually does

The CleverTap backend can send your app a chunk of JSON that describes a UI -
text, images, buttons, colors, layout, the works. This SDK takes that JSON and
turns it into real React Native views on the screen. You don't need to write
any UI code for the rendered content; the JSON is the source of truth.

Conceptually there are **three phases**:

1. **Receive** - the JSON arrives from the CleverTap RN SDK (`clevertap-react-native`).
2. **Parse + cache** - we turn the JSON into a typed in-memory tree and store it.
3. **Render** - when a React component asks for it, we walk the tree and produce
   real `<View>`/`<Text>`/`<Image>` etc.

The SDK is **pure JavaScript / TypeScript**. There is no native iOS or Android
code in this package. Anything platform-specific (CleverTap network calls, the
underlying native UI primitives like `View`, `Image`, etc.) is borrowed from
`clevertap-react-native` and React Native itself.

---

## Top-level folder map

Everything lives under `react-native/src/`:

```
src/
├── index.ts            ← public exports (the SDK's API surface)
├── bridge/             ← talks to CleverTap, owns the cache
├── placement/          ← named "slots" - put a unit at a location by id
├── renderer/           ← turns parsed JSON into real RN views
│   ├── containers/     ← layout boxes (vertical / horizontal / box / gallery)
│   └── elements/       ← leaves (text / image / button / video / ...)
├── models/             ← the JSON's TypeScript shape (Layout, Style, Action, ...)
├── style/              ← merges inline + class + theme styles into one final style
├── evaluator/          ← {{variable}} templating and boolean expressions
├── handler/            ← what happens when a user taps a button
├── listener/           ← interfaces the host app implements to receive events
├── context/            ← React contexts (rootSize, parentSize, font, variables)
├── optional/           ← graceful require() of optional native deps
└── utils/              ← color parsing, dimension math, scheduling helpers
```

You can also think of it as a 5-layer stack, bottom to top:

```
┌────────────────────────────────────────────────────────┐
│  HOST APP - your screens, your buttons                 │
├────────────────────────────────────────────────────────┤
│  Renderer    (NativeDisplayView, RenderNode, Containers, Elements)
│              Turns a parsed unit into <View>s on screen.
├────────────────────────────────────────────────────────┤
│  Placement   (NativeDisplaySlotManager, NativeDisplaySlot)
│              "Show whatever unit comes in for slot X."
├────────────────────────────────────────────────────────┤
│  Bridge      (NativeDisplayBridge, Parser, Cache)
│              Receives JSON, parses, caches, notifies listeners.
├────────────────────────────────────────────────────────┤
│  CleverTap RN SDK   (clevertap-react-native)
│              Provides real CleverTap API calls + display unit events.
└────────────────────────────────────────────────────────┘
```

Each layer only knows about the one beneath it. The Renderer doesn't know
where the JSON came from, the Bridge doesn't know how things get rendered.

---

## Layer 1: Bridge - talking to CleverTap

**Folder:** `src/bridge/`

This is the SDK's "front door." Everything that comes from CleverTap funnels
through here.

### `NativeDisplayBridge` (singleton, `bridge/NativeDisplayBridge.ts`)

The one object that wires the CleverTap SDK to the rest of the world. You always
access it as `NativeDisplayBridge.shared`.

Key methods:

| Method | What it does |
|---|---|
| `bind(cleverTap)` | Hands the bridge a reference to the CleverTap SDK instance, and subscribes to its `CleverTapDisplayUnitsLoaded` event. |
| `fetchNativeDisplays(cleverTap)` | Pulls any units the CleverTap SDK has already cached (units delivered before our listener was attached) and processes them. |
| `processDisplayUnit(jsonString)` | Parse one JSON string and add it to the cache. |
| `processDisplayUnits(jsonStrings[])` | Same, but a batch. |
| `addListener(listener)` | Register a callback that fires whenever new units land. |
| `getAllNativeDisplays()` | All currently cached units. |
| `getNativeDisplayForId(unitId)` | Look up a unit by its `wzrk_id`. |
| `pushViewedEvent(unitId)` | Tell CleverTap "this unit was seen" (fires "Notification Viewed"). |
| `pushClickedEvent(unitId)` | Tell CleverTap "this unit was tapped" (fires "Notification Clicked"). |

Why a singleton? Because a unit might be delivered before any UI listens. The
bridge has to live as long as the app does, hold the cache, and replay units
to whoever shows up later.

### `NativeDisplayConfigParser` (`bridge/NativeDisplayConfigParser.ts`)

Given a raw JSON string, this returns a `NativeDisplayUnit` or null. The
trickiest part is that CleverTap's payload format varies - we try **three
parsing strategies** in order:

1. JSON has a `native_display_config` key (modern advanced builder responses).
2. JSON has `custom_kv.nd_config` as a stringified config (older format).
3. JSON has a `root` key at the top level (we're being handed a bare config).

First strategy that succeeds wins.

Once parsed, this calls `StyleResolver` to **pre-compute every node's final
style**, so the renderer never has to walk the theme/class/inline merge chain
at render time.

### `NativeDisplayUnit` (type, `bridge/NativeDisplayUnit.ts`)

The cached, parsed thing. Just a plain interface:

```ts
{
  unitId: string;          // wzrk_id from the response
  config: ResolvedConfig;  // theme + root tree + variables
  resolvedStyles: ResolvedStyles;  // node id → final Style
  slotId?: string;         // from CT's slot_id, optional
  customExtras: Record<string, string>;  // custom_kv minus nd_config
  rawJson?: string;        // original string for debugging
}
```

### `NativeDisplayUnitCache` (`bridge/NativeDisplayUnitCache.ts`)

A `Map<unitId, unit>`. Nothing exotic.

### `cleverTapAutoWire.ts`

One helper - `wireCleverTap(cleverTap)`. It's literally a wrapper around
`NativeDisplayBridge.shared.bind()`. Convenience for the most common host
integration.

---

## Layer 2: Placement - slot routing

**Folder:** `src/placement/`

A "slot" is a named location in your UI (e.g. `"home_top_banner"`,
`"product_card_promo"`). The backend tags each unit with a `slot_id`. The
host app declares which slots it cares about, and the SDK delivers the
right unit to the right slot.

### `NativeDisplaySlotManager` (singleton)

Subscribes to the bridge. When new units arrive, it indexes them by `slotId`
and notifies any observer registered for that slot. If a unit was already
cached when a new observer registers, it replays it immediately so the slot
fills in without waiting for the next fetch.

Key methods:

| Method | What it does |
|---|---|
| `registerSlot(slotId, observer)` | Start receiving units for this slot. |
| `unregisterSlot(slotId, observer)` | Stop receiving. |
| `clearSlot(slotId)` / `clearAll()` | Drop cached unit(s) for a slot. |
| `syncCurrentSlotIds(cleverTap)` | Tell CT which slots the app currently cares about. |

### `NativeDisplaySlot` (React component)

Drop this into your JSX where you want a slot to live:

```tsx
<NativeDisplaySlot slotId="home_top_banner" />
```

It registers with the manager on mount, unregisters on unmount, and renders
`NativeDisplayView` once a unit arrives.

---

## Layer 3: Renderer - JSON to pixels

**Folder:** `src/renderer/`

This is the biggest layer. It takes a parsed `NativeDisplayUnit` and produces
a tree of React Native views.

### `NativeDisplayView` (component, `renderer/NativeDisplayView.tsx`)

The host-facing root component. You give it either a unit (looked up from the
bridge) or a raw config (e.g. for testing). It:

1. Measures itself via `onLayout` to know how much horizontal space it has
   (`rootSize.width`). Falls back to `Dimensions.get('window')` until the
   first measurement arrives.
2. Provides `RootSizeContext` so descendants can resolve percent dimensions.
3. Provides `FontContext` and `VariablesContext`.
4. Mounts the root `RenderNode` inside a `RenderErrorBoundary` (so a bad
   payload can't crash the host).
5. Fires `pushViewedEvent` once on mount (the "Notification Viewed"
   analytics event).

### `RenderNode` (component, `renderer/RenderNode.tsx`)

The polymorphic renderer. Given any node in the tree (container or element),
it picks the right sub-component and delegates. Also handles:

- **Visibility expressions.** If `node.visible = "{{userType == 'premium'}}"`,
  it asks `VariableEvaluator` whether to render at all.
- **Lifecycle actions.** `onAppear` / `onDisappear` actions fire here via
  `ActionHandler`.
- **Entrance animations.** Wraps content in `EntranceAnimation` if requested.
- **Background.** For element nodes only, wraps in `BackgroundRenderer`
  (container nodes do their own backgrounds internally - see below).
- **Offset.** For non-BOX children, applies any dp-based `offset` as a CSS
  transform.

The actual rendering of children happens by recursion: a container's
sub-component calls back into `RenderNode` for each of its children.

### Container subcomponents

**Folder:** `src/renderer/containers/`

Containers hold children. There are four:

| Type | What it does | RN primitive |
|---|---|---|
| `VerticalContainer` | Lays children out top-to-bottom (column flex). | `<View>` with `flexDirection: 'column'` |
| `HorizontalContainer` | Left-to-right (row flex). | `<View>` with `flexDirection: 'row'` |
| `BoxContainer` | Absolute positioning - children placed via `offset`. Children's percent dimensions resolve against the box's own pixel size, computed synchronously. | `<View>` with `position: 'relative'`, each child wrapped in `position: 'absolute'` |
| `GalleryContainer` | Horizontal or vertical scrolling list with snapping, peek, indicators, arrows. | `<FlatList>` |

Each container reads its **own resolved width and height** from a hierarchy
of contexts:

1. **`useParentSize()`** - what the parent told me my size is (for nested
   containers).
2. **`useRootSize()`** - the NativeDisplayView's measured size (fallback at
   the top of the tree).

Each container then wraps its children in `ParentSizeProvider` so its
grandchildren can resolve `width: '100%'` correctly. This is the chain that
makes percent dimensions work everywhere in the tree, not just at root.

### Element subcomponents

**Folder:** `src/renderer/elements/`

Leaves of the tree:

| File | What it renders |
|---|---|
| `TextElement` | `<View><Text/></View>` (wrapper for borderRadius + overflow). Supports text gradients via MaskedView + LinearGradient. |
| `ImageElement` | Picks the best available image lib: `expo-image` > `react-native-fast-image` > built-in RN `<Image>`. |
| `ButtonElement` | A pressable text. Fires `ActionHandler.fireClickedEvent()` + dispatches the configured action. |
| `VideoElement` | `react-native-video`'s `<Video>` if available, else a placeholder. |
| `HtmlElement` | `react-native-webview`'s `<WebView>`. |
| `SpacerElement` | Empty `<View>` with fixed size - used for visual spacing in flex layouts. |
| `DividerElement` | A 1-pixel line. |

### `BackgroundRenderer` (`renderer/BackgroundRenderer.tsx`)

Renders the `background` style field. Different "type" values pick different
implementations:

| `type` | Implementation |
|---|---|
| `solid` | `<View>` with `backgroundColor` |
| `linear_gradient` | `LinearGradient` from `react-native-linear-gradient` or `expo-linear-gradient` |
| `radial_gradient`, `sweep_gradient` | SVG via `react-native-svg` |
| `animated_gradient` | LinearGradient + `react-native-reanimated` |
| `shimmer`, `pulse` | reanimated-driven overlays |
| `image` | `<Image>` with optional blur + tint |
| `pattern` | SVG pattern |
| `particles` | static dots (simplified animated bg) |
| `layered` | recursively renders an array of backgrounds stacked |

All implementations gracefully fall back to a solid color if the required
native module isn't installed.

### Other renderer helpers

- **`layoutModifier.ts`** - turns `Layout` (model) into a React Native style
  object. Resolves percent dimensions, spacing, offsets, borderRadius.
- **`arrangement.ts`** - turns a `ChildArrangement` (e.g. `space-between`)
  into flex `justifyContent` / `gap` style values.
- **`styleSplit.ts`** - splits a merged Style into "goes on the View wrapper"
  vs "goes on the inner Text" buckets.
- **`EntranceAnimation.tsx`** - reanimated-driven entry animations.
- **`RenderErrorBoundary.tsx`** - catches any render-time error inside a
  unit and shows a blank `<View>` instead of crashing the host app.

---

## Layer 4: Models - the JSON's shape

**Folder:** `src/models/`

Pure TypeScript types and small parser/normalizer functions. No React or RN
imports here.

- **`NativeDisplayNode.ts`** - the polymorphic node union (`Container` vs
  `Element`) and the type guards `isContainer` / `isElement`.
- **`NativeDisplayConfig.ts`** - the top-level structure: theme + root +
  variables + styleClasses, plus `toResolvedConfig()` which converts the
  parsed shape into the optimized rendering shape (`ResolvedConfig`).
- **`Layout.ts`** - dimensions, padding, offset, arrangement. Includes
  helpers like `resolveSpacingTop()`.
- **`Style.ts`** - all visual properties: colors, borders, shadows, font,
  text decoration. Includes `mergeStyles` (cascade order: theme → class →
  inline) and `cascadingOnly` (filter out properties that shouldn't
  inherit from parent to child).
- **`Action.ts`** - actions: `open_url`, `custom`, `navigate`, `event`,
  `composite`. Plus `resolveOpenUrl()` which picks the platform-correct URL
  from `{android: "...", ios: "..."}` shapes.
- **`Background.ts`** - background variants (solid, gradient, image, etc).
- **`Animation.ts`** - entrance animation config.
- **`GalleryConfig.ts`** - the gallery container's behavior config (mode,
  spacing, peek, columns, indicators).
- **`enums.ts`** - shared enums (`DimensionUnit`, `SpecialDimension`, etc).

---

## Layer 5: Style resolution

**Folder:** `src/style/`

### `StyleResolver` (`style/StyleResolver.ts`)

Computes the **final** style for every node in the tree by:

1. Starting from `theme.defaultStyle` (e.g. default text color, default font).
2. Merging in the node's `styleClass` if one applies (named, reusable styles).
3. Merging in the node's inline `style`.
4. Walking down to children with `cascadingOnly()` so text properties
   propagate (children inherit `textColor`, `fontFamily`, etc) but layout
   properties don't.

The output is `ResolvedStyles` - a `Record<nodeId, Style>` that the renderer
just looks up. No cascading at render time.

This is done **once at parse time** (`NativeDisplayConfigParser` calls it).

---

## Other modules

### `context/`

Four React contexts:

| Context | Provided by | Used by |
|---|---|---|
| `RootSizeContext` | `NativeDisplayView` | Anything that needs the unit's overall pixel size |
| `ParentSizeContext` | Containers (each one provides its own resolved size to its children) | Nested containers/elements resolving `width: '100%'` and `height: '100%'` |
| `FontContext` | `NativeDisplayView` (with optional `fontResolver` prop) | Text elements that need to map a JSON font name to a real iOS/Android font |
| `VariablesContext` | `NativeDisplayView` | `RenderNode` and `TextElement` for `{{variable}}` substitution |

### `evaluator/VariableEvaluator.ts`

Two responsibilities:

- **String templating.** `"Hello {{userName}}"` → `"Hello Akash"`.
- **Boolean expressions.** Powers the `node.visible` field. Supports
  comparison operators (`==`, `!=`, `>=`, `<=`, `>`, `<`), `&&` / `||`,
  and `{{varName}}` substitutions.

### `handler/ActionHandler.ts`

The router for "something happened, do something." Created fresh inside
`NativeDisplayView` and passed down to every element. Methods:

| Method | When called |
|---|---|
| `fireClickedEvent(nodeId)` | Every button press, regardless of whether it has an action. Records the "Notification Clicked" event. |
| `handle(action, nodeId, interactionType)` | After fireClickedEvent. Either lets a `componentListener` consume the interaction, or dispatches the configured action (open URL, fire custom callback, etc). |
| `handleLifecycle(action, nodeId, trigger)` | For `onAppear` / `onDisappear` actions. |

Dispatch supports the same action types defined in `models/Action.ts`. URL
opening goes through `Linking.openURL()` unless the host's listener says
it handled it.

### `listener/`

Two interfaces that the host app implements to receive callbacks:

- **`NativeDisplayActionListener`** - high-level events: viewed, clicked,
  open URL, custom action, navigate, track event.
- **`NativeDisplayComponentListener`** - lower-level: intercept individual
  component interactions before they reach the action handler. Useful for
  filtering or augmenting.

### `optional/optionalDeps.ts`

The graceful-degradation layer. Every optional native dep
(`react-native-linear-gradient`, `react-native-reanimated`, `react-native-svg`,
`react-native-video`, `react-native-webview`, `@react-native-masked-view/...`,
`expo-image`, `react-native-fast-image`, `expo-linear-gradient`,
`@react-native-community/blur`) is loaded through a `tryLoad<T>()` helper:

- First call: attempt `require()`. If it works, cache the module. If it
  throws (module not installed), cache a `NOT_INSTALLED` sentinel and warn.
- Subsequent calls: return cached value, no retry.

This file also has the **Expo awareness** - it prefers `expo-linear-gradient`
and `expo-image` when `process.env.EXPO_OS` is defined (Expo's babel preset
inlines that variable). On bare React Native projects, the variable is
undefined and the SDK falls back to the bare-RN equivalents.

### `utils/`

- **`color.ts`** - parses `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `rgb()`, `rgba()`,
  named colors. Returns RN's preferred normalized format.
- **`dimension.ts`** - resolves text dimensions and border widths/radii
  against the root size for percent-based values.
- **`threading.ts`** - `deferToIdleAsync()`, which yields to the JS thread
  before doing heavy work (used by the bridge so parsing doesn't block UI).

---

## Public API surface

The SDK exports exactly the following from `src/index.ts`:

```ts
// Classes / components
NativeDisplayBridge        // singleton, access via .shared
NativeDisplaySlotManager   // singleton, access via .shared
NativeDisplaySlot          // <NativeDisplaySlot slotId="..."/>
NativeDisplayView          // <NativeDisplayView unit={...} config={...}/>

// Helper
wireCleverTap(cleverTap)   // shortcut for NativeDisplayBridge.shared.bind()

// Types
NativeDisplayUnit, NativeDisplayConfig, NativeDisplayNode, ResolvedStyles,
NativeDisplayBridgeListener, NativeDisplayActionListener,
NativeDisplayComponentListener, NativeDisplaySlotObserver, InteractionType
```

Everything else is internal.

---

## Design principles you'll see throughout

1. **Pre-compute, don't re-compute.** Styles are resolved once at parse time
   and looked up at render time. Same for box dimensions in BoxContainer.

2. **Singletons for cross-screen state.** `NativeDisplayBridge.shared` and
   `NativeDisplaySlotManager.shared` are app-wide because units may arrive
   before any UI listens, and we need to replay them.

3. **Context cascades, not prop drilling.** RootSize, ParentSize,
   Variables, and Font are all React contexts. Containers explicitly
   propagate ParentSize to their children so percent dimensions resolve
   correctly at every level.

4. **Pixel values, not percents, whenever we can.** On iOS Fabric, Yoga
   often refuses to resolve `width: '100%'` against ScrollView-rooted
   parents, falling back to intrinsic content size. The SDK substitutes
   the parent's actual pixel value before handing the style to Yoga so the
   layout is correct.

5. **Graceful degradation.** Every optional native dep can be missing.
   Linear gradients fall back to a solid color; SVG patterns become a flat
   bg color; videos become a placeholder. The unit still renders.

6. **Don't crash the host.** Every render is wrapped in
   `RenderErrorBoundary`. A bad JSON payload collapses to an empty `<View>`
   instead of taking the app down.

7. **Mirror Android/iOS semantics.** This SDK is one of three (Android,
   iOS, RN); they all consume the same JSON and aim for pixel-level parity.
   When in doubt, look at how the Android Compose renderer does it - many
   of the trickier rules (BoxContainer dimension priority order, gallery
   `Modifier.fillMaxWidth()`, etc) are intentionally ported one-for-one.

---

## Where to read next

- **`HAPPY_FLOW.md`** (in this folder) - end-to-end trace of an event firing
  in your app to a rendered unit appearing on screen. Use it to see all the
  classes in this doc actually working together.
- **`react-native/src/index.ts`** - quickest way to see the public API.
- **`react-native/example/screens/`** - real working code that uses every
  layer.
