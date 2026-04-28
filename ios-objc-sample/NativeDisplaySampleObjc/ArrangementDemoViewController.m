//
//  ArrangementDemoViewController.m
//  NativeDisplaySampleObjc
//
//  7 pill buttons for arrangement strategies + NativeDisplayUIView content area.
//

#import "ArrangementDemoViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"

// ---------------------------------------------------------------------------
// MARK: - Strategy descriptor
// ---------------------------------------------------------------------------

@interface StrategyItem : NSObject
@property (nonatomic, copy) NSString *label;       // e.g. "SPACED"
@property (nonatomic, copy) NSString *strategyKey; // key passed to NDDisplayHelper
@end

@implementation StrategyItem
+ (instancetype)label:(NSString *)label key:(NSString *)key {
    StrategyItem *item = [StrategyItem new];
    item.label       = label;
    item.strategyKey = key;
    return item;
}
@end

// ---------------------------------------------------------------------------
// MARK: - Pill button
// ---------------------------------------------------------------------------

@interface PillButton : UIButton
@property (nonatomic) BOOL isSelectedPill;
- (void)setSelectedPill:(BOOL)selected;
@end

@implementation PillButton

- (void)setSelectedPill:(BOOL)selected {
    _isSelectedPill = selected;
    if (selected) {
        self.backgroundColor = [UIColor systemBlueColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.backgroundColor = [UIColor systemGray5Color];
        [self setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    }
}

@end

// ---------------------------------------------------------------------------
// MARK: - ArrangementDemoViewController
// ---------------------------------------------------------------------------

@interface ArrangementDemoViewController ()

@property (nonatomic, strong) NSArray<StrategyItem *> *strategies;
@property (nonatomic)         NSInteger selectedIndex;
@property (nonatomic, strong) NSData   *arrangementJSON;

// UI
@property (nonatomic, strong) UIScrollView           *pillScrollView;
@property (nonatomic, strong) UIStackView            *pillStack;
@property (nonatomic, strong) NSMutableArray<PillButton *> *pillButtons;
@property (nonatomic, strong) UIScrollView           *contentScrollView;
@property (nonatomic, strong, nullable) UIView *displayView;
@property (nonatomic, strong) UIView                 *contentContainer;

@end

@implementation ArrangementDemoViewController

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Arrangements";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.selectedIndex = 0;

    [self buildStrategies];
    [self loadArrangementJSON];
    [self setupLayout];
    [self buildPillButtons];
    [self reloadDisplayView];
}

// ---------------------------------------------------------------------------
// MARK: - Data
// ---------------------------------------------------------------------------

- (void)buildStrategies {
    self.strategies = @[
        [StrategyItem label:@"SPACED"  key:@"spaced"],
        [StrategyItem label:@"BETWEEN" key:@"space_between"],
        [StrategyItem label:@"EVENLY"  key:@"space_evenly"],
        [StrategyItem label:@"AROUND"  key:@"space_around"],
        [StrategyItem label:@"START"   key:@"start"],
        [StrategyItem label:@"CENTER"  key:@"center"],
        [StrategyItem label:@"END"     key:@"end"],
    ];
}

- (void)loadArrangementJSON {
    self.arrangementJSON = [NDDisplayHelper loadJSONDataWithFilename:@"arrangement_demo" directory:nil];
}

// ---------------------------------------------------------------------------
// MARK: - Layout
// ---------------------------------------------------------------------------

- (void)setupLayout {
    // Pill scroll view at top
    self.pillScrollView = [UIScrollView new];
    self.pillScrollView.showsHorizontalScrollIndicator = NO;
    self.pillScrollView.backgroundColor = [UIColor systemBackgroundColor];
    self.pillScrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.pillStack = [[UIStackView alloc] initWithArrangedSubviews:@[]];
    self.pillStack.axis = UILayoutConstraintAxisHorizontal;
    self.pillStack.spacing = 8;
    self.pillStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pillScrollView addSubview:self.pillStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.pillStack.leadingAnchor constraintEqualToAnchor:self.pillScrollView.leadingAnchor constant:16],
        [self.pillStack.trailingAnchor constraintEqualToAnchor:self.pillScrollView.trailingAnchor constant:-16],
        [self.pillStack.topAnchor constraintEqualToAnchor:self.pillScrollView.topAnchor constant:8],
        [self.pillStack.bottomAnchor constraintEqualToAnchor:self.pillScrollView.bottomAnchor constant:-8],
        [self.pillStack.heightAnchor constraintEqualToAnchor:self.pillScrollView.heightAnchor constant:-16],
    ]];

    // Shadow under pill strip
    self.pillScrollView.layer.shadowColor  = [UIColor blackColor].CGColor;
    self.pillScrollView.layer.shadowOpacity = 0.05f;
    self.pillScrollView.layer.shadowOffset  = CGSizeMake(0, 2);
    self.pillScrollView.layer.shadowRadius  = 2;

    // Content area
    self.contentContainer = [UIView new];
    self.contentContainer.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
    self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;

    self.contentScrollView = [UIScrollView new];
    self.contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentContainer addSubview:self.contentScrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentScrollView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [self.contentScrollView.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [self.contentScrollView.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [self.contentScrollView.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor],
    ]];

    [self.view addSubview:self.pillScrollView];
    [self.view addSubview:self.contentContainer];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.pillScrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.pillScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pillScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pillScrollView.heightAnchor constraintEqualToConstant:52],

        [self.contentContainer.topAnchor constraintEqualToAnchor:self.pillScrollView.bottomAnchor],
        [self.contentContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentContainer.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (void)buildPillButtons {
    self.pillButtons = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.strategies.count; i++) {
        StrategyItem *strategy = self.strategies[i];
        PillButton *btn = [PillButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:strategy.label forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        btn.layer.cornerRadius = 17;
        btn.layer.masksToBounds = YES;
        btn.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
        btn.tag = (NSInteger)i;
        [btn addTarget:self action:@selector(pillTapped:) forControlEvents:UIControlEventTouchUpInside];
        [btn setSelectedPill:(i == (NSUInteger)self.selectedIndex)];
        [self.pillStack addArrangedSubview:btn];
        [self.pillButtons addObject:btn];
    }
}

// ---------------------------------------------------------------------------
// MARK: - Actions
// ---------------------------------------------------------------------------

- (void)pillTapped:(PillButton *)sender {
    if (sender.tag == self.selectedIndex) { return; }

    // Deselect old
    [self.pillButtons[(NSUInteger)self.selectedIndex] setSelectedPill:NO];
    // Select new
    self.selectedIndex = sender.tag;
    [sender setSelectedPill:YES];

    [self reloadDisplayView];
}

// ---------------------------------------------------------------------------
// MARK: - Display view management
// ---------------------------------------------------------------------------

- (void)reloadDisplayView {
    if (!self.arrangementJSON) { return; }

    [self.displayView removeFromSuperview];
    self.displayView = nil;

    StrategyItem *strategy = self.strategies[(NSUInteger)self.selectedIndex];
    NSError *error = nil;
    CGFloat parentWidth = self.view.bounds.size.width;
    UIView *view = [NDDisplayHelper createViewFrom:self.arrangementJSON
                                                    parentWidth:parentWidth
                                            arrangementStrategy:strategy.strategyKey
                                              componentListener:nil
                                                 actionListener:nil
                                                          error:&error];
    if (!view) {
        NSLog(@"ArrangementDemo error: %@", error);
        return;
    }

    self.displayView = view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentScrollView addSubview:view];

    [NSLayoutConstraint activateConstraints:@[
        [view.topAnchor constraintEqualToAnchor:self.contentScrollView.topAnchor constant:16],
        [view.leadingAnchor constraintEqualToAnchor:self.contentScrollView.leadingAnchor constant:16],
        [view.trailingAnchor constraintEqualToAnchor:self.contentScrollView.trailingAnchor constant:-16],
        [view.bottomAnchor constraintEqualToAnchor:self.contentScrollView.bottomAnchor constant:-16],
        [view.widthAnchor constraintEqualToAnchor:self.contentScrollView.widthAnchor constant:-32],
    ]];
}

@end
