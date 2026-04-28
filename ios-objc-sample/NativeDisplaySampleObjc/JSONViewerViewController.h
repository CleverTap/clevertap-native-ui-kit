//
//  JSONViewerViewController.h
//  NativeDisplaySampleObjc
//
//  Displays JSON text in a monospace dark-themed text view with Copy button.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSONViewerViewController : UIViewController

/// Designated initialiser.
/// @param jsonString  The JSON text to display.
/// @param title       Navigation bar title.
- (instancetype)initWithJSONString:(NSString *)jsonString
                             title:(NSString *)title NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
