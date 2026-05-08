---
title: Render slots in UIKit / Objective-C
sidebar_label: iOS (Objective-C)
sidebar_position: 6
description: Drop a NativeDisplaySlotUIView in any UIKit screen and let the bridge route campaigns to it.
---

# Render slots in UIKit / Objective-C

The SDK is written in Swift but exposes a `UIView`-based slot host (`NativeDisplaySlotUIView`) usable from both UIKit Swift and Objective-C codebases.

## Bridge setup recap

The bridge init code from [Quickstart](/getting-started/quickstart) goes in your `AppDelegate`:

```objc title="AppDelegate.m"
#import <CleverTapNativeDisplay/CleverTapNativeDisplay-Swift.h>
#import <CleverTapSDK/CleverTap.h>

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CleverTap autoIntegrate];

    [[NativeDisplayBridge shared] initialize];
    [[NativeDisplayBridge shared] bind:[CleverTap sharedInstance]];

    return YES;
}
```

## Drop a slot

```objc
- (void)viewDidLoad {
    [super viewDidLoad];

    NativeDisplaySlotUIView *slot =
        [[NativeDisplaySlotUIView alloc] initWithSlotId:@"hero_banner"];
    slot.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:slot];

    [NSLayoutConstraint activateConstraints:@[
        [slot.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [slot.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [slot.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}
```

The slot view auto-subscribes when added to the window and auto-unsubscribes when removed. The bridge routes any campaign with `slotId == @"hero_banner"` into this view.

## Listening to actions

```objc
slot.actionListener = self;

#pragma mark - NativeDisplayActionListener
- (void)onAction:(NativeDisplayAction *)action
          nodeId:(NSString *)nodeId
         trigger:(NSString *)trigger {
    if ([action.type isEqualToString:@"open_url"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:action.url]
                                           options:@{} completionHandler:nil];
    } else if ([action.type isEqualToString:@"dismiss"]) {
        [self dismissCampaign];
    }
}
```

## In a UICollectionView / UITableView

The SDK ships dedicated cells:

- `NativeDisplaySlotCollectionViewCell`
- `NativeDisplaySlotTableViewCell`

Register them with your data source and call `setSlotId:` from `cellForItemAtIndexPath:` / `cellForRowAtIndexPath:`:

```objc
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (item.isAdSlot) {
        NativeDisplaySlotCollectionViewCell *cell =
            [cv dequeueReusableCellWithReuseIdentifier:@"slot" forIndexPath:indexPath];
        [cell setSlotId:item.slotId];
        return cell;
    }
    // … your normal cell types …
}
```

The cell handles registration / unregistration across reuse internally.

## Caveats with Objective-C interop

- Generic Swift types are not bridged — the slot APIs all use concrete types.
- `NativeDisplayActionListener` is exposed as an `@objc`-compatible protocol; implement it with the Objective-C signatures shown above.
- Variables that contain Swift-only types (tuples, generic associated types) won't survive the bridge — stick to JSON-native types in `variables` blocks.

## Next

- [Concepts](/concepts/config-structure)
- [Actions](/concepts/actions)
- [SwiftUI path](/getting-started/ios-swiftui) — if you mix UIKit and SwiftUI
