#import "CleverTapIntegrationViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapSDK;
@import CleverTapNativeDisplay;

@interface CleverTapIntegrationViewController () <NativeDisplayBridgeListener, NativeDisplayActionListener, UITextFieldDelegate>

// UI elements
@property (nonatomic, strong) UITextField *eventNameField;
@property (nonatomic, strong) UIButton *sendEventButton;
@property (nonatomic, strong) UIView *headerContainer;
@property (nonatomic, strong) UIScrollView *canvasScrollView;
@property (nonatomic, strong) UIStackView *canvasStack;
@property (nonatomic, strong) UILabel *emptyCanvasLabel;
@property (nonatomic, strong) UIView *logContainer;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIView *panelSeparator;
@property (nonatomic, strong) UIView *leftPanelAnchor;

// Constraint sets
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *portraitConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *landscapeConstraints;
@end

@implementation CleverTapIntegrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CleverTap Integration";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildLayout];
    [self applyLayoutForSize:self.view.bounds.size];

    CleverTap *ct = [CleverTap sharedInstance];
    if (ct) {
        [self appendLog:@"CleverTap instance found"];
    } else {
        [self appendLog:@"CleverTap not configured — check Info.plist credentials"];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Listen only while this screen is visible — mirrors the SwiftUI sample's
    // onAppear/onDisappear. This VC is a permanent tab in a UITabBarController,
    // so registering once in viewDidLoad would keep it listening forever: slot
    // campaigns fetched on the Slots tab would replay into this canvas, because
    // the bridge notifies every registered listener with the whole unit set.
    [NativeDisplayBridge.shared addListener:self];
    [self appendLog:@"Bridge listener registered"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NativeDisplayBridge.shared removeListener:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applyLayoutForSize:size];
    } completion:nil];
}

- (void)dealloc {
    [NativeDisplayBridge.shared removeListener:self];
}

// MARK: - Layout

- (void)buildLayout {
    // Event name field
    _eventNameField = [[UITextField alloc] init];
    _eventNameField.placeholder = @"Enter event name";
    _eventNameField.borderStyle = UITextBorderStyleRoundedRect;
    _eventNameField.returnKeyType = UIReturnKeySend;
    _eventNameField.translatesAutoresizingMaskIntoConstraints = NO;
    _eventNameField.accessibilityIdentifier = @"ct-event-input";
    [_eventNameField addTarget:self action:@selector(textFieldChanged) forControlEvents:UIControlEventEditingChanged];
    _eventNameField.delegate = self;

    // Send event button
    UIButtonConfiguration *btnConfig = [UIButtonConfiguration filledButtonConfiguration];
    btnConfig.title = @"Send Event";
    btnConfig.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    _sendEventButton = [UIButton buttonWithConfiguration:btnConfig primaryAction:nil];
    _sendEventButton.translatesAutoresizingMaskIntoConstraints = NO;
    _sendEventButton.enabled = NO;
    _sendEventButton.accessibilityIdentifier = @"ct-send-event-btn";
    [_sendEventButton addTarget:self action:@selector(sendEvent) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *inputRow = [[UIStackView alloc] initWithArrangedSubviews:@[_eventNameField, _sendEventButton]];
    inputRow.axis = UILayoutConstraintAxisHorizontal;
    inputRow.spacing = 8;
    inputRow.translatesAutoresizingMaskIntoConstraints = NO;

    _headerContainer = [[UIView alloc] init];
    _headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [_headerContainer addSubview:inputRow];
    [NSLayoutConstraint activateConstraints:@[
        [inputRow.topAnchor constraintEqualToAnchor:_headerContainer.topAnchor constant:10],
        [inputRow.leadingAnchor constraintEqualToAnchor:_headerContainer.leadingAnchor constant:10],
        [inputRow.trailingAnchor constraintEqualToAnchor:_headerContainer.trailingAnchor constant:-10],
        [inputRow.bottomAnchor constraintEqualToAnchor:_headerContainer.bottomAnchor constant:-10],
    ]];

    // Canvas scroll view
    _canvasScrollView = [[UIScrollView alloc] init];
    _canvasScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _canvasScrollView.alwaysBounceVertical = YES;
    _canvasScrollView.accessibilityIdentifier = @"ct-display-canvas";

    _canvasStack = [[UIStackView alloc] init];
    _canvasStack.axis = UILayoutConstraintAxisVertical;
    _canvasStack.spacing = 12;
    _canvasStack.translatesAutoresizingMaskIntoConstraints = NO;
    _canvasStack.layoutMargins = UIEdgeInsetsMake(0, 10, 0, 10);
    _canvasStack.layoutMarginsRelativeArrangement = YES;
    [_canvasScrollView addSubview:_canvasStack];

    _emptyCanvasLabel = [[UILabel alloc] init];
    _emptyCanvasLabel.text = @"Waiting for Native Display response...";
    _emptyCanvasLabel.font = [UIFont systemFontOfSize:14];
    _emptyCanvasLabel.textColor = [UIColor secondaryLabelColor];
    _emptyCanvasLabel.textAlignment = NSTextAlignmentCenter;
    _emptyCanvasLabel.numberOfLines = 0;
    _emptyCanvasLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _emptyCanvasLabel.accessibilityIdentifier = @"ct-waiting-canvas";
    [_canvasScrollView addSubview:_emptyCanvasLabel];

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

    // Log container
    _logContainer = [self buildLogContainer];

    // Panel separator
    _panelSeparator = [[UIView alloc] init];
    _panelSeparator.backgroundColor = [UIColor separatorColor];
    _panelSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    _panelSeparator.hidden = YES;

    // Left panel anchor (invisible, used for 33% split in landscape)
    _leftPanelAnchor = [[UIView alloc] init];
    _leftPanelAnchor.hidden = YES;
    _leftPanelAnchor.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_headerContainer];
    [self.view addSubview:_canvasScrollView];
    [self.view addSubview:_logContainer];
    [self.view addSubview:_panelSeparator];
    [self.view addSubview:_leftPanelAnchor];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;

    // Portrait: vertical stack, log at 160pt footer
    _portraitConstraints = @[
        [_headerContainer.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [_headerContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_headerContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [_canvasScrollView.topAnchor constraintEqualToAnchor:_headerContainer.bottomAnchor],
        [_canvasScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_canvasScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_canvasScrollView.bottomAnchor constraintEqualToAnchor:_logContainer.topAnchor],

        [_logContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_logContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_logContainer.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [_logContainer.heightAnchor constraintEqualToConstant:200],
    ];

    // Landscape: two-column split at 33/67
    _landscapeConstraints = @[
        // Invisible anchor occupies the left 33%
        [_leftPanelAnchor.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_leftPanelAnchor.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_leftPanelAnchor.heightAnchor constraintEqualToConstant:1],
        [_leftPanelAnchor.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.33],

        // Separator
        [_panelSeparator.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [_panelSeparator.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [_panelSeparator.widthAnchor constraintEqualToConstant:0.5],
        [_panelSeparator.leadingAnchor constraintEqualToAnchor:_leftPanelAnchor.trailingAnchor],

        // Left panel: header at top
        [_headerContainer.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [_headerContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_headerContainer.trailingAnchor constraintEqualToAnchor:_panelSeparator.leadingAnchor],

        // Left panel: log below header, fills rest
        [_logContainer.topAnchor constraintEqualToAnchor:_headerContainer.bottomAnchor],
        [_logContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_logContainer.trailingAnchor constraintEqualToAnchor:_panelSeparator.leadingAnchor],
        [_logContainer.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],

        // Right panel: canvas full height
        [_canvasScrollView.topAnchor constraintEqualToAnchor:guide.topAnchor constant:8],
        [_canvasScrollView.leadingAnchor constraintEqualToAnchor:_panelSeparator.trailingAnchor],
        [_canvasScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_canvasScrollView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-8],
    ];
}

- (UIView *)buildLogContainer {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *logLabel = [[UILabel alloc] init];
    logLabel.text = @"Event Log";
    logLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    logLabel.textColor = [UIColor secondaryLabelColor];
    logLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    clearBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [clearBtn addTarget:self action:@selector(clearLog) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *headerRow = [[UIStackView alloc] initWithArrangedSubviews:@[logLabel, [[UIView alloc] init], clearBtn]];
    headerRow.axis = UILayoutConstraintAxisHorizontal;
    headerRow.alignment = UIStackViewAlignmentCenter;
    headerRow.translatesAutoresizingMaskIntoConstraints = NO;

    _logTextView = [[UITextView alloc] init];
    _logTextView.editable = NO;
    _logTextView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    _logTextView.textColor = [UIColor colorWithRed:0.5 green:0.8 blue:0.77 alpha:1];
    _logTextView.backgroundColor = [UIColor colorWithRed:0.15 green:0.19 blue:0.22 alpha:1];
    _logTextView.layer.cornerRadius = 8;
    _logTextView.translatesAutoresizingMaskIntoConstraints = NO;
    _logTextView.text = @"No events yet";

    [container addSubview:headerRow];
    [container addSubview:_logTextView];

    [NSLayoutConstraint activateConstraints:@[
        [headerRow.topAnchor constraintEqualToAnchor:container.topAnchor constant:8],
        [headerRow.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [headerRow.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],

        [_logTextView.topAnchor constraintEqualToAnchor:headerRow.bottomAnchor constant:4],
        [_logTextView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [_logTextView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],
        [_logTextView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-8],
    ]];

    return container;
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
    _panelSeparator.hidden = !isLandscape;
    [_canvasScrollView setNeedsLayout];
    [_canvasScrollView layoutIfNeeded];
}

// MARK: - Actions

- (void)sendEvent {
    NSString *name = [_eventNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length == 0) return;
    [[CleverTap sharedInstance] recordEvent:name];
    [self appendLog:[NSString stringWithFormat:@"[EVENT] Sent event: %@", name]];
    _eventNameField.text = @"";
    _sendEventButton.enabled = NO;
    [_eventNameField resignFirstResponder];
}

- (void)clearLog {
    _logTextView.text = @"";
}

- (void)textFieldChanged {
    BOOL hasText = !([_eventNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0);
    _sendEventButton.enabled = hasText;
}

// MARK: - NativeDisplayBridgeListener

- (void)onNativeDisplaysLoaded:(NSArray<NativeDisplayUnit *> *)units {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Clear existing canvas views
        NSArray *views = [self->_canvasStack.arrangedSubviews copy];
        for (UIView *v in views) {
            [self->_canvasStack removeArrangedSubview:v];
            [v removeFromSuperview];
        }

        for (NativeDisplayUnit *unit in units) {
            NativeDisplayUIView *displayView = [[NativeDisplayUIView alloc]
                initWithUnit:unit
                parentWidth:self->_canvasScrollView.bounds.size.width
                actionListener:self
                componentListener:nil];
            if (displayView) {
                displayView.translatesAutoresizingMaskIntoConstraints = NO;
                [self->_canvasStack addArrangedSubview:displayView];
            }
        }

        self->_emptyCanvasLabel.hidden = (units.count > 0);
        [self appendLog:[NSString stringWithFormat:@"[Received] %lu display unit(s)", (unsigned long)units.count]];
        for (NativeDisplayUnit *unit in units) {
            [self appendLog:[NSString stringWithFormat:@"  unit: %@", unit.unitId]];
        }

        [self->_canvasScrollView setNeedsLayout];
        [self->_canvasScrollView layoutIfNeeded];
    });
}

// MARK: - NativeDisplayActionListener

- (BOOL)onOpenUrlWithUrl:(NSString *)url openInBrowser:(BOOL)openInBrowser {
    [self appendLog:[NSString stringWithFormat:@"[ACTION] openUrl: %@", url]];
    NSURL *parsedUrl = [NSURL URLWithString:url];
    if (parsedUrl) {
        [[UIApplication sharedApplication] openURL:parsedUrl options:@{} completionHandler:nil];
    }
    return YES;
}

- (void)onCustomActionWithKey:(NSString *)key value:(id)value metadata:(NSDictionary<NSString *, NSString *> *)metadata {
    [self appendLog:[NSString stringWithFormat:@"[ACTION] custom: %@ = %@", key, value ?: @"nil"]];
}

- (void)onNavigateWithDestination:(NSString *)destination params:(NSDictionary<NSString *, NSString *> *)params {
    [self appendLog:[NSString stringWithFormat:@"[ACTION] navigate: %@", destination]];
}

- (void)onTrackEventWithEventName:(NSString *)eventName properties:(NSDictionary<NSString *, id> *)properties {
    [self appendLog:[NSString stringWithFormat:@"[EVENT] %@", eventName]];
}

// MARK: - Helpers

- (void)appendLog:(NSString *)message {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss.SSS";
    NSString *timestamp = [fmt stringFromDate:[NSDate date]];
    NSString *entry = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *current = self->_logTextView.text ?: @"";
        if ([current isEqualToString:@"No events yet"]) current = @"";
        self->_logTextView.text = [entry stringByAppendingString:current];
    });
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendEvent];
    return YES;
}

@end

