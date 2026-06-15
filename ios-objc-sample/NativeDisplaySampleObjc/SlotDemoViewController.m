#import "SlotDemoViewController.h"
#import "NativeDisplaySampleObjc-Swift.h"
@import CleverTapSDK;
@import CleverTapNativeDisplay;
#import <objc/runtime.h>

// MARK: - AppContentCardUIView

@interface AppContentCardUIView : UIView
- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle imageUrl:(NSString *)imageUrl;
@end

static char const kAssociatedShapeLayerKey;

@implementation AppContentCardUIView {
    UIImageView *_imageView;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UIActivityIndicatorView *_spinner;
}

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle imageUrl:(NSString *)imageUrl {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // Outer shadow (self)
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.08f;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 6;
        self.layer.cornerRadius = 12;

        // Inner clip view
        UIView *clipView = [[UIView alloc] initWithFrame:CGRectZero];
        clipView.layer.cornerRadius = 12;
        clipView.clipsToBounds = YES;
        clipView.backgroundColor = [UIColor systemBackgroundColor];
        clipView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:clipView];
        [NSLayoutConstraint activateConstraints:@[
            [clipView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [clipView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [clipView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [clipView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];

        // Image view
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor systemGray5Color];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [clipView addSubview:_imageView];

        // Spinner
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [_imageView addSubview:_spinner];
        [_spinner startAnimating];

        // Title
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.text = title;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        // Subtitle
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:13];
        _subtitleLabel.textColor = [UIColor secondaryLabelColor];
        _subtitleLabel.numberOfLines = 2;
        _subtitleLabel.text = subtitle;
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _subtitleLabel]];
        textStack.axis = UILayoutConstraintAxisVertical;
        textStack.spacing = 4;
        textStack.translatesAutoresizingMaskIntoConstraints = NO;
        [clipView addSubview:textStack];

        [NSLayoutConstraint activateConstraints:@[
            [_imageView.topAnchor constraintEqualToAnchor:clipView.topAnchor],
            [_imageView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor],
            [_imageView.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor],
            [_imageView.heightAnchor constraintEqualToConstant:180],

            [_spinner.centerXAnchor constraintEqualToAnchor:_imageView.centerXAnchor],
            [_spinner.centerYAnchor constraintEqualToAnchor:_imageView.centerYAnchor],

            [textStack.topAnchor constraintEqualToAnchor:_imageView.bottomAnchor constant:12],
            [textStack.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12],
            [textStack.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor constant:-12],
            [textStack.bottomAnchor constraintEqualToAnchor:clipView.bottomAnchor constant:-12],
        ]];

        // Async image load
        NSURL *url = [NSURL URLWithString:imageUrl];
        if (url) {
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (data && !error) {
                    UIImage *image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->_imageView.image = image;
                        [self->_spinner stopAnimating];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_spinner stopAnimating];
                    });
                }
            }];
            [task resume];
        }
    }
    return self;
}

@end

// MARK: - SlotDemoViewController

@interface SlotDemoViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *feedStack;
@end

@implementation SlotDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Slot Demo";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self buildLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fetchSlotData];
}

- (void)buildLayout {
    // Outer scroll view
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_scrollView];

    UIView *guide = self.view;
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:guide.safeAreaLayoutGuide.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
    ]];

    // Outer stack (content width)
    UIStackView *outerStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    outerStack.axis = UILayoutConstraintAxisVertical;
    outerStack.spacing = 0;
    outerStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:outerStack];

    [NSLayoutConstraint activateConstraints:@[
        [outerStack.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
        [outerStack.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor],
        [outerStack.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor],
        [outerStack.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
        [outerStack.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor],
    ]];

    // Header section
    UIView *headerSection = [self buildHeaderSection];
    [outerStack addArrangedSubview:headerSection];

    // Feed stack
    _feedStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    _feedStack.axis = UILayoutConstraintAxisVertical;
    _feedStack.spacing = 12;
    _feedStack.translatesAutoresizingMaskIntoConstraints = NO;
    [outerStack addArrangedSubview:_feedStack];

    // Feed padding container
    UIEdgeInsets feedInsets = UIEdgeInsetsMake(12, 12, 12, 12);
    _feedStack.layoutMargins = feedInsets;
    _feedStack.layoutMarginsRelativeArrangement = YES;

    // Build 19 feed items
    [self buildFeedItems];
}

- (UIView *)buildHeaderSection {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Slot Demo";
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = @"This feed contains 4 NativeDisplaySlot views at fixed positions. Tap the button below to fire CleverTap events that fetch real server data for the slots.";
    descLabel.font = [UIFont systemFontOfSize:14];
    descLabel.textColor = [UIColor colorWithRed:0x66/255.0 green:0x66/255.0 blue:0x66/255.0 alpha:1];
    descLabel.numberOfLines = 0;
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *fetchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [fetchButton setTitle:@"Fetch Slot Data" forState:UIControlStateNormal];
    fetchButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    fetchButton.backgroundColor = [UIColor systemBlueColor];
    [fetchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    fetchButton.layer.cornerRadius = 8;
    fetchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [fetchButton addTarget:self action:@selector(fetchSlotData) forControlEvents:UIControlEventTouchUpInside];

    [container addSubview:titleLabel];
    [container addSubview:descLabel];
    [container addSubview:fetchButton];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
        [titleLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
        [titleLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],

        [descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [descLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
        [descLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],

        [fetchButton.topAnchor constraintEqualToAnchor:descLabel.bottomAnchor constant:12],
        [fetchButton.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
        [fetchButton.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
        [fetchButton.heightAnchor constraintEqualToConstant:44],
        [fetchButton.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12],
    ]];

    return container;
}

- (void)buildFeedItems {
    // Content items mirroring SlotDemoView.swift
    NSArray<NSDictionary *> *appItems = @[
        @{@"title": @"Morning Yoga Flow", @"subtitle": @"30 min · Beginner friendly", @"url": @"https://yavuzceliker.github.io/sample-images/image-1.jpg"},
        @{@"title": @"Mediterranean Salad", @"subtitle": @"Quick & healthy lunch recipe", @"url": @"https://yavuzceliker.github.io/sample-images/image-5.jpg"},
        @{@"title": @"Productivity Hacks", @"subtitle": @"5 tips for focused work", @"url": @"https://yavuzceliker.github.io/sample-images/image-10.jpg"},
        @{@"title": @"Trail Running Guide", @"subtitle": @"Best routes near you", @"url": @"https://yavuzceliker.github.io/sample-images/image-15.jpg"},
        @{@"title": @"Indoor Plants 101", @"subtitle": @"Low-maintenance greenery", @"url": @"https://yavuzceliker.github.io/sample-images/image-20.jpg"},
        @{@"title": @"Weekend Getaways", @"subtitle": @"Top 10 road trip destinations", @"url": @"https://yavuzceliker.github.io/sample-images/image-25.jpg"},
        @{@"title": @"Budget Meal Prep", @"subtitle": @"Save time and money", @"url": @"https://yavuzceliker.github.io/sample-images/image-30.jpg"},
        @{@"title": @"Home Workout", @"subtitle": @"No equipment needed", @"url": @"https://yavuzceliker.github.io/sample-images/image-35.jpg"},
        @{@"title": @"Coffee Brewing", @"subtitle": @"Perfect pour-over technique", @"url": @"https://yavuzceliker.github.io/sample-images/image-40.jpg"},
        @{@"title": @"Sleep Better", @"subtitle": @"Science-backed tips", @"url": @"https://yavuzceliker.github.io/sample-images/image-45.jpg"},
        @{@"title": @"Digital Detox", @"subtitle": @"Unplug and recharge", @"url": @"https://yavuzceliker.github.io/sample-images/image-50.jpg"},
        @{@"title": @"Book Club Picks", @"subtitle": @"This month's top reads", @"url": @"https://yavuzceliker.github.io/sample-images/image-55.jpg"},
        @{@"title": @"Smoothie Recipes", @"subtitle": @"Fuel your morning", @"url": @"https://yavuzceliker.github.io/sample-images/image-60.jpg"},
        @{@"title": @"Desk Stretches", @"subtitle": @"Relieve tension in 5 min", @"url": @"https://yavuzceliker.github.io/sample-images/image-65.jpg"},
        @{@"title": @"Mindful Breathing", @"subtitle": @"Calm in 3 minutes", @"url": @"https://yavuzceliker.github.io/sample-images/image-70.jpg"},
    ];

    // Index 0: slot_top
    [_feedStack addArrangedSubview:[self buildSlotPlaceholder:@"slot_top"]];
    // Index 1-3: app content 0,1,2
    for (NSInteger i = 0; i < 3; i++) {
        [_feedStack addArrangedSubview:[self buildContentCard:appItems[i]]];
    }
    // Index 4: slot_feed_1
    [_feedStack addArrangedSubview:[self buildSlotPlaceholder:@"slot_feed_1"]];
    // Index 5-7: app content 3,4,5
    for (NSInteger i = 3; i < 6; i++) {
        [_feedStack addArrangedSubview:[self buildContentCard:appItems[i]]];
    }
    // Index 8: slot_feed_2
    [_feedStack addArrangedSubview:[self buildSlotPlaceholder:@"slot_feed_2"]];
    // Index 9-17: app content 6-14
    for (NSInteger i = 6; i < 15; i++) {
        [_feedStack addArrangedSubview:[self buildContentCard:appItems[i]]];
    }
    // Index 18: slot_bottom
    [_feedStack addArrangedSubview:[self buildSlotPlaceholder:@"slot_bottom"]];
}

- (UIView *)buildSlotPlaceholder:(NSString *)slotId {
    // Create the placeholder UIView
    UIView *placeholder = [[UIView alloc] init];
    placeholder.backgroundColor = [UIColor systemGray6Color];
    placeholder.layer.cornerRadius = 10;

    // "Ad" label centered
    UILabel *adLabel = [[UILabel alloc] init];
    adLabel.text = @"Ad";
    adLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    adLabel.textColor = [UIColor systemGray2Color];
    adLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [placeholder addSubview:adLabel];
    [NSLayoutConstraint activateConstraints:@[
        [adLabel.centerXAnchor constraintEqualToAnchor:placeholder.centerXAnchor],
        [adLabel.centerYAnchor constraintEqualToAnchor:placeholder.centerYAnchor],
    ]];

    // Create slot view with placeholder using NDDisplayHelper
    UIView *slotView = [NDDisplayHelper createSlotViewWithSlotId:slotId placeholder:placeholder];
    if (slotView) {
        slotView.translatesAutoresizingMaskIntoConstraints = NO;
        // We need to store the shape layer for dashed border — done via layoutSubviews override trick.
        // Instead, use a wrapper view that draws the dashed border on layoutSubviews.
        UIView *wrapper = [self makeDashedBorderWrapper:slotView height:80];
        return wrapper;
    } else {
        // Fallback: bare placeholder
        placeholder.translatesAutoresizingMaskIntoConstraints = NO;
        [placeholder.heightAnchor constraintEqualToConstant:80].active = YES;
        return placeholder;
    }
}

- (UIView *)makeDashedBorderWrapper:(UIView *)innerView height:(CGFloat)height {
    // Wrapper that hosts the dashed CAShapeLayer border via layoutSubviews
    UIView *wrapper = [[UIView alloc] init];
    wrapper.backgroundColor = [UIColor clearColor];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;

    innerView.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:innerView];
    [NSLayoutConstraint activateConstraints:@[
        [innerView.topAnchor constraintEqualToAnchor:wrapper.topAnchor],
        [innerView.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor],
        [innerView.trailingAnchor constraintEqualToAnchor:wrapper.trailingAnchor],
        [innerView.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor],
        [wrapper.heightAnchor constraintGreaterThanOrEqualToConstant:height],
    ]];

    // Add a dashed border CAShapeLayer stored via associated object for later update in layoutSubviews
    CAShapeLayer *dashedLayer = [CAShapeLayer layer];
    dashedLayer.strokeColor = [UIColor systemGray4Color].CGColor;
    dashedLayer.fillColor = [UIColor clearColor].CGColor;
    dashedLayer.lineDashPattern = @[@6, @4];
    dashedLayer.lineWidth = 1;
    [innerView.layer addSublayer:dashedLayer];

    // Store the shape layer on the innerView using associated object
    objc_setAssociatedObject(innerView, &kAssociatedShapeLayerKey, dashedLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Observe layout changes to update the dashed border path
    // We'll update it after the layout pass via a scheduled call
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDashedBorderForView:innerView cornerRadius:10];
    });

    return wrapper;
}

- (void)updateDashedBorderForView:(UIView *)view cornerRadius:(CGFloat)radius {
    CAShapeLayer *layer = objc_getAssociatedObject(view, &kAssociatedShapeLayerKey);
    if (layer && !CGRectIsEmpty(view.bounds)) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.bounds cornerRadius:radius];
        layer.path = path.CGPath;
    }
}

- (UIView *)buildContentCard:(NSDictionary *)item {
    AppContentCardUIView *card = [[AppContentCardUIView alloc]
        initWithTitle:item[@"title"]
        subtitle:item[@"subtitle"]
        imageUrl:item[@"url"]];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    return card;
}

- (void)fetchSlotData {
    CleverTap *ct = [CleverTap sharedInstance];
    [ct recordEvent:@"asd"];
    [ct recordEvent:@"Footer5"];
    [ct recordEvent:@"Header1"];
    [ct recordEvent:@"Header2"];
    [ct recordEvent:@"Header4"];
    [ct recordEvent:@"lalit"];
}

@end
