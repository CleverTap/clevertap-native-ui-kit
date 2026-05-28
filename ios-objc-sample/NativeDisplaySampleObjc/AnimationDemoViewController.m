//
//  AnimationDemoViewController.m
//  NativeDisplaySampleObjc
//
//  3 animation demo options with info card and NativeDisplayUIView content area.
//

#import "AnimationDemoViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"

// ---------------------------------------------------------------------------
// MARK: - Demo descriptor
// ---------------------------------------------------------------------------

@interface AnimationDemoItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *infoText;
@end

@implementation AnimationDemoItem
+ (instancetype)title:(NSString *)title filename:(NSString *)filename info:(NSString *)info {
    AnimationDemoItem *item = [AnimationDemoItem new];
    item.title    = title;
    item.filename = filename;
    item.infoText = info;
    return item;
}
@end

// ---------------------------------------------------------------------------
// MARK: - AnimationDemoViewController
// ---------------------------------------------------------------------------

@interface AnimationDemoViewController ()

@property (nonatomic, strong) NSArray<AnimationDemoItem *> *demos;
@property (nonatomic)         NSInteger selectedIndex;

// UI
@property (nonatomic, strong) UIScrollView  *demoScrollView;
@property (nonatomic, strong) UIStackView   *demoButtonStack;
@property (nonatomic, strong) NSMutableArray<UIButton *> *demoButtons;
@property (nonatomic, strong) UIView        *infoCard;
@property (nonatomic, strong) UILabel       *infoLabel;
@property (nonatomic, strong) UIScrollView  *contentScrollView;
@property (nonatomic, strong, nullable) UIView *displayView;

@end

@implementation AnimationDemoViewController

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Animations";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.selectedIndex = 0;

    [self buildDemos];
    [self setupLayout];
    [self buildDemoButtons];
    [self reloadDisplayView];
}

// ---------------------------------------------------------------------------
// MARK: - Data
// ---------------------------------------------------------------------------

- (void)buildDemos {
    self.demos = @[
        [AnimationDemoItem
            title:@"Container Fade"
         filename:@"animation_container_fade"
             info:@"Entire container fades in (500ms). All children appear together."],

        [AnimationDemoItem
            title:@"Staggered Children"
         filename:@"animation_staggered_children"
             info:@"Each child slides in from left with 100ms stagger delay (0ms, 100ms, 200ms, 300ms, 400ms)."],

        [AnimationDemoItem
            title:@"Container + Children"
         filename:@"animation_container_and_children"
             info:@"Container fades in first (0ms), then image scales (400ms delay), text slides (600ms, 800ms delay), features fade-scale (1000-1200ms delay), button springs (1400ms)."],
    ];
}

// ---------------------------------------------------------------------------
// MARK: - Layout
// ---------------------------------------------------------------------------

- (void)setupLayout {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // Demo button strip
    self.demoScrollView = [UIScrollView new];
    self.demoScrollView.showsHorizontalScrollIndicator = NO;
    self.demoScrollView.backgroundColor = [UIColor systemBackgroundColor];
    self.demoScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.demoScrollView.layer.shadowColor   = [UIColor blackColor].CGColor;
    self.demoScrollView.layer.shadowOpacity = 0.05f;
    self.demoScrollView.layer.shadowOffset  = CGSizeMake(0, 2);
    self.demoScrollView.layer.shadowRadius  = 2;

    self.demoButtonStack = [[UIStackView alloc] initWithArrangedSubviews:@[]];
    self.demoButtonStack.axis = UILayoutConstraintAxisHorizontal;
    self.demoButtonStack.spacing = 8;
    self.demoButtonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.demoScrollView addSubview:self.demoButtonStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.demoButtonStack.leadingAnchor constraintEqualToAnchor:self.demoScrollView.leadingAnchor constant:16],
        [self.demoButtonStack.trailingAnchor constraintEqualToAnchor:self.demoScrollView.trailingAnchor constant:-16],
        [self.demoButtonStack.topAnchor constraintEqualToAnchor:self.demoScrollView.topAnchor constant:8],
        [self.demoButtonStack.bottomAnchor constraintEqualToAnchor:self.demoScrollView.bottomAnchor constant:-8],
        [self.demoButtonStack.heightAnchor constraintEqualToAnchor:self.demoScrollView.heightAnchor constant:-16],
    ]];

    // Info card – orange background
    self.infoCard = [UIView new];
    self.infoCard.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.88 alpha:1.0]; // #FFF3E0
    self.infoCard.layer.cornerRadius = 8;
    self.infoCard.layer.masksToBounds = YES;
    self.infoCard.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *bulbIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lightbulb.fill"]];
    bulbIcon.tintColor = [UIColor colorWithRed:0.90 green:0.32 blue:0.0 alpha:1.0]; // #E65100
    bulbIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [bulbIcon setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

    self.infoLabel = [UILabel new];
    self.infoLabel.font = [UIFont systemFontOfSize:14];
    self.infoLabel.textColor = [UIColor colorWithRed:0.90 green:0.32 blue:0.0 alpha:1.0];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *infoRow = [[UIStackView alloc] initWithArrangedSubviews:@[bulbIcon, self.infoLabel]];
    infoRow.axis = UILayoutConstraintAxisHorizontal;
    infoRow.spacing = 8;
    infoRow.alignment = UIStackViewAlignmentTop;
    infoRow.translatesAutoresizingMaskIntoConstraints = NO;

    [self.infoCard addSubview:infoRow];
    [NSLayoutConstraint activateConstraints:@[
        [infoRow.topAnchor constraintEqualToAnchor:self.infoCard.topAnchor constant:12],
        [infoRow.leadingAnchor constraintEqualToAnchor:self.infoCard.leadingAnchor constant:12],
        [infoRow.trailingAnchor constraintEqualToAnchor:self.infoCard.trailingAnchor constant:-12],
        [infoRow.bottomAnchor constraintEqualToAnchor:self.infoCard.bottomAnchor constant:-12],
    ]];

    UIView *infoWrapper = [UIView new];
    infoWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [infoWrapper addSubview:self.infoCard];
    [NSLayoutConstraint activateConstraints:@[
        [self.infoCard.topAnchor constraintEqualToAnchor:infoWrapper.topAnchor constant:8],
        [self.infoCard.leadingAnchor constraintEqualToAnchor:infoWrapper.leadingAnchor constant:16],
        [self.infoCard.trailingAnchor constraintEqualToAnchor:infoWrapper.trailingAnchor constant:-16],
        [self.infoCard.bottomAnchor constraintEqualToAnchor:infoWrapper.bottomAnchor constant:-8],
    ]];

    // Content area
    UIView *contentBg = [UIView new];
    contentBg.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
    contentBg.translatesAutoresizingMaskIntoConstraints = NO;

    self.contentScrollView = [UIScrollView new];
    self.contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentBg addSubview:self.contentScrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentScrollView.topAnchor constraintEqualToAnchor:contentBg.topAnchor],
        [self.contentScrollView.leadingAnchor constraintEqualToAnchor:contentBg.leadingAnchor],
        [self.contentScrollView.trailingAnchor constraintEqualToAnchor:contentBg.trailingAnchor],
        [self.contentScrollView.bottomAnchor constraintEqualToAnchor:contentBg.bottomAnchor],
    ]];

    // Main vertical stack
    UIStackView *mainStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.demoScrollView, infoWrapper, contentBg]];
    mainStack.axis = UILayoutConstraintAxisVertical;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];

    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [mainStack.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.demoScrollView.heightAnchor constraintEqualToConstant:52],
        [contentBg.heightAnchor constraintGreaterThanOrEqualToConstant:100],
    ]];

    // Make contentBg expand
    [contentBg setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
}

- (void)buildDemoButtons {
    self.demoButtons = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.demos.count; i++) {
        AnimationDemoItem *demo = self.demos[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:demo.title forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        btn.layer.cornerRadius = 17;
        btn.layer.masksToBounds = YES;
        btn.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
        btn.tag = (NSInteger)i;
        [btn addTarget:self action:@selector(demoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self updateButton:btn selected:(i == (NSUInteger)self.selectedIndex)];
        [self.demoButtonStack addArrangedSubview:btn];
        [self.demoButtons addObject:btn];
    }
}

- (void)updateButton:(UIButton *)btn selected:(BOOL)selected {
    if (selected) {
        btn.backgroundColor = [UIColor systemBlueColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        btn.backgroundColor = [UIColor systemGray5Color];
        [btn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    }
}

// ---------------------------------------------------------------------------
// MARK: - Actions
// ---------------------------------------------------------------------------

- (void)demoButtonTapped:(UIButton *)sender {
    if (sender.tag == self.selectedIndex) { return; }
    [self updateButton:self.demoButtons[(NSUInteger)self.selectedIndex] selected:NO];
    self.selectedIndex = sender.tag;
    [self updateButton:sender selected:YES];
    [self reloadDisplayView];
}

// ---------------------------------------------------------------------------
// MARK: - Display view management
// ---------------------------------------------------------------------------

- (void)reloadDisplayView {
    AnimationDemoItem *demo = self.demos[(NSUInteger)self.selectedIndex];
    self.infoLabel.text = demo.infoText;

    [self.displayView removeFromSuperview];
    self.displayView = nil;

    NSData *jsonData = [NDDisplayHelper loadJSONDataWithFilename:demo.filename directory:nil];
    if (!jsonData) {
        NSLog(@"AnimationDemo: could not load %@.json", demo.filename);
        return;
    }

    NSError *error = nil;
    CGFloat parentWidth = self.view.bounds.size.width;
    UIView *view = [NDDisplayHelper createViewFrom:jsonData
                                                     parentWidth:parentWidth
                                              componentListener:nil
                                                 actionListener:nil
                                                          error:&error];
    if (!view) {
        NSLog(@"AnimationDemo error: %@", error);
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
