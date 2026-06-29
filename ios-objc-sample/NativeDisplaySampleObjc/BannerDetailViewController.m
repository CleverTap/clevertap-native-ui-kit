//
//  BannerDetailViewController.m
//  NativeDisplaySampleObjc
//
//  70/30 split layout: top 70% scrollable banner, bottom 30% interaction log.
//

#import "BannerDetailViewController.h"
#import "JSONViewerViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapNativeDisplay;

// ---------------------------------------------------------------------------
// MARK: - Interaction log entry
// ---------------------------------------------------------------------------

@interface InteractionLogEntry : NSObject
@property (nonatomic, copy) NSString *typeString;    // "CLICK", "LONG_PRESS", "DOUBLE_TAP", "ACTION"
@property (nonatomic, copy) NSString *iconName;      // SF Symbol name
@property (nonatomic, copy) NSString *detail;        // node id or action description
@property (nonatomic, copy) NSString *extra;         // action data line
@property (nonatomic, copy) NSString *timestamp;
@property (nonatomic) BOOL isAction;                 // YES = green badge, NO = blue
@end

@implementation InteractionLogEntry
@end

// ---------------------------------------------------------------------------
// MARK: - Component listener (ObjC class conforming to @objc Swift protocol)
// ---------------------------------------------------------------------------

@interface BannerComponentListenerObjc : NSObject <NativeDisplayComponentListener>
@property (nonatomic, copy) void (^onInteraction)(NSString *nodeId, InteractionType type, BOOL hasServerAction);
@end

@implementation BannerComponentListenerObjc
- (BOOL)onComponentInteractionWithNodeId:(NSString *)nodeId
                         interactionType:(InteractionType)interactionType
                         hasServerAction:(BOOL)hasServerAction {
    if (self.onInteraction) {
        self.onInteraction(nodeId, interactionType, hasServerAction);
    }
    return NO; // don't consume
}
@end

// ---------------------------------------------------------------------------
// MARK: - Action listener (ObjC class conforming to @objc Swift protocol)
// ---------------------------------------------------------------------------

@interface BannerActionListenerObjc : NSObject <NativeDisplayActionListener>
@property (nonatomic, copy) void (^onAction)(NSString *description);
@end

@implementation BannerActionListenerObjc

- (void)onCustomActionWithKey:(NSString *)key value:(id _Nullable)value metadata:(NSDictionary<NSString *, NSString *> * _Nullable)metadata {
    NSString *desc = [NSString stringWithFormat:@"Custom Action: %@\nValue: %@", key, value ?: @"nil"];
    if (self.onAction) self.onAction(desc);
}

- (void)onNavigateWithDestination:(NSString *)destination params:(NSDictionary<NSString *, NSString *> * _Nullable)params {
    NSString *desc = [NSString stringWithFormat:@"Navigate: %@\nParams: %@", destination, params ?: @{}];
    if (self.onAction) self.onAction(desc);
}

- (void)onTrackEventWithEventName:(NSString *)eventName properties:(NSDictionary<NSString *, id> * _Nullable)properties {
    NSString *desc = [NSString stringWithFormat:@"Track Event: %@\nProperties: %@", eventName, properties ?: @{}];
    if (self.onAction) self.onAction(desc);
}

- (BOOL)onOpenUrlWithUrl:(NSString *)url openInBrowser:(BOOL)openInBrowser {
    NSString *desc = [NSString stringWithFormat:@"Open URL: %@\nIn Browser: %@", url, openInBrowser ? @"YES" : @"NO"];
    if (self.onAction) self.onAction(desc);
    return NO;
}

@end

// ---------------------------------------------------------------------------
// MARK: - Log table cell
// ---------------------------------------------------------------------------

@interface LogCell : UITableViewCell
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *actionBadge;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *extraLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *iconView;
@end

@implementation LogCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;
    [self buildLayout];
    return self;
}

- (void)buildLayout {
    // Icon circle
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *iconCircle = [UIView new];
    iconCircle.layer.cornerRadius = 20;
    iconCircle.layer.masksToBounds = YES;
    iconCircle.translatesAutoresizingMaskIntoConstraints = NO;
    [iconCircle addSubview:self.iconView];
    [NSLayoutConstraint activateConstraints:@[
        [self.iconView.centerXAnchor constraintEqualToAnchor:iconCircle.centerXAnchor],
        [self.iconView.centerYAnchor constraintEqualToAnchor:iconCircle.centerYAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:20],
        [self.iconView.heightAnchor constraintEqualToConstant:20],
        [iconCircle.widthAnchor constraintEqualToConstant:40],
        [iconCircle.heightAnchor constraintEqualToConstant:40],
    ]];
    self.iconView.superview.tag = 99; // mark it so we can tint later

    // Type label + action badge row
    self.typeLabel = [UILabel new];
    self.typeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.typeLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.actionBadge = [UILabel new];
    self.actionBadge.text = @"ACTION EXECUTED";
    self.actionBadge.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    self.actionBadge.textColor = [UIColor whiteColor];
    self.actionBadge.backgroundColor = [UIColor systemGreenColor];
    self.actionBadge.layer.cornerRadius = 4;
    self.actionBadge.layer.masksToBounds = YES;
    self.actionBadge.translatesAutoresizingMaskIntoConstraints = NO;
    UIEdgeInsets badgePad = UIEdgeInsetsMake(2, 6, 2, 6);
    self.actionBadge.layoutMargins = badgePad;

    UIStackView *topRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.typeLabel, self.actionBadge]];
    topRow.axis = UILayoutConstraintAxisHorizontal;
    topRow.spacing = 6;
    topRow.alignment = UIStackViewAlignmentCenter;
    topRow.translatesAutoresizingMaskIntoConstraints = NO;

    self.detailLabel = [UILabel new];
    self.detailLabel.font = [UIFont systemFontOfSize:12];
    self.detailLabel.textColor = [UIColor secondaryLabelColor];
    self.detailLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.extraLabel = [UILabel new];
    self.extraLabel.font = [UIFont systemFontOfSize:11];
    self.extraLabel.textColor = [UIColor secondaryLabelColor];
    self.extraLabel.numberOfLines = 3;
    self.extraLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.timeLabel = [UILabel new];
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel.textColor = [UIColor tertiaryLabelColor];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[topRow, self.detailLabel, self.extraLabel, self.timeLabel]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 3;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *rowStack = [[UIStackView alloc] initWithArrangedSubviews:@[iconCircle, textStack]];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 12;
    rowStack.alignment = UIStackViewAlignmentTop;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:rowStack];
    [NSLayoutConstraint activateConstraints:@[
        [rowStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [rowStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [rowStack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [rowStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
    ]];
}

- (void)configureWithEntry:(InteractionLogEntry *)entry {
    UIColor *color = entry.isAction ? [UIColor systemGreenColor] : [UIColor systemBlueColor];

    UIImage *icon = [UIImage systemImageNamed:entry.iconName];
    self.iconView.image = icon;
    self.iconView.tintColor = color;
    self.iconView.superview.backgroundColor = [color colorWithAlphaComponent:0.1];

    self.typeLabel.text = entry.typeString;
    self.actionBadge.hidden = !entry.isAction;
    self.detailLabel.text = entry.detail;
    self.detailLabel.hidden = (entry.detail.length == 0);
    self.extraLabel.text = entry.extra;
    self.timeLabel.text = entry.timestamp;
}

@end

// ---------------------------------------------------------------------------
// MARK: - BannerDetailViewController
// ---------------------------------------------------------------------------

static NSString * const kLogCellID = @"LogCell";
static NSString * const kEmptyCellID = @"EmptyCell";

@interface BannerDetailViewController () <UITableViewDataSource, UITableViewDelegate>

// Input
@property (nonatomic, copy) NSString *bannerTitle;
@property (nonatomic, strong) NSData *jsonData;
@property (nonatomic, strong, nullable) NSURL *jsonFileURL;

// UI
@property (nonatomic, strong) UIScrollView *bannerScrollView;
@property (nonatomic, strong, nullable) UIView *displayView;
@property (nonatomic, strong) UIView *bannerArea;
@property (nonatomic, strong) UIView *logArea;
@property (nonatomic, strong) UITableView *logTable;
@property (nonatomic, strong) UILabel *logCountLabel;
@property (nonatomic, strong) UIBarButtonItem *jsonViewerBtn;
@property (nonatomic, strong) UIBarButtonItem *clearBtn;

// Log data
@property (nonatomic, strong) NSMutableArray<InteractionLogEntry *> *logs;

// Listeners
@property (nonatomic, strong) BannerComponentListenerObjc *componentListener;
@property (nonatomic, strong) BannerActionListenerObjc *actionListener;

@end

@implementation BannerDetailViewController

// ---------------------------------------------------------------------------
// MARK: - Init
// ---------------------------------------------------------------------------

- (instancetype)initWithTitle:(NSString *)title
                     jsonData:(NSData *)jsonData
                  jsonFileURL:(nullable NSURL *)jsonFileURL {
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    _bannerTitle = [title copy];
    _jsonData    = jsonData;
    _jsonFileURL = jsonFileURL;
    _logs        = [NSMutableArray array];
    return self;
}

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.bannerTitle;
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupListeners];
    [self setupLayout];
    [self setupNavBar];
    [self loadBanner];
}

// ---------------------------------------------------------------------------
// MARK: - Listeners
// ---------------------------------------------------------------------------

- (void)setupListeners {
    __weak typeof(self) weakSelf = self;

    BannerComponentListenerObjc *compListener = [BannerComponentListenerObjc new];
    compListener.onInteraction = ^(NSString *nodeId, InteractionType type, BOOL hasServerAction) {
        NSString *typeStr, *iconName;
        switch (type) {
            case InteractionTypeClick:
                typeStr  = @"CLICK";
                iconName = @"hand.tap.fill";
                break;
            case InteractionTypeLongPress:
                typeStr  = @"LONG_PRESS";
                iconName = @"hand.point.up.left.fill";
                break;
            case InteractionTypeDoubleTap:
                typeStr  = @"DOUBLE_TAP";
                iconName = @"hand.draw.fill";
                break;
            default:
                typeStr  = @"INTERACTION";
                iconName = @"hand.tap.fill";
                break;
        }
        NSString *actionText = hasServerAction ? @"Has Server Action" : @"No Server Action";

        NSDateFormatter *fmt = [NSDateFormatter new];
        fmt.timeStyle = NSDateFormatterMediumStyle;
        NSString *ts = [fmt stringFromDate:[NSDate date]];

        InteractionLogEntry *entry = [InteractionLogEntry new];
        entry.typeString  = typeStr;
        entry.iconName    = iconName;
        entry.detail      = [NSString stringWithFormat:@"Node: %@", nodeId];
        entry.extra       = actionText;
        entry.timestamp   = ts;
        entry.isAction    = NO;

        [weakSelf prependLogEntry:entry];
    };
    self.componentListener = compListener;

    BannerActionListenerObjc *actListener = [BannerActionListenerObjc new];
    actListener.onAction = ^(NSString *description) {
        NSDateFormatter *fmt = [NSDateFormatter new];
        fmt.timeStyle = NSDateFormatterMediumStyle;
        NSString *ts = [fmt stringFromDate:[NSDate date]];

        InteractionLogEntry *entry = [InteractionLogEntry new];
        entry.typeString = @"ACTION";
        entry.iconName   = @"bolt.fill";
        entry.detail     = @"";
        entry.extra      = description;
        entry.timestamp  = ts;
        entry.isAction   = YES;

        [weakSelf prependLogEntry:entry];
    };
    self.actionListener = actListener;
}

// ---------------------------------------------------------------------------
// MARK: - Layout
// ---------------------------------------------------------------------------

- (void)setupLayout {
    // Banner area (70%)
    self.bannerArea = [UIView new];
    self.bannerArea.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.bannerArea.translatesAutoresizingMaskIntoConstraints = NO;

    // Scroll view inside banner area
    self.bannerScrollView = [UIScrollView new];
    self.bannerScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bannerArea addSubview:self.bannerScrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.bannerScrollView.topAnchor constraintEqualToAnchor:self.bannerArea.topAnchor],
        [self.bannerScrollView.leadingAnchor constraintEqualToAnchor:self.bannerArea.leadingAnchor],
        [self.bannerScrollView.trailingAnchor constraintEqualToAnchor:self.bannerArea.trailingAnchor],
        [self.bannerScrollView.bottomAnchor constraintEqualToAnchor:self.bannerArea.bottomAnchor],
    ]];

    // Divider
    UIView *divider = [UIView new];
    divider.backgroundColor = [UIColor separatorColor];
    divider.translatesAutoresizingMaskIntoConstraints = NO;

    // Log area (30%)
    self.logArea = [self buildLogArea];
    self.logArea.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.bannerArea];
    [self.view addSubview:divider];
    [self.view addSubview:self.logArea];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        // Banner area – top 70%
        [self.bannerArea.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.bannerArea.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bannerArea.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bannerArea.heightAnchor constraintEqualToAnchor:safe.heightAnchor multiplier:0.7],

        // Divider
        [divider.topAnchor constraintEqualToAnchor:self.bannerArea.bottomAnchor],
        [divider.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],

        // Log area – bottom 30%
        [self.logArea.topAnchor constraintEqualToAnchor:divider.bottomAnchor],
        [self.logArea.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.logArea.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.logArea.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (UIView *)buildLogArea {
    UIView *container = [UIView new];
    container.backgroundColor = [UIColor systemBackgroundColor];

    // Header
    UIImageView *listIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"list.bullet.rectangle"]];
    listIcon.tintColor = [UIColor systemBlueColor];
    listIcon.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *headerTitle = [UILabel new];
    headerTitle.text = @"Interaction Log";
    headerTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    headerTitle.translatesAutoresizingMaskIntoConstraints = NO;

    self.logCountLabel = [UILabel new];
    self.logCountLabel.text = @"0 events";
    self.logCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.logCountLabel.textColor = [UIColor secondaryLabelColor];
    self.logCountLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *headerStack = [[UIStackView alloc] initWithArrangedSubviews:@[listIcon, headerTitle]];
    headerStack.axis = UILayoutConstraintAxisHorizontal;
    headerStack.spacing = 8;
    headerStack.alignment = UIStackViewAlignmentCenter;
    headerStack.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *header = [UIView new];
    header.backgroundColor = [UIColor systemGray6Color];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:headerStack];
    [header addSubview:self.logCountLabel];
    [NSLayoutConstraint activateConstraints:@[
        [headerStack.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:16],
        [headerStack.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [self.logCountLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-16],
        [self.logCountLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [header.heightAnchor constraintEqualToConstant:44],
    ]];

    UIView *headerDivider = [UIView new];
    headerDivider.backgroundColor = [UIColor separatorColor];
    headerDivider.translatesAutoresizingMaskIntoConstraints = NO;

    // Log table
    self.logTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.logTable.dataSource = self;
    self.logTable.delegate   = self;
    self.logTable.rowHeight  = UITableViewAutomaticDimension;
    self.logTable.estimatedRowHeight = 80;
    self.logTable.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.logTable.translatesAutoresizingMaskIntoConstraints = NO;
    [self.logTable registerClass:[LogCell class] forCellReuseIdentifier:kLogCellID];
    [self.logTable registerClass:[UITableViewCell class] forCellReuseIdentifier:kEmptyCellID];

    [container addSubview:header];
    [container addSubview:headerDivider];
    [container addSubview:self.logTable];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:container.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [headerDivider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [headerDivider.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [headerDivider.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [headerDivider.heightAnchor constraintEqualToConstant:1],
        [self.logTable.topAnchor constraintEqualToAnchor:headerDivider.bottomAnchor],
        [self.logTable.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [self.logTable.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [self.logTable.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];

    return container;
}

// ---------------------------------------------------------------------------
// MARK: - Nav Bar
// ---------------------------------------------------------------------------

- (void)setupNavBar {
    // JSON viewer button
    UIImage *docIcon = [UIImage systemImageNamed:@"doc.text.fill"];
    self.jsonViewerBtn = [[UIBarButtonItem alloc] initWithImage:docIcon
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(openJSONViewer)];
    self.jsonViewerBtn.tintColor = [UIColor systemBlueColor];

    // Clear / trash button
    UIImage *trashIcon = [UIImage systemImageNamed:@"trash"];
    self.clearBtn = [[UIBarButtonItem alloc] initWithImage:trashIcon
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(clearLogs)];
    self.clearBtn.tintColor = [UIColor systemRedColor];
    self.clearBtn.enabled = NO;

    self.navigationItem.rightBarButtonItems = @[self.clearBtn, self.jsonViewerBtn];
}

// ---------------------------------------------------------------------------
// MARK: - Banner Loading
// ---------------------------------------------------------------------------

- (void)loadBanner {
    UIView *view = [[NativeDisplayUIView alloc] initWithJsonData:self.jsonData
                                                             parentWidth:self.view.bounds.size.width
                                                         actionListener:self.actionListener
                                                      componentListener:self.componentListener];
    if (!view) {
        [self showErrorMessage:@"Failed to create banner view"];
        return;
    }

    // Remove previous display view if any
    [self.displayView removeFromSuperview];
    self.displayView = view;

    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bannerScrollView addSubview:view];

    [NSLayoutConstraint activateConstraints:@[
        [view.topAnchor constraintEqualToAnchor:self.bannerScrollView.topAnchor constant:16],
        [view.leadingAnchor constraintEqualToAnchor:self.bannerScrollView.leadingAnchor constant:16],
        [view.trailingAnchor constraintEqualToAnchor:self.bannerScrollView.trailingAnchor constant:-16],
        [view.bottomAnchor constraintEqualToAnchor:self.bannerScrollView.bottomAnchor constant:-16],
        [view.widthAnchor constraintEqualToAnchor:self.bannerScrollView.widthAnchor constant:-32],
    ]];
}

- (void)showErrorMessage:(NSString *)message {
    UILabel *errorLbl = [UILabel new];
    errorLbl.text = [NSString stringWithFormat:@"Error loading banner:\n\n%@", message];
    errorLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    errorLbl.textColor = [UIColor secondaryLabelColor];
    errorLbl.textAlignment = NSTextAlignmentCenter;
    errorLbl.numberOfLines = 0;
    errorLbl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bannerArea addSubview:errorLbl];
    [NSLayoutConstraint activateConstraints:@[
        [errorLbl.centerXAnchor constraintEqualToAnchor:self.bannerArea.centerXAnchor],
        [errorLbl.centerYAnchor constraintEqualToAnchor:self.bannerArea.centerYAnchor],
        [errorLbl.leadingAnchor constraintEqualToAnchor:self.bannerArea.leadingAnchor constant:32],
        [errorLbl.trailingAnchor constraintEqualToAnchor:self.bannerArea.trailingAnchor constant:-32],
    ]];
}

// ---------------------------------------------------------------------------
// MARK: - Log helpers
// ---------------------------------------------------------------------------

- (void)prependLogEntry:(InteractionLogEntry *)entry {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logs insertObject:entry atIndex:0];
        self.logCountLabel.text = [NSString stringWithFormat:@"%lu events", (unsigned long)self.logs.count];
        self.clearBtn.enabled = YES;
        [self.logTable reloadData];
        NSLog(@"Interaction: %@ | %@", entry.typeString, entry.detail);
    });
}

- (void)clearLogs {
    [self.logs removeAllObjects];
    self.logCountLabel.text = @"0 events";
    self.clearBtn.enabled = NO;
    [self.logTable reloadData];
}

- (void)openJSONViewer {
    NSString *jsonString = [[NSString alloc] initWithData:self.jsonData encoding:NSUTF8StringEncoding];
    if (!jsonString) { return; }
    JSONViewerViewController *viewer = [[JSONViewerViewController alloc] initWithJSONString:jsonString title:@"Banner JSON"];
    [self.navigationController pushViewController:viewer animated:YES];
}

// ---------------------------------------------------------------------------
// MARK: - UITableViewDataSource
// ---------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logs.count == 0 ? 1 : (NSInteger)self.logs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.logs.count == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kEmptyCellID];
        cell.textLabel.text = @"Tap banner components to see interactions";
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        cell.textLabel.textColor = [UIColor secondaryLabelColor];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    LogCell *cell = [tableView dequeueReusableCellWithIdentifier:kLogCellID];
    [cell configureWithEntry:self.logs[(NSUInteger)indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

// ---------------------------------------------------------------------------
// MARK: - UITableViewDelegate
// ---------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
