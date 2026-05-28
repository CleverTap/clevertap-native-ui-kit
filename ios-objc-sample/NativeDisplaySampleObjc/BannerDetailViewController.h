//
//  BannerDetailViewController.h
//  NativeDisplaySampleObjc
//
//  70/30 split view: banner display on top, interaction log panel on bottom.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BannerDetailViewController : UIViewController

/// Designated initialiser.
/// @param title        Navigation bar title (e.g. "🌞 Summer Sale")
/// @param jsonData     Pre-loaded JSON data for the banner
/// @param jsonFileURL  Optional URL when data was loaded from a user-picked file
///                     (needed for the JSON viewer). Pass nil for bundle files.
- (instancetype)initWithTitle:(NSString *)title
                     jsonData:(NSData *)jsonData
                  jsonFileURL:(nullable NSURL *)jsonFileURL NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
