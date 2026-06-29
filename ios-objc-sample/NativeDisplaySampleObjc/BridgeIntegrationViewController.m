#import "BridgeIntegrationViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapNativeDisplay;

// MARK: - Mock JSON Strings

static NSString * const kMockProductCard = @"{"
    "\"wzrk_id\": \"demo_unit_1\","
    "\"type\": \"native_display\","
    "\"native_display_config\": {"
    "  \"theme\": { \"id\": \"product-card\", \"defaultStyle\": { \"textColor\": \"#1F2937\", \"fontSize\": 14, \"lineHeight\": 20 } },"
    "  \"root\": {"
    "    \"type\": \"container\", \"id\": \"card\", \"containerType\": \"vertical\","
    "    \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" }, \"padding\": { \"all\": 16 }, \"arrangement\": { \"type\": \"spaced\", \"spacing\": 8 } },"
    "    \"style\": { \"backgroundColor\": \"#FFFFFF\", \"borderRadius\": 16, \"shadowRadius\": 8, \"shadowColor\": \"#000000\", \"shadowOpacity\": 0.1, \"shadowOffsetY\": 4 },"
    "    \"children\": ["
    "      { \"type\": \"element\", \"id\": \"product-image\", \"elementType\": \"image\", \"bindings\": { \"url\": \"https://yavuzceliker.github.io/sample-images/image-83.jpg\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": 180, \"unit\": \"dp\" } }, \"style\": { \"borderRadius\": 12 } },"
    "      { \"type\": \"element\", \"id\": \"product-name\", \"elementType\": \"text\", \"bindings\": { \"text\": \"Premium Wireless Headphones\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 18, \"fontWeight\": \"bold\", \"textColor\": \"#111827\", \"lineHeight\": 24 } },"
    "      { \"type\": \"element\", \"id\": \"product-price\", \"elementType\": \"text\", \"bindings\": { \"text\": \"$299.99\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 22, \"fontWeight\": \"bold\", \"textColor\": \"#10B981\", \"lineHeight\": 30 } },"
    "      { \"type\": \"element\", \"id\": \"buy-button\", \"elementType\": \"button\", \"bindings\": { \"text\": \"Add to Cart\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": 48, \"unit\": \"dp\" } }, \"style\": { \"backgroundColor\": \"#3B82F6\", \"borderRadius\": 12, \"textColor\": \"#FFFFFF\", \"fontSize\": 16, \"fontWeight\": \"bold\", \"lineHeight\": 22 } }"
    "    ]"
    "  },"
    "  \"styleClasses\": [], \"variables\": {}"
    "},"
    "\"custom_kv\": { \"campaign\": \"summer_sale\", \"category\": \"electronics\" }"
"}";

static NSString * const kMockNotification = @"{"
    "\"wzrk_id\": \"demo_unit_2\","
    "\"type\": \"native_display\","
    "\"native_display_config\": {"
    "  \"theme\": { \"id\": \"notification\", \"defaultStyle\": { \"textColor\": \"#1F2937\", \"fontSize\": 14, \"lineHeight\": 20 } },"
    "  \"root\": {"
    "    \"type\": \"container\", \"id\": \"notif-card\", \"containerType\": \"horizontal\","
    "    \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" }, \"padding\": { \"all\": 16 }, \"arrangement\": { \"type\": \"spaced\", \"spacing\": 12 } },"
    "    \"style\": { \"backgroundColor\": \"#EFF6FF\", \"borderRadius\": 12, \"borderWidth\": 1, \"borderColor\": \"#BFDBFE\" },"
    "    \"children\": ["
    "      { \"type\": \"element\", \"id\": \"notif-icon\", \"elementType\": \"image\", \"bindings\": { \"url\": \"https://yavuzceliker.github.io/sample-images/image-10.jpg\" }, \"layout\": { \"width\": { \"value\": 48, \"unit\": \"dp\" }, \"height\": { \"value\": 48, \"unit\": \"dp\" } }, \"style\": { \"borderRadius\": 24 } },"
    "      { \"type\": \"container\", \"id\": \"notif-text-group\", \"containerType\": \"vertical\", \"layout\": { \"width\": { \"value\": -1, \"unit\": \"dp\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" }, \"arrangement\": { \"type\": \"spaced\", \"spacing\": 4 } }, \"children\": ["
    "        { \"type\": \"element\", \"id\": \"notif-title\", \"elementType\": \"text\", \"bindings\": { \"text\": \"New offer available!\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 16, \"fontWeight\": \"semibold\", \"textColor\": \"#1E40AF\", \"lineHeight\": 22 } },"
    "        { \"type\": \"element\", \"id\": \"notif-body\", \"elementType\": \"text\", \"bindings\": { \"text\": \"Get 20% off your next purchase. Limited time only.\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 14, \"textColor\": \"#3B82F6\", \"lineHeight\": 20 } }"
    "      ] }"
    "    ]"
    "  },"
    "  \"styleClasses\": [], \"variables\": {}"
    "},"
    "\"custom_kv\": { \"campaign\": \"retention_offer\", \"discount\": \"20\" }"
"}";

static NSString * const kMockStatsCard = @"{"
    "\"wzrk_id\": \"demo_unit_3\","
    "\"type\": \"native_display\","
    "\"native_display_config\": {"
    "  \"theme\": { \"id\": \"stats\", \"defaultStyle\": { \"textColor\": \"#1F2937\", \"fontSize\": 14, \"lineHeight\": 20 } },"
    "  \"root\": {"
    "    \"type\": \"container\", \"id\": \"stats-card\", \"containerType\": \"vertical\","
    "    \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" }, \"padding\": { \"all\": 20 }, \"arrangement\": { \"type\": \"spaced\", \"spacing\": 12 } },"
    "    \"style\": { \"backgroundColor\": \"#F0FDF4\", \"borderRadius\": 16, \"borderWidth\": 1, \"borderColor\": \"#BBF7D0\" },"
    "    \"children\": ["
    "      { \"type\": \"element\", \"id\": \"stats-title\", \"elementType\": \"text\", \"bindings\": { \"text\": \"Your Weekly Stats\" }, \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 18, \"fontWeight\": \"bold\", \"textColor\": \"#166534\", \"lineHeight\": 24 } },"
    "      { \"type\": \"container\", \"id\": \"stats-row\", \"containerType\": \"horizontal\", \"layout\": { \"width\": { \"value\": 100, \"unit\": \"percent\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" }, \"arrangement\": { \"type\": \"space_between\" } }, \"children\": ["
    "        { \"type\": \"element\", \"id\": \"stat-visits\", \"elementType\": \"text\", \"bindings\": { \"text\": \"Visits: 142\" }, \"layout\": { \"width\": { \"value\": -2, \"unit\": \"dp\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 14, \"fontWeight\": \"medium\", \"textColor\": \"#15803D\", \"lineHeight\": 20 } },"
    "        { \"type\": \"element\", \"id\": \"stat-orders\", \"elementType\": \"text\", \"bindings\": { \"text\": \"Orders: 8\" }, \"layout\": { \"width\": { \"value\": -2, \"unit\": \"dp\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 14, \"fontWeight\": \"medium\", \"textColor\": \"#15803D\", \"lineHeight\": 20 } },"
    "        { \"type\": \"element\", \"id\": \"stat-saved\", \"elementType\": \"text\", \"bindings\": { \"text\": \"Saved: $47\" }, \"layout\": { \"width\": { \"value\": -2, \"unit\": \"dp\" }, \"height\": { \"value\": -2, \"unit\": \"dp\" } }, \"style\": { \"fontSize\": 14, \"fontWeight\": \"medium\", \"textColor\": \"#15803D\", \"lineHeight\": 20 } }"
    "      ] }"
    "    ]"
    "  },"
    "  \"styleClasses\": [], \"variables\": {}"
    "},"
    "\"custom_kv\": { \"campaign\": \"engagement_stats\", \"period\": \"weekly\" }"
"}";

// MARK: - BridgeIntegrationViewController

@interface BridgeIntegrationViewController () <NativeDisplayBridgeListener>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;

// Section views
@property (nonatomic, strong) UIStackView *renderedUnitsStack;
@property (nonatomic, strong) UILabel *renderedUnitsTitleLabel;
@property (nonatomic, strong) UITextView *eventLogTextView;
@property (nonatomic, strong) UILabel *pullResultLabel;

// Unit IDs currently displayed
@property (nonatomic, strong) NSMutableArray<NSString *> *currentUnitIds;

// Pull API text field
@property (nonatomic, strong) UITextField *unitIdTextField;

@end

@implementation BridgeIntegrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Bridge Integration";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    _currentUnitIds = [NSMutableArray array];
    [self buildLayout];
    [NativeDisplayBridge.shared addListener:self];
    [self appendLog:@"Listener registered on NativeDisplayBridge.shared"];
}

- (void)dealloc {
    [NativeDisplayBridge.shared removeListener:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [NativeDisplayBridge.shared removeListener:self];
        [self appendLog:@"Listener removed"];
    }
}

// MARK: - Layout

- (void)buildLayout {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    _contentStack = [[UIStackView alloc] init];
    _contentStack.axis = UILayoutConstraintAxisVertical;
    _contentStack.spacing = 16;
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    _contentStack.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    _contentStack.layoutMarginsRelativeArrangement = YES;
    [_scrollView addSubview:_contentStack];

    [NSLayoutConstraint activateConstraints:@[
        [_contentStack.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
        [_contentStack.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor],
        [_contentStack.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor],
        [_contentStack.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
        [_contentStack.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor],
    ]];

    // Section 1: Integration Mode
    [_contentStack addArrangedSubview:[self buildIntegrationModeSection]];
    // Section 2: Simulate Server
    [_contentStack addArrangedSubview:[self buildSimulateSection]];
    // Section 3: Pull API
    [_contentStack addArrangedSubview:[self buildPullAPISection]];
    // Section 4: Rendered Units
    [_contentStack addArrangedSubview:[self buildRenderedUnitsSection]];
    // Section 5: Event Log
    [_contentStack addArrangedSubview:[self buildEventLogSection]];
}

- (UIView *)buildSectionCard:(NSString *)title sfSymbol:(NSString *)symbol content:(UIView *)content {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor systemBackgroundColor];
    card.layer.cornerRadius = 12;
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbol]];
    iconView.tintColor = [UIColor systemBlueColor];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *headerRow = [[UIStackView alloc] initWithArrangedSubviews:@[iconView, titleLabel]];
    headerRow.axis = UILayoutConstraintAxisHorizontal;
    headerRow.spacing = 8;
    headerRow.alignment = UIStackViewAlignmentCenter;
    headerRow.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *inner = [[UIStackView alloc] initWithArrangedSubviews:@[headerRow, content]];
    inner.axis = UILayoutConstraintAxisVertical;
    inner.spacing = 12;
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:inner];

    [NSLayoutConstraint activateConstraints:@[
        [iconView.widthAnchor constraintEqualToConstant:20],
        [iconView.heightAnchor constraintEqualToConstant:20],

        [inner.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [inner.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [inner.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [inner.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];

    return card;
}

- (UIView *)buildIntegrationModeSection {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;

    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"In a real app, choose one approach:";
    desc.font = [UIFont systemFontOfSize:13];
    desc.textColor = [UIColor secondaryLabelColor];
    desc.numberOfLines = 0;

    UILabel *opt1 = [[UILabel alloc] init];
    opt1.text = @"Option 1: bind() — recommended\nNativeDisplayBridge.shared.addListener(self)\nNativeDisplayBridge.shared.bind(CleverTap.sharedInstance())";
    opt1.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    opt1.numberOfLines = 0;
    opt1.backgroundColor = [UIColor systemGray6Color];
    opt1.layer.cornerRadius = 8;
    opt1.layer.masksToBounds = YES;

    UILabel *opt3 = [[UILabel alloc] init];
    opt3.text = @"Option 3: Manual JSON (used in this demo)\nNativeDisplayBridge.shared.addListener(self)\nNativeDisplayBridge.shared.processDisplayUnits(jsonStrings)";
    opt3.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    opt3.numberOfLines = 0;
    opt3.backgroundColor = [UIColor systemGray6Color];
    opt3.layer.cornerRadius = 8;
    opt3.layer.masksToBounds = YES;

    [stack addArrangedSubview:desc];
    [stack addArrangedSubview:opt1];
    [stack addArrangedSubview:opt3];

    return [self buildSectionCard:@"Integration Mode" sfSymbol:@"link" content:stack];
}

- (UIView *)buildSimulateSection {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;

    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Tap a button to feed mock display unit JSON into the bridge.";
    desc.font = [UIFont systemFontOfSize:13];
    desc.textColor = [UIColor secondaryLabelColor];
    desc.numberOfLines = 0;

    UIButton *oneUnit = [UIButton buttonWithType:UIButtonTypeSystem];
    [oneUnit setTitle:@"1 Unit" forState:UIControlStateNormal];
    oneUnit.backgroundColor = [UIColor systemBlueColor];
    [oneUnit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    oneUnit.layer.cornerRadius = 8;
    [oneUnit addTarget:self action:@selector(simulateSingleUnit) forControlEvents:UIControlEventTouchUpInside];

    UIButton *threeUnits = [UIButton buttonWithType:UIButtonTypeSystem];
    [threeUnits setTitle:@"3 Units" forState:UIControlStateNormal];
    threeUnits.backgroundColor = [UIColor systemBlueColor];
    [threeUnits setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    threeUnits.layer.cornerRadius = 8;
    [threeUnits addTarget:self action:@selector(simulateMultipleUnits) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttonRow = [[UIStackView alloc] initWithArrangedSubviews:@[oneUnit, threeUnits]];
    buttonRow.axis = UILayoutConstraintAxisHorizontal;
    buttonRow.spacing = 12;
    buttonRow.distribution = UIStackViewDistributionFillEqually;

    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearBtn setTitle:@"Clear All" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    clearBtn.layer.cornerRadius = 8;
    clearBtn.layer.borderWidth = 1;
    clearBtn.layer.borderColor = [UIColor systemRedColor].CGColor;
    [clearBtn addTarget:self action:@selector(clearBridge) forControlEvents:UIControlEventTouchUpInside];

    [stack addArrangedSubview:desc];
    [stack addArrangedSubview:buttonRow];
    [stack addArrangedSubview:clearBtn];

    [oneUnit.heightAnchor constraintEqualToConstant:44].active = YES;
    [threeUnits.heightAnchor constraintEqualToConstant:44].active = YES;
    [clearBtn.heightAnchor constraintEqualToConstant:44].active = YES;

    return [self buildSectionCard:@"Simulate Server Response" sfSymbol:@"arrow.down.circle" content:stack];
}

- (UIView *)buildPullAPISection {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;

    UILabel *desc = [[UILabel alloc] init];
    desc.text = @"Fetch cached units on demand, without waiting for listener callbacks.";
    desc.font = [UIFont systemFontOfSize:13];
    desc.textColor = [UIColor secondaryLabelColor];
    desc.numberOfLines = 0;

    UIButton *getAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [getAllBtn setTitle:@"getAllNativeDisplays()" forState:UIControlStateNormal];
    getAllBtn.titleLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    getAllBtn.layer.cornerRadius = 8;
    getAllBtn.layer.borderWidth = 1;
    getAllBtn.layer.borderColor = [UIColor systemBlueColor].CGColor;
    [getAllBtn addTarget:self action:@selector(fetchAllUnits) forControlEvents:UIControlEventTouchUpInside];
    [getAllBtn.heightAnchor constraintEqualToConstant:44].active = YES;

    _unitIdTextField = [[UITextField alloc] init];
    _unitIdTextField.placeholder = @"Unit ID";
    _unitIdTextField.borderStyle = UITextBorderStyleRoundedRect;
    _unitIdTextField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    _unitIdTextField.text = @"demo_unit_1";

    UIButton *getByIdBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [getByIdBtn setTitle:@"Get" forState:UIControlStateNormal];
    getByIdBtn.layer.cornerRadius = 8;
    getByIdBtn.layer.borderWidth = 1;
    getByIdBtn.layer.borderColor = [UIColor systemBlueColor].CGColor;
    [getByIdBtn addTarget:self action:@selector(fetchUnitById) forControlEvents:UIControlEventTouchUpInside];
    [getByIdBtn.widthAnchor constraintEqualToConstant:60].active = YES;

    UIStackView *idRow = [[UIStackView alloc] initWithArrangedSubviews:@[_unitIdTextField, getByIdBtn]];
    idRow.axis = UILayoutConstraintAxisHorizontal;
    idRow.spacing = 8;
    idRow.alignment = UIStackViewAlignmentFill;

    _pullResultLabel = [[UILabel alloc] init];
    _pullResultLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    _pullResultLabel.textColor = [UIColor secondaryLabelColor];
    _pullResultLabel.numberOfLines = 0;
    _pullResultLabel.backgroundColor = [UIColor systemGray6Color];
    _pullResultLabel.layer.cornerRadius = 6;
    _pullResultLabel.layer.masksToBounds = YES;
    _pullResultLabel.hidden = YES;

    [stack addArrangedSubview:desc];
    [stack addArrangedSubview:getAllBtn];
    [stack addArrangedSubview:idRow];
    [stack addArrangedSubview:_pullResultLabel];

    return [self buildSectionCard:@"Pull API" sfSymbol:@"arrow.down.doc" content:stack];
}

- (UIView *)buildRenderedUnitsSection {
    UIStackView *outerStack = [[UIStackView alloc] init];
    outerStack.axis = UILayoutConstraintAxisVertical;
    outerStack.spacing = 0;

    _renderedUnitsStack = [[UIStackView alloc] init];
    _renderedUnitsStack.axis = UILayoutConstraintAxisVertical;
    _renderedUnitsStack.spacing = 16;

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"No units yet. Tap \"Simulate\" above.";
    emptyLabel.font = [UIFont systemFontOfSize:13];
    emptyLabel.textColor = [UIColor secondaryLabelColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 0;
    emptyLabel.tag = 999;
    [emptyLabel.heightAnchor constraintEqualToConstant:60].active = YES;
    [_renderedUnitsStack addArrangedSubview:emptyLabel];

    [outerStack addArrangedSubview:_renderedUnitsStack];

    _renderedUnitsTitleLabel = nil; // title set in buildSectionCard via title param

    return [self buildSectionCard:@"Rendered Units (0)" sfSymbol:@"rectangle.on.rectangle" content:outerStack];
}

- (UIView *)buildEventLogSection {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;

    _eventLogTextView = [[UITextView alloc] init];
    _eventLogTextView.editable = NO;
    _eventLogTextView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    _eventLogTextView.textColor = [UIColor greenColor];
    _eventLogTextView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    _eventLogTextView.layer.cornerRadius = 8;
    _eventLogTextView.text = @"Events will appear here as the bridge processes units.";
    _eventLogTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [_eventLogTextView.heightAnchor constraintEqualToConstant:160].active = YES;

    [stack addArrangedSubview:_eventLogTextView];

    return [self buildSectionCard:@"Event Log" sfSymbol:@"doc.text" content:stack];
}

// MARK: - Actions

- (void)simulateSingleUnit {
    [self appendLog:@"Calling processDisplayUnits with 1 mock unit..."];
    [NativeDisplayBridge.shared processDisplayUnits:@[kMockProductCard]];
}

- (void)simulateMultipleUnits {
    [self appendLog:@"Calling processDisplayUnits with 3 mock units..."];
    [NativeDisplayBridge.shared processDisplayUnits:@[kMockProductCard, kMockNotification, kMockStatsCard]];
}

- (void)clearBridge {
    [NativeDisplayBridge.shared clear];
    _currentUnitIds = [NSMutableArray array];
    [self refreshRenderedUnits];
    _pullResultLabel.hidden = YES;
    [self appendLog:@"Bridge cleared. Re-registering listener..."];
    [NativeDisplayBridge.shared addListener:self];
    [self appendLog:@"Listener re-registered"];
}

- (void)fetchAllUnits {
    NSArray<NativeDisplayUnit *> *units = [NativeDisplayBridge.shared getAllNativeDisplays];
    NSArray<NSString *> *ids = [units valueForKey:@"unitId"];
    NSString *result = [NSString stringWithFormat:@"getAllNativeDisplays() returned %lu unit(s): [%@]",
        (unsigned long)ids.count, [ids componentsJoinedByString:@", "]];
    _pullResultLabel.text = result;
    _pullResultLabel.hidden = NO;
    [self appendLog:[NSString stringWithFormat:@"Pull API: %@", result]];
}

- (void)fetchUnitById {
    NSString *unitId = [_unitIdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NativeDisplayUnit *unit = [NativeDisplayBridge.shared getNativeDisplayForId:unitId];
    NativeDisplayUIView *view = unit ? [[NativeDisplayUIView alloc] initWithUnit:unit parentWidth:self.view.bounds.size.width actionListener:nil componentListener:nil] : nil;
    NSString *result;
    if (view) {
        result = [NSString stringWithFormat:@"Found unit '%@'", unitId];
    } else {
        result = [NSString stringWithFormat:@"No unit found for id '%@'", unitId];
    }
    _pullResultLabel.text = result;
    _pullResultLabel.hidden = NO;
    [self appendLog:[NSString stringWithFormat:@"Pull API: %@", result]];
}

// MARK: - NativeDisplayBridgeListener

- (void)onNativeDisplaysLoaded:(NSArray<NativeDisplayUnit *> *)units {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<NSString *> *unitIds = [units valueForKey:@"unitId"];
        self->_currentUnitIds = [unitIds mutableCopy];
        [self refreshRenderedUnits];
        [self appendLog:[NSString stringWithFormat:@"onNativeDisplaysLoaded: received %lu unit(s)", (unsigned long)units.count]];
        for (NativeDisplayUnit *unit in units) {
            [self appendLog:[NSString stringWithFormat:@"  - unitId: %@", unit.unitId]];
        }
    });
}

- (void)refreshRenderedUnits {
    // Remove old subviews
    NSArray *subviews = [_renderedUnitsStack.arrangedSubviews copy];
    for (UIView *v in subviews) {
        [_renderedUnitsStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    if (_currentUnitIds.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"No units yet. Tap \"Simulate\" above.";
        emptyLabel.font = [UIFont systemFontOfSize:13];
        emptyLabel.textColor = [UIColor secondaryLabelColor];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.numberOfLines = 0;
        emptyLabel.tag = 999;
        [emptyLabel.heightAnchor constraintEqualToConstant:60].active = YES;
        [_renderedUnitsStack addArrangedSubview:emptyLabel];
    } else {
        for (NSString *unitId in _currentUnitIds) {
            UIView *unitContainer = [self buildUnitCard:unitId];
            [_renderedUnitsStack addArrangedSubview:unitContainer];
        }
    }
}

- (UIView *)buildUnitCard:(NSString *)unitId {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor systemBackgroundColor];
    card.layer.cornerRadius = 12;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.05f;
    card.layer.shadowRadius = 4;
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *idLabel = [[UILabel alloc] init];
    idLabel.text = unitId;
    idLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    idLabel.textColor = [UIColor systemBlueColor];
    idLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *inner = [[UIStackView alloc] initWithArrangedSubviews:@[idLabel]];
    inner.axis = UILayoutConstraintAxisVertical;
    inner.spacing = 8;
    inner.translatesAutoresizingMaskIntoConstraints = NO;

    CGFloat parentWidth = self.view.bounds.size.width - 64; // account for card padding
    NativeDisplayUnit *cachedUnit = [NativeDisplayBridge.shared getNativeDisplayForId:unitId];
    NativeDisplayUIView *displayView = cachedUnit ? [[NativeDisplayUIView alloc] initWithUnit:cachedUnit parentWidth:parentWidth actionListener:nil componentListener:nil] : nil;
    if (displayView) {
        displayView.translatesAutoresizingMaskIntoConstraints = NO;
        [displayView.heightAnchor constraintEqualToConstant:380].active = YES;
        displayView.layer.cornerRadius = 12;
        displayView.clipsToBounds = YES;
        [inner addArrangedSubview:displayView];
    }

    [card addSubview:inner];
    [NSLayoutConstraint activateConstraints:@[
        [inner.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [inner.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12],
        [inner.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
        [inner.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-12],
    ]];

    return card;
}

// MARK: - Helpers

- (void)appendLog:(NSString *)message {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss.SSS";
    NSString *timestamp = [fmt stringFromDate:[NSDate date]];
    NSString *entry = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *current = self->_eventLogTextView.text ?: @"";
        // Prepend newest entry
        self->_eventLogTextView.text = [entry stringByAppendingString:current];
    });
}

@end
