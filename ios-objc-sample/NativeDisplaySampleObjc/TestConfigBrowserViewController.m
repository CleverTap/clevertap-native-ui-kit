//
//  TestConfigBrowserViewController.m
//  NativeDisplaySampleObjc
//
//  Sequential browser: title bar, prev/next, chip strip, content area.
//

#import "TestConfigBrowserViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"

// ---------------------------------------------------------------------------
// MARK: - Chip button
// ---------------------------------------------------------------------------

@interface ChipButton : UIButton
@end

@implementation ChipButton
@end

// ---------------------------------------------------------------------------
// MARK: - TestConfigBrowserViewController
// ---------------------------------------------------------------------------

@interface TestConfigBrowserViewController ()

@property (nonatomic, strong) NSArray<NSString *> *testFiles;
@property (nonatomic)         NSInteger            currentIndex;

// UI
@property (nonatomic, strong) UILabel         *counterLabel;
@property (nonatomic, strong) UILabel         *filenameLabel;
@property (nonatomic, strong) UIButton        *prevButton;
@property (nonatomic, strong) UIButton        *nextButton;
@property (nonatomic, strong) UIScrollView    *chipScrollView;
@property (nonatomic, strong) UIStackView     *chipStack;
@property (nonatomic, strong) NSMutableArray<ChipButton *> *chipButtons;
@property (nonatomic, strong) UIScrollView    *contentScrollView;
@property (nonatomic, strong) UIView          *contentBg;
@property (nonatomic, strong, nullable) UIView *displayView;

@end

@implementation TestConfigBrowserViewController

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Test Configs";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.currentIndex = 0;

    self.testFiles = [NDDisplayHelper discoverTestFiles];

    [self setupLayout];
    [self buildChips];
    [self updateCounter];
    if (self.testFiles.count > 0) {
        [self loadCurrentConfig];
    }
}

// ---------------------------------------------------------------------------
// MARK: - Layout
// ---------------------------------------------------------------------------

- (void)setupLayout {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // ── Title bar ──────────────────────────────────────────────────
    UILabel *titleLbl = [UILabel new];
    titleLbl.text = @"Test Browser";
    titleLbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;

    self.counterLabel = [UILabel new];
    self.counterLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
    self.counterLabel.textColor = [UIColor secondaryLabelColor];
    self.counterLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *titleBar = [UIView new];
    titleBar.backgroundColor = [UIColor systemBackgroundColor];
    titleBar.translatesAutoresizingMaskIntoConstraints = NO;
    [titleBar addSubview:titleLbl];
    [titleBar addSubview:self.counterLabel];
    [NSLayoutConstraint activateConstraints:@[
        [titleLbl.leadingAnchor constraintEqualToAnchor:titleBar.leadingAnchor constant:16],
        [titleLbl.centerYAnchor constraintEqualToAnchor:titleBar.centerYAnchor],
        [self.counterLabel.trailingAnchor constraintEqualToAnchor:titleBar.trailingAnchor constant:-16],
        [self.counterLabel.centerYAnchor constraintEqualToAnchor:titleBar.centerYAnchor],
        [titleBar.heightAnchor constraintEqualToConstant:44],
    ]];

    UIView *divider1 = [self hairlineDivider];

    // ── Navigation row ─────────────────────────────────────────────
    self.prevButton = [self navButtonWithImage:@"chevron.left" action:@selector(goToPrev)];
    self.nextButton = [self navButtonWithImage:@"chevron.right" action:@selector(goToNext)];
    self.nextButton.accessibilityIdentifier = @"nav-next";

    self.filenameLabel = [UILabel new];
    self.filenameLabel.font = [UIFont systemFontOfSize:13];
    self.filenameLabel.textAlignment = NSTextAlignmentCenter;
    self.filenameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.filenameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *navRow = [UIView new];
    navRow.backgroundColor = [UIColor secondarySystemBackgroundColor];
    navRow.translatesAutoresizingMaskIntoConstraints = NO;
    [navRow addSubview:self.prevButton];
    [navRow addSubview:self.filenameLabel];
    [navRow addSubview:self.nextButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.prevButton.leadingAnchor constraintEqualToAnchor:navRow.leadingAnchor],
        [self.prevButton.topAnchor constraintEqualToAnchor:navRow.topAnchor],
        [self.prevButton.bottomAnchor constraintEqualToAnchor:navRow.bottomAnchor],
        [self.prevButton.widthAnchor constraintEqualToConstant:44],
        [self.nextButton.trailingAnchor constraintEqualToAnchor:navRow.trailingAnchor],
        [self.nextButton.topAnchor constraintEqualToAnchor:navRow.topAnchor],
        [self.nextButton.bottomAnchor constraintEqualToAnchor:navRow.bottomAnchor],
        [self.nextButton.widthAnchor constraintEqualToConstant:44],
        [self.filenameLabel.leadingAnchor constraintEqualToAnchor:self.prevButton.trailingAnchor],
        [self.filenameLabel.trailingAnchor constraintEqualToAnchor:self.nextButton.leadingAnchor],
        [self.filenameLabel.centerYAnchor constraintEqualToAnchor:navRow.centerYAnchor],
        [navRow.heightAnchor constraintEqualToConstant:44],
    ]];

    UIView *divider2 = [self hairlineDivider];

    // ── Chip strip ─────────────────────────────────────────────────
    self.chipScrollView = [UIScrollView new];
    self.chipScrollView.showsHorizontalScrollIndicator = NO;
    self.chipScrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.chipStack = [[UIStackView alloc] initWithArrangedSubviews:@[]];
    self.chipStack.axis = UILayoutConstraintAxisHorizontal;
    self.chipStack.spacing = 4;
    self.chipStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.chipScrollView addSubview:self.chipStack];
    [NSLayoutConstraint activateConstraints:@[
        [self.chipStack.leadingAnchor constraintEqualToAnchor:self.chipScrollView.leadingAnchor constant:8],
        [self.chipStack.trailingAnchor constraintEqualToAnchor:self.chipScrollView.trailingAnchor constant:-8],
        [self.chipStack.topAnchor constraintEqualToAnchor:self.chipScrollView.topAnchor constant:6],
        [self.chipStack.bottomAnchor constraintEqualToAnchor:self.chipScrollView.bottomAnchor constant:-6],
        [self.chipStack.heightAnchor constraintEqualToAnchor:self.chipScrollView.heightAnchor constant:-12],
    ]];

    UIView *divider3 = [self hairlineDivider];

    // ── Content area ───────────────────────────────────────────────
    self.contentBg = [UIView new];
    self.contentBg.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.contentBg.translatesAutoresizingMaskIntoConstraints = NO;

    self.contentScrollView = [UIScrollView new];
    self.contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentBg addSubview:self.contentScrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentScrollView.topAnchor constraintEqualToAnchor:self.contentBg.topAnchor],
        [self.contentScrollView.leadingAnchor constraintEqualToAnchor:self.contentBg.leadingAnchor],
        [self.contentScrollView.trailingAnchor constraintEqualToAnchor:self.contentBg.trailingAnchor],
        [self.contentScrollView.bottomAnchor constraintEqualToAnchor:self.contentBg.bottomAnchor],
    ]];

    // ── Assemble ───────────────────────────────────────────────────
    for (UIView *v in @[titleBar, divider1, navRow, divider2, self.chipScrollView, divider3, self.contentBg]) {
        [self.view addSubview:v];
    }

    [NSLayoutConstraint activateConstraints:@[
        [titleBar.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [titleBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [titleBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [divider1.topAnchor constraintEqualToAnchor:titleBar.bottomAnchor],
        [divider1.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [divider1.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [navRow.topAnchor constraintEqualToAnchor:divider1.bottomAnchor],
        [navRow.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [navRow.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [divider2.topAnchor constraintEqualToAnchor:navRow.bottomAnchor],
        [divider2.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [divider2.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [self.chipScrollView.topAnchor constraintEqualToAnchor:divider2.bottomAnchor],
        [self.chipScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chipScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.chipScrollView.heightAnchor constraintEqualToConstant:36],

        [divider3.topAnchor constraintEqualToAnchor:self.chipScrollView.bottomAnchor],
        [divider3.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [divider3.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [self.contentBg.topAnchor constraintEqualToAnchor:divider3.bottomAnchor],
        [self.contentBg.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentBg.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentBg.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (UIView *)hairlineDivider {
    UIView *v = [UIView new];
    v.backgroundColor = [UIColor separatorColor];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v.heightAnchor constraintEqualToConstant:0.5].active = YES;
    return v;
}

- (UIButton *)navButtonWithImage:(NSString *)imageName action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setImage:[UIImage systemImageNamed:imageName] forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buildChips {
    self.chipButtons = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.testFiles.count; i++) {
        NSString *filename = self.testFiles[i];
        NSString *chipLabel = [self extractNumber:filename];

        ChipButton *chip = [ChipButton buttonWithType:UIButtonTypeCustom];
        [chip setTitle:chipLabel forState:UIControlStateNormal];
        chip.titleLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
        chip.layer.cornerRadius = 4;
        chip.layer.masksToBounds = YES;
        chip.contentEdgeInsets = UIEdgeInsetsMake(4, 6, 4, 6);
        chip.tag = (NSInteger)i;
        chip.accessibilityIdentifier = [NSString stringWithFormat:@"chip-%@", filename];
        [chip addTarget:self action:@selector(chipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self updateChip:chip selected:(i == (NSUInteger)self.currentIndex)];
        [self.chipStack addArrangedSubview:chip];
        [self.chipButtons addObject:chip];
    }
}

- (void)updateChip:(UIButton *)chip selected:(BOOL)selected {
    if (selected) {
        chip.backgroundColor = [UIColor systemBlueColor];
        [chip setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        chip.titleLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightSemibold];
    } else {
        chip.backgroundColor = [UIColor tertiarySystemBackgroundColor];
        [chip setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        chip.titleLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    }
}

// ---------------------------------------------------------------------------
// MARK: - Navigation
// ---------------------------------------------------------------------------

- (void)goToPrev {
    if (self.testFiles.count == 0) { return; }
    NSInteger next = self.currentIndex == 0 ? (NSInteger)self.testFiles.count - 1 : self.currentIndex - 1;
    [self jumpToIndex:next];
}

- (void)goToNext {
    if (self.testFiles.count == 0) { return; }
    NSInteger next = self.currentIndex == (NSInteger)self.testFiles.count - 1 ? 0 : self.currentIndex + 1;
    [self jumpToIndex:next];
}

- (void)chipTapped:(UIButton *)sender {
    [self jumpToIndex:sender.tag];
}

- (void)jumpToIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.testFiles.count) { return; }
    [self updateChip:self.chipButtons[(NSUInteger)self.currentIndex] selected:NO];
    self.currentIndex = index;
    [self updateChip:self.chipButtons[(NSUInteger)self.currentIndex] selected:YES];
    [self scrollChipToVisible];
    [self updateCounter];
    [self loadCurrentConfig];
}

- (void)scrollChipToVisible {
    if (self.chipButtons.count == 0) { return; }
    NSUInteger idx = (NSUInteger)MAX(0LL, (long long)self.currentIndex - 4);
    UIButton *chip = self.chipButtons[idx];
    [self.chipScrollView scrollRectToVisible:chip.frame animated:YES];
}

// ---------------------------------------------------------------------------
// MARK: - Counter / filename label
// ---------------------------------------------------------------------------

- (void)updateCounter {
    if (self.testFiles.count == 0) {
        self.counterLabel.text = @"";
        self.filenameLabel.text = @"";
        return;
    }
    self.counterLabel.text = [NSString stringWithFormat:@"%03ld / %lu",
                               (long)self.currentIndex + 1,
                               (unsigned long)self.testFiles.count];
    self.filenameLabel.text = self.testFiles[(NSUInteger)self.currentIndex];
}

// ---------------------------------------------------------------------------
// MARK: - Content loading
// ---------------------------------------------------------------------------

- (void)loadCurrentConfig {
    if (self.testFiles.count == 0) { return; }
    NSString *filename = self.testFiles[(NSUInteger)self.currentIndex];

    // Remove old display view
    [self.displayView removeFromSuperview];
    self.displayView = nil;

    NSData *data = [NDDisplayHelper loadJSONDataWithFilename:filename directory:@"TestConfigs"];
    if (!data) {
        [self showErrorLabel:[NSString stringWithFormat:@"Failed to load: %@.json", filename]];
        return;
    }

    NSError *error = nil;
    CGFloat parentWidth = self.view.bounds.size.width;
    UIView *view = [NDDisplayHelper createViewFrom:data
                                                     parentWidth:parentWidth
                                              componentListener:nil
                                                 actionListener:nil
                                                          error:&error];
    if (!view) {
        [self showErrorLabel:error.localizedDescription ?: @"Unknown error"];
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

- (void)showErrorLabel:(NSString *)message {
    UILabel *lbl = [UILabel new];
    lbl.text = message;
    lbl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    lbl.textColor = [UIColor secondaryLabelColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 0;
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentBg addSubview:lbl];
    [NSLayoutConstraint activateConstraints:@[
        [lbl.centerXAnchor constraintEqualToAnchor:self.contentBg.centerXAnchor],
        [lbl.centerYAnchor constraintEqualToAnchor:self.contentBg.centerYAnchor],
        [lbl.leadingAnchor constraintEqualToAnchor:self.contentBg.leadingAnchor constant:32],
        [lbl.trailingAnchor constraintEqualToAnchor:self.contentBg.trailingAnchor constant:-32],
    ]];
}

// ---------------------------------------------------------------------------
// MARK: - Helpers
// ---------------------------------------------------------------------------

/// Extract "NNN" from "test-NNN-some-description"
- (NSString *)extractNumber:(NSString *)filename {
    NSArray<NSString *> *parts = [filename componentsSeparatedByString:@"-"];
    if (parts.count >= 2) { return parts[1]; }
    return @"???";
}

@end
