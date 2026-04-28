//
//  JSONViewerViewController.m
//  NativeDisplaySampleObjc
//
//  Displays JSON text in a monospace dark-themed text view with Copy button.
//

#import "JSONViewerViewController.h"

@interface JSONViewerViewController ()

@property (nonatomic, copy) NSString *jsonString;
@property (nonatomic, copy) NSString *viewerTitle;

@end

@implementation JSONViewerViewController

// ---------------------------------------------------------------------------
// MARK: - Init
// ---------------------------------------------------------------------------

- (instancetype)initWithJSONString:(NSString *)jsonString title:(NSString *)title {
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    _jsonString   = [jsonString copy];
    _viewerTitle  = [title copy];
    return self;
}

// ---------------------------------------------------------------------------
// MARK: - Lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.viewerTitle;
    [self setupLayout];
}

// ---------------------------------------------------------------------------
// MARK: - Setup
// ---------------------------------------------------------------------------

- (void)setupLayout {
    UIColor *darkBg   = [UIColor colorWithRed:0.118 green:0.118 blue:0.118 alpha:1.0]; // #1E1E1E
    UIColor *lightFg  = [UIColor colorWithRed:0.831 green:0.831 blue:0.831 alpha:1.0]; // #D4D4D4

    self.view.backgroundColor = darkBg;

    // ── JSON text view ─────────────────────────────────────────────
    UITextView *textView = [UITextView new];
    textView.text = self.jsonString;
    textView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    textView.textColor = lightFg;
    textView.backgroundColor = darkBg;
    textView.editable = NO;
    textView.showsVerticalScrollIndicator = YES;
    textView.showsHorizontalScrollIndicator = YES;
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    // Allow horizontal scrolling
    textView.textContainer.lineBreakMode = NSLineBreakByClipping;
    textView.textContainer.widthTracksTextView = NO;
    textView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16);

    // ── Divider ────────────────────────────────────────────────────
    UIView *divider = [UIView new];
    divider.backgroundColor = [UIColor separatorColor];
    divider.translatesAutoresizingMaskIntoConstraints = NO;

    // ── Copy button ────────────────────────────────────────────────
    UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    copyBtn.backgroundColor = [UIColor systemBlueColor];
    [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    copyBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    copyBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [copyBtn addTarget:self action:@selector(copyToClipboard) forControlEvents:UIControlEventTouchUpInside];

    // Icon + label
    UIImageView *docIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"doc.on.doc.fill"]];
    docIcon.tintColor = [UIColor whiteColor];
    docIcon.translatesAutoresizingMaskIntoConstraints = NO;
    docIcon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *copyLabel = [UILabel new];
    copyLabel.text = @"Copy to Clipboard";
    copyLabel.textColor = [UIColor whiteColor];
    copyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    copyLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *btnContent = [[UIStackView alloc] initWithArrangedSubviews:@[docIcon, copyLabel]];
    btnContent.axis = UILayoutConstraintAxisHorizontal;
    btnContent.spacing = 8;
    btnContent.alignment = UIStackViewAlignmentCenter;
    btnContent.userInteractionEnabled = NO;
    btnContent.translatesAutoresizingMaskIntoConstraints = NO;

    [copyBtn addSubview:btnContent];
    [NSLayoutConstraint activateConstraints:@[
        [btnContent.centerXAnchor constraintEqualToAnchor:copyBtn.centerXAnchor],
        [btnContent.centerYAnchor constraintEqualToAnchor:copyBtn.centerYAnchor],
        [docIcon.widthAnchor constraintEqualToConstant:20],
        [docIcon.heightAnchor constraintEqualToConstant:20],
    ]];

    // ── Assemble ───────────────────────────────────────────────────
    [self.view addSubview:textView];
    [self.view addSubview:divider];
    [self.view addSubview:copyBtn];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [divider.topAnchor constraintEqualToAnchor:textView.bottomAnchor],
        [divider.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],

        [copyBtn.topAnchor constraintEqualToAnchor:divider.bottomAnchor],
        [copyBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [copyBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [copyBtn.heightAnchor constraintEqualToConstant:56],
        [copyBtn.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

// ---------------------------------------------------------------------------
// MARK: - Actions
// ---------------------------------------------------------------------------

- (void)copyToClipboard {
    [UIPasteboard generalPasteboard].string = self.jsonString;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Copied!"
                                                                   message:@"JSON has been copied to clipboard"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
