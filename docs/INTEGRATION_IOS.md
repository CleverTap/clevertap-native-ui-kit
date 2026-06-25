# iOS Integration — CleverTap Native Display SDK

Render server-driven native UI campaigns on iOS using SwiftUI — with first-class UIKit and Objective-C support. No WebViews.

← Back to the [project README](../README.md) · For the cross-platform JSON spec see [JSON Structure Reference](JSON_STRUCTURE_REFERENCE.md) · For Android see [Android Integration](INTEGRATION_ANDROID.md).

---

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Prerequisite: CleverTap Core SDK](#prerequisite-clevertap-core-sdk)
- [Approach 1 — Slot-based integration (recommended)](#approach-1--slot-based-integration-recommended)
- [Approach 2 — Custom rendering](#approach-2--custom-rendering)
- [Fetch on demand](#fetch-on-demand)
- [Event hooks](#event-hooks)
- [Custom fonts](#custom-fonts)
- [Troubleshooting](#troubleshooting)

---

## Requirements

| | Minimum |
|----------|---------|
| iOS | 15.0+ |
| Swift | 5.5+ |
| UI | SwiftUI (UIKit and Objective-C supported via wrappers) |

---

## Installation

Add the package in Xcode via **File → Add Package Dependencies**:

```
https://github.com/CleverTap/clevertap-native-ui-kit
```

Or add it to your `Package.swift`:

```swift
.package(url: "https://github.com/CleverTap/clevertap-native-ui-kit.git", from: "<version>")
```

---

## Prerequisite: CleverTap Core SDK

The Native Display SDK is a renderer — display unit JSON is delivered by the [CleverTap iOS Core SDK](https://github.com/CleverTap/clevertap-ios-sdk). Install and initialize it before going further.

Two integration paths are supported:

- **Approach 1 (slot-based)** — recommended for most apps. The SDK manages discovery, listening, attribution, and lifecycle.
- **Approach 2 (custom rendering)** — for hosts that need to inspect units, place them in custom layouts, or run standalone without the Core SDK.

You can also run the Display SDK in standalone mode (no Core SDK) and feed JSON manually — see [Approach 2](#approach-2--custom-rendering).

---

## Approach 1 — Slot-based integration (recommended)

The slot flow is the shortest path to a working integration. Your only job is to declare *where* a unit can appear and *which* slot ID maps to it.

**Step 1 — Initialize the bridge** in your app entry point.

SwiftUI (`App.init()`):
```swift
@main
struct MyApp: App {
    init() {
        NativeDisplayBridge.shared.initialize()
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
```

<details>
<summary><b>UIKit (Swift, AppDelegate)</b></summary>

```swift
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    NativeDisplayBridge.shared.initialize()
    return true
}
```
</details>

<details>
<summary><b>Objective-C (AppDelegate.m)</b></summary>

```objc
#import <CleverTapNativeDisplay/CleverTapNativeDisplay-Swift.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NativeDisplayBridge shared] initialize];
    return YES;
}
```
</details>

**Step 2 — Link with CleverTap Core** so server-pushed units flow into the bridge. Bind the Core SDK instance once it's available.

Swift:
```swift
if let cleverTap = CleverTap.sharedInstance() {
    NativeDisplayBridge.shared.bind(cleverTap)
}
```

<details>
<summary><b>Objective-C</b></summary>

```objc
CleverTap *cleverTap = [CleverTap sharedInstance];
if (cleverTap != nil) {
    [[NativeDisplayBridge shared] bind:cleverTap forwardTo:nil];
}
```
</details>

**Step 3 — Drop a slot view** in your UI with the slot ID configured on the dashboard. The SDK looks it up, picks the matching unit, and renders it. While no unit is present, the slot shows your placeholder (or stays empty by default).

SwiftUI:
```swift
NativeDisplaySlot(slotId: "hero_banner") {
    // optional placeholder view, e.g. ProgressView()
}
```

<details>
<summary><b>UIKit (Swift)</b></summary>

`NativeDisplaySlotUIView` is a regular `UIView` — no `UIHostingController` needed:
```swift
final class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let slot = NativeDisplaySlotUIView(slotId: "hero_banner")
        slot.actionListener = myActionListener
        slot.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slot)
        NSLayoutConstraint.activate([
            slot.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            slot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            slot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
```
</details>

<details>
<summary><b>UIKit (Objective-C)</b></summary>

```objc
#import <CleverTapNativeDisplay/CleverTapNativeDisplay-Swift.h>

- (void)viewDidLoad {
    [super viewDidLoad];
    NativeDisplaySlotUIView *slot = [[NativeDisplaySlotUIView alloc] initWithSlotId:@"hero_banner"];
    slot.actionListener = self.myActionListener;
    slot.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:slot];
    [NSLayoutConstraint activateConstraints:@[
        [slot.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [slot.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [slot.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}
```
</details>

For list-driven UIs, the SDK ships cell wrappers: `NativeDisplaySlotTableViewCell.configure(slotId:)` for `UITableView` and `NativeDisplaySlotCollectionViewCell.configure(slotId:)` for `UICollectionView`. Both are usable from Swift and Objective-C, e.g. `[cell configureWithSlotId:@"hero_banner" actionListener:nil componentListener:nil];`.

> **When do I need `UIHostingController`?** Only if you want to embed the SwiftUI `NativeDisplayView` directly in a UIKit screen. The UIKit wrappers above (`NativeDisplaySlotUIView`, `NativeDisplayUIView`, and the cell variants) are real `UIView`/`UITableViewCell`/`UICollectionViewCell` subclasses — they already wrap a `UIHostingController` internally, so you don't have to.

Slot views auto-register with the bridge on attach and auto-unregister on detach — there's no listener to manage.

<details>
<summary><b>Observing slots manually (Swift &amp; Objective-C)</b></summary>

When you need raw control over where and how a slot's unit is placed — without using a slot view — observe `NativeDisplaySlotManager.shared` directly. `NativeDisplaySlotObserver` is an `@objc` protocol, so this works from both Swift and Objective-C:

```objc
@interface MySlotHost : NSObject <NativeDisplaySlotObserver>
@end

@implementation MySlotHost

- (void)startObserving {
    [[NativeDisplaySlotManager shared] registerSlot:@"hero_banner" observer:self];
}

- (void)stopObserving {
    [[NativeDisplaySlotManager shared] unregisterSlot:@"hero_banner" observer:self];
}

- (void)onUnitAvailable:(NativeDisplayUnit *)unit { /* render it */ }
- (void)onUnitCleared:(NSString *)slotId       { /* remove your view */ }

@end
```

Observers are held weakly, so unregistering is optional but recommended for deterministic cleanup. Other `@objc` helpers on the manager: `getUnitForSlot:` returns the latest unit for a slot (or `nil`), and `activeSlotIds` returns the currently-indexed slot IDs as an `NSArray<NSString *>` (Obj-C can't represent the Swift `Set` from `getActiveSlotIds()`).
</details>

---

## Approach 2 — Custom rendering

Choose this when you need to inspect units before rendering, place them in custom layouts (carousels, dynamic view graphs), filter by metadata, or run standalone without the Core SDK.

> **Objective-C is supported here too.** `NativeDisplayUnit` is an `@objc` class and `NativeDisplayBridgeListener` is an `@objc` protocol, so Obj-C apps can attach the listener and render units with the unit-based `NativeDisplayUIView` initializer — see the Obj-C snippets in Steps A and B below. (The SwiftUI `NativeDisplayView` initializer remains Swift-only; use `NativeDisplayUIView` from Obj-C.)

After Steps 1 & 2 above, attach a `NativeDisplayBridgeListener` and render each unit with the renderer that fits your UI layer.

**Step A — attach the listener**

Swift:
```swift
class MyBridgeListener: NativeDisplayBridgeListener {
    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        // Store in your state, then render with one of the options below
    }
}
NativeDisplayBridge.shared.addListener(myBridgeListener)
```

<details>
<summary><b>Objective-C</b></summary>

`NativeDisplayBridgeListener` is an `@objc` protocol and `NativeDisplayUnit` is an `@objc` class, so you can implement the listener directly on any `NSObject` subclass (e.g. a `UIViewController`):

```objc
@interface MyViewController () <NativeDisplayBridgeListener>
@end

@implementation MyViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NativeDisplayBridge shared] addListener:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NativeDisplayBridge shared] removeListener:self];
}

- (void)onNativeDisplaysLoaded:(NSArray<NativeDisplayUnit *> *)units {
    // Store the units, then render with the Obj-C snippet in Step B
}

@end
```

> The bridge notifies every listener with the entire unit cache. If your listener lives on a screen that stays alive (e.g. a tab in a `UITabBarController`), add it in `viewWillAppear:` and remove it in `viewWillDisappear:` so units fetched on other screens don't replay into yours.
</details>

Hold a strong reference to your listener — if it's a local variable, it will be released before any callback fires.

**Step B — render each unit**

SwiftUI:
```swift
struct CampaignBanner: View {
    let unit: NativeDisplayUnit
    var body: some View {
        NativeDisplayView(unit: unit, actionListener: myActionListener)
    }
}
```

<details>
<summary><b>UIKit (Swift)</b></summary>

`NativeDisplayUIView` is a regular `UIView`, so you can drop it into any view hierarchy. Instantiate it in your listener callback:
```swift
func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
    guard let unit = units.first else { return }
    let banner = NativeDisplayUIView(unit: unit, actionListener: myActionListener)
    banner.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(banner)
    NSLayoutConstraint.activate([
        banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
}
```
</details>

<details>
<summary><b>UIKit (Objective-C)</b></summary>

`NativeDisplayUIView` exposes an `@objc` unit-based initializer, so render each unit from your `onNativeDisplaysLoaded:` callback:
```objc
- (void)onNativeDisplaysLoaded:(NSArray<NativeDisplayUnit *> *)units {
    NativeDisplayUnit *unit = units.firstObject;
    if (unit == nil) { return; }
    NativeDisplayUIView *banner = [[NativeDisplayUIView alloc]
        initWithUnit:unit
         parentWidth:self.view.bounds.size.width
      actionListener:self.myActionListener
   componentListener:nil];
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:banner];
    [NSLayoutConstraint activateConstraints:@[
        [banner.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [banner.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [banner.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}
```
</details>

**Standalone mode** (no Core SDK): feed units yourself. The same `onNativeDisplaysLoaded` callback fires.

```swift
NativeDisplayBridge.shared.addListener(myBridgeListener)
NativeDisplayBridge.shared.processDisplayUnits(jsonStrings)
```

<details>
<summary><b>Render raw JSON directly (Objective-C)</b></summary>

When you already hold a config's JSON and don't need the bridge or a `NativeDisplayUnit`, the UIKit components expose `@objc` entry points that parse `NSData` and render it in one call. These return whether parsing succeeded:

```objc
// View controller — convenience initializer returns nil on parse failure
NativeDisplayViewController *vc = [[NativeDisplayViewController alloc]
    initWithJsonData:jsonData
      actionListener:self.myActionListener
   componentListener:nil];

// Table / collection cells — returns NO on parse failure
[tableCell      configureWithJsonData:jsonData actionListener:nil componentListener:nil];
[collectionCell configureWithJsonData:jsonData actionListener:nil componentListener:nil];
```

> ⚠️ This path renders JSON with **no attribution** — there is no `NativeDisplayUnit`, so viewed/clicked events do not fire. Use the slot flow (Approach 1) or the unit-based bridge flow (Approach 2) when you need attribution.
</details>

---

## Fetch on demand

By default the Core SDK pushes units when they're ready. To pull on demand (e.g. screen open, pull-to-refresh):

Swift:
```swift
NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap.sharedInstance())
```

<details>
<summary><b>Objective-C</b></summary>

```objc
[[NativeDisplayBridge shared] fetchNativeDisplays:[CleverTap sharedInstance]];
```
</details>

The call returns a `Bool` indicating that the **request was dispatched** — not that the fetch completed. Results arrive asynchronously via the same `onNativeDisplaysLoaded` callback. This works orthogonally to either approach above: slots in Approach 1 refresh automatically, custom listeners in Approach 2 fire again.

---

## Event hooks

The renderer surfaces two listeners. Attach one or both to a slot or to `NativeDisplayView` to react to user interactions and run your own logic.

### NativeDisplayActionListener — high-level outcomes

Semantic callbacks that describe what the user did:

| Callback | Purpose |
|----------|---------|
| `onOpenUrl(url, openInBrowser) -> Bool` | Return `true` if your app handled it (e.g. deep-link router); `false` to let the SDK open it. |
| `onCustomAction(key, value, metadata)` | Handle custom actions defined in the campaign JSON. |
| `onNavigate(destination, params)` | In-app navigation actions. |
| `onTrackEvent(eventName, properties)` | Forward to your analytics layer if needed. |
| `onDisplayUnitViewed(unitId)` / `onDisplayUnitClicked(unitId)` | Attribution callbacks — Core SDK already tracks these automatically; implement only if you need a copy. |

### NativeDisplayComponentListener — low-level node interactions

Raw gestures on specific nodes by ID. Use this when you need to intercept individual taps, long presses, or double-taps before the SDK handles them.

| Member | Purpose |
|--------|---------|
| `onComponentInteraction(nodeId, interactionType, hasServerAction) -> Bool` | Return `true` to consume the interaction; `false` to let the SDK proceed with default behavior. |
| `getInterestedNodeIds(): Set<String>?` | Narrow callbacks to specific node IDs; `nil` (default) means all nodes. |
| `InteractionType` | `.click` / `.longPress` / `.doubleTap`. |

### Attaching listeners

SwiftUI:
```swift
NativeDisplaySlot(
    slotId: "hero_banner",
    actionListener: myActionListener,
    componentListener: myComponentListener,
)
```

<details>
<summary><b>UIKit (Swift)</b></summary>

```swift
let slot = NativeDisplaySlotUIView(slotId: "hero_banner")
slot.actionListener = myActionListener
slot.componentListener = myComponentListener
```
</details>

<details>
<summary><b>UIKit (Objective-C)</b></summary>

```objc
NativeDisplaySlotUIView *slot = [[NativeDisplaySlotUIView alloc] initWithSlotId:@"hero_banner"];
slot.actionListener = self.myActionListener;
slot.componentListener = self.myComponentListener;
```
</details>

<details>
<summary><b>Implementing a listener in Objective-C</b></summary>

Both `NativeDisplayActionListener` and `NativeDisplayComponentListener` are `@objc` protocols — implement them from an `NSObject` subclass:

```objc
@interface MyActionListener : NSObject <NativeDisplayActionListener>
@end

@implementation MyActionListener

- (BOOL)onOpenUrlWithUrl:(NSString *)url openInBrowser:(BOOL)openInBrowser {
    // return YES if you handled it; NO to let the SDK open it
    return NO;
}

- (void)onCustomActionWithKey:(NSString *)key
                        value:(id)value
                     metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    // handle custom action
}

- (void)onNavigateWithDestination:(NSString *)destination
                           params:(NSDictionary<NSString *,NSString *> *)params { }

- (void)onTrackEventWithEventName:(NSString *)eventName
                       properties:(NSDictionary<NSString *,id> *)properties { }

@end
```
</details>

---

## Custom fonts

Provide a font resolver via the SwiftUI environment:

```swift
NativeDisplayView(unit: unit)
    .environment(\.nativeDisplayFontResolver) { name, size, weight in
        Font.custom(name, size: size).weight(weight)
    }
```

> If cross-platform font parity matters, enforce a shared font on both platforms — San Francisco (iOS) and Roboto (Android) have different character widths and will wrap text differently.

---

## Troubleshooting

**Listener not called / campaigns never arrive**
- Confirm Step 2 of Approach 1 is complete — without a Core SDK link, no units will be pushed. For standalone testing, feed JSON yourself via `processDisplayUnits(...)` (Approach 2).
- Hold a strong reference to your listener. If it's a local variable, it will be released before any callback fires.

**Layout looks wrong or view has zero height**
- Always provide `layout.width` on the root node — use `"match_parent"` to fill the available space.
- `HTML` elements require an explicit `layout.height`; they cannot auto-size.

**Text wraps differently on Android vs iOS**
- Roboto (Android) and San Francisco (iOS) have different character widths. Always specify `lineHeight` in your campaign JSON for consistent results across platforms, and consider supplying the same custom font on both platforms via the custom font APIs.

---

For campaign JSON structure and element reference, see [JSON Structure Reference](JSON_STRUCTURE_REFERENCE.md) and the [project README](../README.md).
