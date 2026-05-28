//
//  DemoMenuViewController.m
//  NativeDisplaySampleObjc
//
//  Menu listing all demo screens.
//

#import "DemoMenuViewController.h"
#import "ArrangementDemoViewController.h"
#import "AnimationDemoViewController.h"
#import "TestConfigBrowserViewController.h"
#import "HomeScreenViewController.h"

// ---------------------------------------------------------------------------
// MARK: - Menu item model
// ---------------------------------------------------------------------------

@interface DemoMenuItem : NSObject
@property (nonatomic, copy) NSString *icon;        // SF Symbol name
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) Class destinationClass; // UIViewController subclass
@end

@implementation DemoMenuItem
+ (instancetype)icon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle destination:(Class)cls {
    DemoMenuItem *item  = [DemoMenuItem new];
    item.icon            = icon;
    item.title           = title;
    item.subtitle        = subtitle;
    item.destinationClass = cls;
    return item;
}
@end

// ---------------------------------------------------------------------------
// MARK: - DemoMenuViewController
// ---------------------------------------------------------------------------

static NSString * const kMenuCellID = @"MenuCell";

@interface DemoMenuViewController ()
@property (nonatomic, strong) NSArray<DemoMenuItem *> *items;
@end

@implementation DemoMenuViewController

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Other Demos";
    [self buildItemList];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMenuCellID];
}

- (void)buildItemList {
    self.items = @[
        [DemoMenuItem icon:@"rectangle.3.group"
                     title:@"Arrangements"
                  subtitle:@"Explore all 7 arrangement strategies"
               destination:[ArrangementDemoViewController class]],

        [DemoMenuItem icon:@"wand.and.stars"
                     title:@"Animations"
                  subtitle:@"Container and element animations"
               destination:[AnimationDemoViewController class]],

        [DemoMenuItem icon:@"testtube.2"
                     title:@"Test Configs"
                  subtitle:@"Browse and test configurations"
               destination:[TestConfigBrowserViewController class]],

        [DemoMenuItem icon:@"house.fill"
                     title:@"Home Screen"
                  subtitle:@"Example home screen layout"
               destination:[HomeScreenViewController class]],
    ];
}

// ---------------------------------------------------------------------------
// MARK: - UITableViewDataSource
// ---------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Demo Screens";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMenuCellID];
    DemoMenuItem *item = self.items[(NSUInteger)indexPath.row];

    // Clear previous content
    for (UIView *v in cell.contentView.subviews) { [v removeFromSuperview]; }

    // Icon in rounded rect
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:item.icon]];
    iconView.tintColor = [UIColor systemBlueColor];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *iconBg = [UIView new];
    iconBg.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.1];
    iconBg.layer.cornerRadius = 8;
    iconBg.layer.masksToBounds = YES;
    iconBg.translatesAutoresizingMaskIntoConstraints = NO;
    [iconBg addSubview:iconView];

    [NSLayoutConstraint activateConstraints:@[
        [iconView.widthAnchor constraintEqualToConstant:22],
        [iconView.heightAnchor constraintEqualToConstant:22],
        [iconView.centerXAnchor constraintEqualToAnchor:iconBg.centerXAnchor],
        [iconView.centerYAnchor constraintEqualToAnchor:iconBg.centerYAnchor],
        [iconBg.widthAnchor constraintEqualToConstant:40],
        [iconBg.heightAnchor constraintEqualToConstant:40],
    ]];

    UILabel *titleLbl = [UILabel new];
    titleLbl.text = item.title;
    titleLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subLbl = [UILabel new];
    subLbl.text = item.subtitle;
    subLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    subLbl.textColor = [UIColor secondaryLabelColor];
    subLbl.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLbl, subLbl]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.spacing = 4;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *rowStack = [[UIStackView alloc] initWithArrangedSubviews:@[iconBg, textStack]];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 12;
    rowStack.alignment = UIStackViewAlignmentCenter;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;

    [cell.contentView addSubview:rowStack];
    [NSLayoutConstraint activateConstraints:@[
        [rowStack.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
        [rowStack.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
        [rowStack.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
        [rowStack.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],
    ]];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

// ---------------------------------------------------------------------------
// MARK: - UITableViewDelegate
// ---------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DemoMenuItem *item = self.items[(NSUInteger)indexPath.row];
    UIViewController *vc = [[item.destinationClass alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
