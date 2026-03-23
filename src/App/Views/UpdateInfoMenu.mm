#import "UpdateInfoMenu.h"

@interface UpdateInfoMenu ()

@property (nonatomic, strong) UITextView *changelogTextView;

@end

@implementation UpdateInfoMenu

- (instancetype)initWithStackView:(UIStackView *)stackView {
    self = [super initWithView:stackView];
    if (self) {
        self.title = @"Changelog";
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    [self setupChangelogSection];
}

#pragma mark - Changelog Section with UITextView

- (void)setupChangelogSection {
    UIView *changelogContainer = [[UIView alloc] init];
    changelogContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.changelogTextView = [[UITextView alloc] init];
    self.changelogTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.changelogTextView.font = [UIFont systemFontOfSize:14];
    self.changelogTextView.textColor = [UIColor whiteColor];
    self.changelogTextView.backgroundColor = [UIColor clearColor];
    self.changelogTextView.editable = NO;
    self.changelogTextView.scrollEnabled = NO;
    self.changelogTextView.selectable = YES;
    self.changelogTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    
    self.changelogTextView.textContainerInset = UIEdgeInsetsZero;
    self.changelogTextView.textContainer.lineFragmentPadding = 0;
    
    [changelogContainer addSubview:self.changelogTextView];
    
    [self.mainStackView addArrangedSubview:changelogContainer];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.changelogTextView.topAnchor constraintEqualToAnchor:changelogContainer.topAnchor],
        [self.changelogTextView.leadingAnchor constraintEqualToAnchor:changelogContainer.leadingAnchor],
        [self.changelogTextView.trailingAnchor constraintEqualToAnchor:changelogContainer.trailingAnchor],
        [self.changelogTextView.bottomAnchor constraintEqualToAnchor:changelogContainer.bottomAnchor],
        [self.changelogTextView.heightAnchor constraintGreaterThanOrEqualToConstant:100]
    ]];
}

#pragma mark - Public Method to Set Changelog Text

- (void)setChangelogText:(NSString *)text {
    if (self.changelogTextView) {
        self.changelogTextView.text = text;
    }
}

@end
