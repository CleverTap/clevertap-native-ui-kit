#import "UIKitDemoViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapSDK;
@import CleverTapNativeDisplay;

@interface UIKitDemoViewController () <NDBridgeListenerObjc, NativeDisplayActionListener, UITextFieldDelegate>

// UI elements (mirroring UIKitTestViewController.swift)
@property (nonatomic, strong) UITextField *eventNameField;
@property (nonatomic, strong) UIButton *fireButton;
@property (nonatomic, strong) UILabel *canvasLabel;
@property (nonatomic, strong) UIScrollView *canvasScrollView;
@property (nonatomic, strong) UIStackView *canvasStack;
@property (nonatomic, strong) UILabel *emptyCanvasLabel;
@property (nonatomic, strong) UIStackView *logHeaderStack;
@property (nonatomic, strong) UILabel *logLabel;
@property (nonatomic, strong) UIButton *clearLogButton;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIView *panelSeparator;
@property (nonatomic, strong) UIView *leftPanelAnchor;
@property (nonatomic, strong) UIStackView *headerStack;

// Constraint sets
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *portraitConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *landscapeConstraints;

// Bridge
@property (nonatomic, strong) NDBridgeListenerToken *listenerToken;

@end

@implementation UIKitDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"UIKit Demo";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildLayout];
    [self applyLayoutForSize:self.view.bounds.size];
    [self wireActions];
    _listenerToken = [NDDisplayHelper bridgeAddListener:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applyLayoutForSize:size];
    } completion:nil];
}

- (void)dealloc {
    if (_listenerToken) {
        [NDDisplayHelper bridgeRemoveListener:_listenerToken];
    }
}

// MARK: - Layout

- (void)buildLayout {
    // Event name field
    _eventNameField = [[UITextField alloc] init];
    _eventNameField.placeholder = @"Enter event name";
    _eventNameField.borderStyle = UITextBorderStyleRoundedRect;
    _eventNameField.returnKeyType = UIReturnKeySend;
    _eventNameField.translatesAutoresizingMaskIntoConstraints = NO;
    _eventNameField.delegate = self;

    // Fire button
    UIButtonConfiguration *btnConfig = [UIButtonConfiguration filledButtonConfiguration];
    btnConfig.title = @"Fire Event";
    btnConfig.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    _fireButton = [UIButton buttonWithConfiguration:btnConfig primaryAction:nil];
    _fireButton.translatesAutoresizingMaskIntoConstraints = NO;
    _fireButton.enabled = NO;

    // Header stack
    _headerStack = [[UIStackView alloc] initWithArrangedSubviews:@[_eventNameField, _fireButton]];
    _headerStack.axis = UILayoutConstraintAxisHorizontal;
    _headerStack.spacing = 8;
    _headerStack.translatesAutoresizingMaskIntoConstraints = NO;

    // Canvas label
    _canvasLabel = [[UILabel alloc] init];
    _canvasLabel.text = @"Native Display Canvas";
    _canvasLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _canvasLabel.textColor = [UIColor secondaryLabelColor];
    _canvasLabel.translatesAutoresizingMaskIntoConstraints = NO;

    // Canvas scroll view
    _canvasScrollView = [[UIScrollView alloc] init];
    _canvasScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _canvasScrollView.alwaysBounceVertical = YES;

    _canvasStack = [[UIStackView alloc] init];
    _canvasStack.axis = UILayoutConstraintAxisVertical;
    _canvasStack.spacing = 12;
    _canvasStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_canvasScrollView addSubview:_canvasStack];

    _emptyCanvasLabel = [[UILabel alloc] init];
    _emptyCanvasLabel.text = @"Fire an event to receive display units";
    _emptyCanvasLabel.textColor = [UIColor tertiaryLabelColor];
    _emptyCanvasLabel.font = [UIFont systemFontOfSize:14];
    _emptyCanvasLabel.textAlignment = NSTextAlignmentCenter;
    _emptyCanvasLabel.numberOfLines = 0;
    _emptyCanvasLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_canvasScrollView addSubview:_emptyCanvasLabel];

    // Log header
    _logLabel = [[UILabel alloc] init];
    _logLabel.text = @"Event Log";
    _logLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _logLabel.textColor = [UIColor secondaryLabelColor];

    UIButtonConfiguration *clearConfig = [UIButtonConfiguration plainButtonConfiguration];
    clearConfig.title = @"Clear";
    clearConfig.baseForegroundColor = [UIColor systemBlueColor];
    _clearLogButton = [UIButton buttonWithConfiguration:clearConfig primaryAction:nil];
    _clearLogButton.translatesAutoresizingMaskIntoConstraints = NO;

    _logHeaderStack = [[UIStackView alloc] initWithArrangedSubviews:@[_logLabel, [[UIView alloc] init], _clearLogButton]];
    _logHeaderStack.axis = UILayoutConstraintAxisHorizontal;
    _logHeaderStack.alignment = UIStackViewAlignmentCenter;
    _logHeaderStack.translatesAutoresizingMaskIntoConstraints = NO;

    // Log text view
    _logTextView = [[UITextView alloc] init];
    _logTextView.editable = NO;
    _logTextView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    _logTextView.textColor = [UIColor greenColor];
    _logTextView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    _logTextView.layer.cornerRadius = 8;
    _logTextView.translatesAutoresizingMaskIntoConstraints = NO;
    _logTextView.text = @"";

    // Panel separator (landscape only)
    _panelSeparator = [[UIView alloc] init];
    _panelSeparator.backgroundColor = [UIColor separatorColor];
    _panelSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    _panelSeparator.hidden = YES;

    // Left panel anchor (invisible, 33% width reference for landscape)
    _leftPanelAnchor = [[UIView alloc] init];
    _leftPanelAnchor.hidden = YES;
    _leftPanelAnchor.translatesAutoresizingMaskIntoConstraints = NO;

    // Add to view hierarchy
    [self.view addSubview:_headerStack];
    [self.view addSubview:_canvasLabel];
    [self.view addSubview:_canvasScrollView];
    [self.view addSubview:_logHeaderStack];
    [self.view addSubview:_logTextView];
    [self.view addSubview:_panelSeparator];
    [self.view addSubview:_leftPanelAnchor];

    // Always-active: canvas stack pinned inside scroll view
    [NSLayoutConstraint activateConstraints:@[
        [_canvasStack.topAnchor constraintEqualToAnchor:_canvasScrollView.topAnchor constant:8],
        [_canvasStack.bottomAnchor constraintEqualToAnchor:_canvasScrollView.bottomAnchor constant:-8],
        [_canvasStack.leadingAnchor constraintEqualToAnchor:_canvasScrollView.leadingAnchor],
        [_canvasStack.trailingAnchor constraintEqualToAnchor:_canvasScrollView.trailingAnchor],
        [_canvasStack.widthAnchor constraintEqualToAnchor:_canvasScrollView.widthAnchor],

        [_emptyCanvasLabel.centerXAnchor constraintEqualToAnchor:_canvasScrollView.centerXAnchor],
        [_emptyCanvasLabel.centerYAnchor constraintEqualToAnchor:_canvasScrollView.centerYAnchor],
        [_emptyCanvasLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_canvasScrollView.leadingAnchor constant:32],
        [_emptyCanvasLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_canvasScrollView.trailingAnchor constant:-32],
    ]];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;

    // Portrait constraints
    _portraitConstraints = @[
        [_headerStack.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [_headerStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_headerStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [_canvasLabel.topAnchor constraintEqualToAnchor:_headerStack.bottomAnchor constant:12],
        [_canvasLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_canvasLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [_canvasScrollView.topAnchor constraintEqualToAnchor:_canvasLabel.bottomAnchor constant:8],
        [_canvasScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_canvasScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_canvasScrollView.bottomAnchor constraintEqualToAnchor:_logHeaderStack.topAnchor constant:-8],

        [_logHeaderStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_logHeaderStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [_logTextView.topAnchor constraintEqualToAnchor:_logHeaderStack.bottomAnchor constant:4],
        [_logTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_logTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [_logTextView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-8],
        [_logTextView.heightAnchor constraintEqualToConstant:160],
    ];

    // Landscape constraints (33/67 split)
    _landscapeConstraints = @[
        // Invisible anchor occupies left 33%
        [_leftPanelAnchor.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_leftPanelAnchor.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_leftPanelAnchor.heightAnchor constraintEqualToConstant:1],
        [_leftPanelAnchor.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.33],

        // Separator at 33%
        [_panelSeparator.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [_panelSeparator.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [_panelSeparator.widthAnchor constraintEqualToConstant:0.5],
        [_panelSeparator.leadingAnchor constraintEqualToAnchor:_leftPanelAnchor.trailingAnchor],

        // Left panel: header at top
        [_headerStack.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [_headerStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_headerStack.trailingAnchor constraintEqualToAnchor:_panelSeparator.leadingAnchor constant:-8],

        // Left panel: log header below event header
        [_logHeaderStack.topAnchor constraintEqualToAnchor:_headerStack.bottomAnchor constant:12],
        [_logHeaderStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_logHeaderStack.trailingAnchor constraintEqualToAnchor:_panelSeparator.leadingAnchor constant:-8],

        // Left panel: log fills remaining height
        [_logTextView.topAnchor constraintEqualToAnchor:_logHeaderStack.bottomAnchor constant:4],
        [_logTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_logTextView.trailingAnchor constraintEqualToAnchor:_panelSeparator.leadingAnchor constant:-8],
        [_logTextView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-8],

        // Right panel: canvas full height
        [_canvasScrollView.topAnchor constraintEqualToAnchor:guide.topAnchor constant:8],
        [_canvasScrollView.leadingAnchor constraintEqualToAnchor:_panelSeparator.trailingAnchor],
        [_canvasScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_canvasScrollView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-8],
    ];
}

- (void)applyLayoutForSize:(CGSize)size {
    BOOL isLandscape = size.width > size.height;
    if (isLandscape) {
        [NSLayoutConstraint deactivateConstraints:_portraitConstraints];
        [NSLayoutConstraint activateConstraints:_landscapeConstraints];
    } else {
        [NSLayoutConstraint deactivateConstraints:_landscapeConstraints];
        [NSLayoutConstraint activateConstraints:_portraitConstraints];
    }
    _canvasLabel.hidden = isLandscape;
    _panelSeparator.hidden = !isLandscape;
    [_canvasScrollView setNeedsLayout];
    [_canvasScrollView layoutIfNeeded];
}

- (void)wireActions {
    [_fireButton addTarget:self action:@selector(fireEvent) forControlEvents:UIControlEventTouchUpInside];
    [_clearLogButton addTarget:self action:@selector(clearLog) forControlEvents:UIControlEventTouchUpInside];
    [_eventNameField addTarget:self action:@selector(textFieldChanged) forControlEvents:UIControlEventEditingChanged];
}

// MARK: - Actions

- (void)fireEvent {
    NSString *name = [_eventNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length == 0) return;
    [[CleverTap sharedInstance] recordEvent:name];
    [self appendLog:[NSString stringWithFormat:@"Event fired: %@", name]];
    _eventNameField.text = @"";
    _fireButton.enabled = NO;
    [_eventNameField resignFirstResponder];
}

- (void)clearLog {
    _logTextView.text = @"";
}

- (void)textFieldChanged {
    BOOL hasText = !([_eventNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0);
    _fireButton.enabled = hasText;
}

- (void)updateEmptyState {
    _emptyCanvasLabel.hidden = (_canvasStack.arrangedSubviews.count > 0);
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self fireEvent];
    return YES;
}

// MARK: - NDBridgeListenerObjc

- (void)onNativeDisplaysLoaded:(NSArray<NSString *> *)unitIds {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *views = [self->_canvasStack.arrangedSubviews copy];
        for (UIView *v in views) {
            [self->_canvasStack removeArrangedSubview:v];
            [v removeFromSuperview];
        }

        for (NSString *unitId in unitIds) {
            NativeDisplayUIView *displayView = [NDDisplayHelper createViewForUnitId:unitId
                parentWidth:self->_canvasScrollView.bounds.size.width
                actionListener:self
                componentListener:nil];
            if (displayView) {
                displayView.translatesAutoresizingMaskIntoConstraints = NO;
                [self->_canvasStack addArrangedSubview:displayView];
            }
        }

        [self updateEmptyState];
        [self appendLog:[NSString stringWithFormat:@"Received %lu display unit(s)", (unsigned long)unitIds.count]];
        [self->_canvasScrollView setNeedsLayout];
        [self->_canvasScrollView layoutIfNeeded];
    });
}

// MARK: - NativeDisplayActionListener

- (BOOL)onOpenUrlWithUrl:(NSString *)url openInBrowser:(BOOL)openInBrowser {
    [self appendLog:[NSString stringWithFormat:@"Open URL: %@ (browser: %@)", url, openInBrowser ? @"YES" : @"NO"]];
    return NO;
}

- (void)onCustomActionWithKey:(NSString *)key value:(id)value metadata:(NSDictionary<NSString *, NSString *> *)metadata {
    [self appendLog:[NSString stringWithFormat:@"Custom action: %@", key]];
}

- (void)onNavigateWithDestination:(NSString *)destination params:(NSDictionary<NSString *, NSString *> *)params {
    [self appendLog:[NSString stringWithFormat:@"Navigate: %@", destination]];
}

- (void)onTrackEventWithEventName:(NSString *)eventName properties:(NSDictionary<NSString *, id> *)properties {
    [self appendLog:[NSString stringWithFormat:@"Track event: %@", eventName]];
}

// MARK: - Helpers

- (void)appendLog:(NSString *)message {
    NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_logTextView.text = [self->_logTextView.text stringByAppendingString:line];
        NSRange range = NSMakeRange(self->_logTextView.text.length > 0 ? self->_logTextView.text.length - 1 : 0, 1);
        [self->_logTextView scrollRangeToVisible:range];
    });
}

@end
