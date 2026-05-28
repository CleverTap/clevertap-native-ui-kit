//
//  HomeScreenViewController.m
//  NativeDisplaySampleObjc
//
//  Home screen layout demo with component listener (logs to console).
//

#import "HomeScreenViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapNativeDisplay;

// ---------------------------------------------------------------------------
// MARK: - Component listener for home screen (logs to console)
// ---------------------------------------------------------------------------

@interface HomeScreenComponentListenerObjc : NSObject <NativeDisplayComponentListener>
@end

@implementation HomeScreenComponentListenerObjc

- (BOOL)onComponentInteractionWithNodeId:(NSString *)nodeId
                         interactionType:(InteractionType)interactionType
                         hasServerAction:(BOOL)hasServerAction {
    NSString *typeStr;
    switch (interactionType) {
        case InteractionTypeClick:     typeStr = @"click";      break;
        case InteractionTypeLongPress: typeStr = @"long_press";  break;
        case InteractionTypeDoubleTap: typeStr = @"double_tap";  break;
        default:                       typeStr = @"unknown";     break;
    }
    NSLog(@"HomeScreen_Click: Component: %@ | Type: %@ | HasServerAction: %@",
          nodeId, typeStr, hasServerAction ? @"YES" : @"NO");
    return NO; // don't consume
}

@end

// ---------------------------------------------------------------------------
// MARK: - HomeScreenViewController
// ---------------------------------------------------------------------------

@interface HomeScreenViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong, nullable) UIView *displayView;
@property (nonatomic, strong) HomeScreenComponentListenerObjc *componentListener;
@end

@implementation HomeScreenViewController

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Home";
    self.view.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.996 alpha:1.0]; // #F8F9FE

    self.componentListener = [HomeScreenComponentListenerObjc new];

    [self setupScrollView];
    [self loadHomeScreen];
}

// ---------------------------------------------------------------------------
// MARK: - Setup
// ---------------------------------------------------------------------------

- (void)setupScrollView {
    self.scrollView = [UIScrollView new];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (void)loadHomeScreen {
    NSData *data = [NDDisplayHelper loadJSONDataWithFilename:@"home_screen" directory:nil];
    if (!data) {
        NSLog(@"HomeScreen: could not find home_screen.json");
        [self showErrorLabel:@"Could not find home_screen.json in bundle"];
        return;
    }

    NSError *error = nil;
    CGFloat parentWidth = self.view.bounds.size.width;
    UIView *view = [NDDisplayHelper createViewFrom:data
                                                     parentWidth:parentWidth
                                              componentListener:self.componentListener
                                                 actionListener:nil
                                                          error:&error];
    if (!view) {
        NSLog(@"HomeScreen error: %@", error);
        [self showErrorLabel:error.localizedDescription ?: @"Unknown error"];
        return;
    }

    [self.displayView removeFromSuperview];
    self.displayView = view;

    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:view];

    [NSLayoutConstraint activateConstraints:@[
        [view.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor constant:16],
        [view.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:16],
        [view.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor constant:-16],
        [view.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor constant:-16],
        [view.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor constant:-32],
    ]];
}

- (void)showErrorLabel:(NSString *)message {
    UILabel *lbl = [UILabel new];
    lbl.text = message;
    lbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    lbl.textColor = [UIColor secondaryLabelColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:lbl];
    [NSLayoutConstraint activateConstraints:@[
        [lbl.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [lbl.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [lbl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32],
        [lbl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32],
    ]];
}

@end
