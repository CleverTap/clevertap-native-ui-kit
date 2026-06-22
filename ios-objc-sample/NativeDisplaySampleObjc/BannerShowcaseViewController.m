//
//  BannerShowcaseViewController.m
//  NativeDisplaySampleObjc
//
//  Main screen: 10 pre-defined banners + Upload Custom JSON row.
//

#import "BannerShowcaseViewController.h"
#import "BannerDetailViewController.h"
#import "DemoMenuViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapNativeDisplay;
@import UniformTypeIdentifiers;

// ---------------------------------------------------------------------------
// MARK: - Banner data model
// ---------------------------------------------------------------------------

@interface BannerItem : NSObject
@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *emoji;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *filename;
@end

@implementation BannerItem
+ (instancetype)itemId:(NSString *)itemId
                 emoji:(NSString *)emoji
                 title:(NSString *)title
              subtitle:(NSString *)subtitle
              filename:(NSString *)filename {
    BannerItem *item = [BannerItem new];
    item.itemId   = itemId;
    item.emoji    = emoji;
    item.title    = title;
    item.subtitle = subtitle;
    item.filename = filename;
    return item;
}
@end

// ---------------------------------------------------------------------------
// MARK: - BannerShowcaseViewController
// ---------------------------------------------------------------------------

static NSString * const kUploadCellID  = @"UploadCell";
static NSString * const kBannerCellID  = @"BannerCell";
static NSInteger  const kSectionUpload  = 0;
static NSInteger  const kSectionBanners = 1;

@interface BannerShowcaseViewController () <UIDocumentPickerDelegate>

@property (nonatomic, strong) NSArray<BannerItem *> *banners;
@property (nonatomic, strong, nullable) NSURL *pendingCustomURL; // retained across picker dismiss

@end

@implementation BannerShowcaseViewController

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildBannerList];
    [self setupUI];
}

// ---------------------------------------------------------------------------
// MARK: - Setup
// ---------------------------------------------------------------------------

- (void)buildBannerList {
    self.banners = @[
        [BannerItem itemId:@"banner-01" emoji:@"\U0001F31E" title:@"Summer Sale"        subtitle:@"Hero banner with gradient"      filename:@"banner-01-hero-summer-sale"],
        [BannerItem itemId:@"banner-02" emoji:@"\U0001F4F1" title:@"iPhone 15 Pro"      subtitle:@"Product showcase"               filename:@"banner-02-product-iphone"],
        [BannerItem itemId:@"banner-03" emoji:@"\U0001F389" title:@"New Features"       subtitle:@"App update announcement"        filename:@"banner-03-announcement-update"],
        [BannerItem itemId:@"banner-04" emoji:@"\u2708\uFE0F"  title:@"Travel Deals"       subtitle:@"Multi-button travel banner"     filename:@"banner-04-travel-deals"],
        [BannerItem itemId:@"banner-05" emoji:@"\U0001F457" title:@"Fashion Collection" subtitle:@"Image banner"                   filename:@"banner-05-fashion-collection"],
        [BannerItem itemId:@"banner-06" emoji:@"\U0001F4B3" title:@"Cashback Offer"     subtitle:@"Credit card with GIF"           filename:@"banner-06-credit-card-offer"],
        [BannerItem itemId:@"banner-07" emoji:@"\u2B50"     title:@"App Rating"         subtitle:@"Social proof"                   filename:@"banner-07-app-rating"],
        [BannerItem itemId:@"banner-08" emoji:@"\u26A1"     title:@"Flash Sale"         subtitle:@"Urgency banner"                 filename:@"banner-08-flash-sale"],
        [BannerItem itemId:@"banner-09" emoji:@"\U0001F48E" title:@"Go Premium"         subtitle:@"Typography showcase"            filename:@"banner-09-premium-subscription"],
        [BannerItem itemId:@"banner-10" emoji:@"\U0001F44B" title:@"Welcome"            subtitle:@"Onboarding banner"              filename:@"banner-10-welcome-onboarding"],
    ];
}

- (void)setupUI {
    self.title = @"Banner Showcase";

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kUploadCellID];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kBannerCellID];

    // "..." nav bar button -> DemoMenu
    UIImage *ellipsisImage = [UIImage systemImageNamed:@"ellipsis.circle"];
    UIBarButtonItem *menuBtn = [[UIBarButtonItem alloc]
                                initWithImage:ellipsisImage
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:@selector(openDemoMenu)];
    self.navigationItem.rightBarButtonItem = menuBtn;
}

// ---------------------------------------------------------------------------
// MARK: - Actions
// ---------------------------------------------------------------------------

- (void)openDemoMenu {
    DemoMenuViewController *menu = [DemoMenuViewController new];
    [self.navigationController pushViewController:menu animated:YES];
}

- (void)showFilePicker {
    UIDocumentPickerViewController *picker;
    if (@available(iOS 14.0, *)) {
        UTType *jsonType = [UTType typeWithIdentifier:@"public.json"];
        if (jsonType) {
            picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[jsonType]];
        } else {
            picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.json"] inMode:UIDocumentPickerModeOpen];
        }
    } else {
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.json"] inMode:UIDocumentPickerModeOpen];
    }
    picker.allowsMultipleSelection = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

// ---------------------------------------------------------------------------
// MARK: - UIDocumentPickerDelegate
// ---------------------------------------------------------------------------

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) { return; }

    BOOL accessed = [url startAccessingSecurityScopedResource];

    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&readError];

    if (accessed) { [url stopAccessingSecurityScopedResource]; }

    if (!data || readError) {
        [self showErrorTitle:@"Upload Error" message:readError.localizedDescription ?: @"Could not read file"];
        return;
    }

    // Validate by attempting to create a view (will fail if JSON is bad)
    UIView *testView = [[NativeDisplayUIView alloc] initWithJsonData:data
                                                                parentWidth:0
                                                            actionListener:nil
                                                         componentListener:nil];
    if (!testView) {
        [self showErrorTitle:@"Upload Error" message:@"Invalid JSON format"];
        return;
    }

    // Valid – navigate to BannerDetailViewController
    BannerDetailViewController *detail = [[BannerDetailViewController alloc] initWithTitle:@"\U0001F4C4 Custom JSON"
                                                                                  jsonData:data
                                                                               jsonFileURL:url];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    // User cancelled – no action required.
}

// ---------------------------------------------------------------------------
// MARK: - Helpers
// ---------------------------------------------------------------------------

- (void)showErrorTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// ---------------------------------------------------------------------------
// MARK: - UITableViewDataSource
// ---------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionUpload)  return 1;
    if (section == kSectionBanners) return (NSInteger)self.banners.count;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kSectionBanners) return @"Pre-defined Banners";
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionUpload) {
        return [self uploadCellForTableView:tableView];
    }
    return [self bannerCellForTableView:tableView atIndex:indexPath.row];
}

- (UITableViewCell *)uploadCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUploadCellID];

    // Icon
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.doc.fill"]];
    icon.tintColor = [UIColor systemBlueColor];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.frame = CGRectMake(0, 0, 24, 24);

    // Title label
    UILabel *titleLbl = [UILabel new];
    titleLbl.text = @"Upload Custom JSON";
    titleLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;

    // Subtitle label
    UILabel *subLbl = [UILabel new];
    subLbl.text = @"Load and test your own banner configuration";
    subLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    subLbl.textColor = [UIColor secondaryLabelColor];
    subLbl.translatesAutoresizingMaskIntoConstraints = NO;

    // Text stack
    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLbl, subLbl]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 4;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;

    // Row stack
    UIStackView *rowStack = [[UIStackView alloc] initWithArrangedSubviews:@[icon, textStack]];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 12;
    rowStack.alignment = UIStackViewAlignmentCenter;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;

    // Clear existing subviews added in previous reuses
    for (UIView *v in cell.contentView.subviews) { [v removeFromSuperview]; }
    [cell.contentView addSubview:rowStack];

    [NSLayoutConstraint activateConstraints:@[
        [rowStack.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [rowStack.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [rowStack.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:12],
        [rowStack.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-12],
        [icon.widthAnchor constraintEqualToConstant:28],
        [icon.heightAnchor constraintEqualToConstant:28],
    ]];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)bannerCellForTableView:(UITableView *)tableView atIndex:(NSInteger)index {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBannerCellID];
    BannerItem *banner = self.banners[(NSUInteger)index];

    // Emoji badge
    UILabel *emojiLbl = [UILabel new];
    emojiLbl.text = banner.emoji;
    emojiLbl.font = [UIFont systemFontOfSize:28];
    emojiLbl.textAlignment = NSTextAlignmentCenter;
    emojiLbl.backgroundColor = [UIColor systemGray6Color];
    emojiLbl.layer.cornerRadius = 10;
    emojiLbl.layer.masksToBounds = YES;
    emojiLbl.translatesAutoresizingMaskIntoConstraints = NO;

    // Title
    UILabel *titleLbl = [UILabel new];
    titleLbl.text = banner.title;
    titleLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;

    // Subtitle
    UILabel *subLbl = [UILabel new];
    subLbl.text = banner.subtitle;
    subLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    subLbl.textColor = [UIColor secondaryLabelColor];
    subLbl.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLbl, subLbl]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 4;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *rowStack = [[UIStackView alloc] initWithArrangedSubviews:@[emojiLbl, textStack]];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 12;
    rowStack.alignment = UIStackViewAlignmentCenter;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;

    for (UIView *v in cell.contentView.subviews) { [v removeFromSuperview]; }
    [cell.contentView addSubview:rowStack];

    [NSLayoutConstraint activateConstraints:@[
        [rowStack.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [rowStack.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [rowStack.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
        [rowStack.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],
        [emojiLbl.widthAnchor constraintEqualToConstant:50],
        [emojiLbl.heightAnchor constraintEqualToConstant:50],
    ]];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

// ---------------------------------------------------------------------------
// MARK: - UITableViewDelegate
// ---------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == kSectionUpload) {
        [self showFilePicker];
        return;
    }

    BannerItem *banner = self.banners[(NSUInteger)indexPath.row];
    NSData *data = [NDSampleHelpers loadJSONDataWithFilename:banner.filename directory:@"Banners"];
    if (!data) {
        [self showErrorTitle:@"Error" message:[NSString stringWithFormat:@"Could not load %@.json", banner.filename]];
        return;
    }

    NSString *displayTitle = [NSString stringWithFormat:@"%@ %@", banner.emoji, banner.title];
    BannerDetailViewController *detail = [[BannerDetailViewController alloc] initWithTitle:displayTitle
                                                                                  jsonData:data
                                                                               jsonFileURL:nil];
    [self.navigationController pushViewController:detail animated:YES];
}

@end
