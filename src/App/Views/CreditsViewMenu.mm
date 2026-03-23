#import "CreditsViewMenu.h"

@interface CreditsViewMenu ()
@end

@implementation CreditsViewMenu

-(id)initWithStackView:(UIStackView *)stackView {
    self = [super initWithView:stackView];
    if (self) {
        self.title = @"Credits";

        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    [self setupDonateSection];
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.numberOfLines = 0;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - Donate Section

- (void)setupDonateSection {
    UILabel *sectionLabel = [[UILabel alloc] init];
    sectionLabel.numberOfLines = 0;
    [self.mainStackView addArrangedSubview:sectionLabel];

    sectionLabel.text = [NSString stringWithFormat:@"You can support the currently free project with cryptocurrency using this data.\nTap on the address to copy"];

    UIStackView *buttonStackView = [[UIStackView alloc] init];
    buttonStackView.axis = UILayoutConstraintAxisVertical;
    buttonStackView.spacing = 15;
    buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.mainStackView addArrangedSubview:buttonStackView];

	[self addCryptoButtonWithTitle:@"BTC" address:@"bc1qcuftvrz8hvv8er9w0kj4zq33gxnw3yq9l0eqa8" toStackView:buttonStackView];
	[self addCryptoButtonWithTitle:@"ETH" address:@"0xfFd227a8dbFE5EB32A2503CabC9620237c5a62DA" toStackView:buttonStackView];
	[self addCryptoButtonWithTitle:@"BNB" address:@"0xfFd227a8dbFE5EB32A2503CabC9620237c5a62DA" toStackView:buttonStackView];
    [self addCryptoButtonWithTitle:@"USDT TRC20" address:@"TWuqhr8xH4Jg6sWYktjzqtADgFQVZrW98p" toStackView:buttonStackView];
    [self addCryptoButtonWithTitle:@"TON" address:@"EQAzw-r7_eTwEZZAJI0DkJGjhcOb1OFsfCJ21cviZ-RaONgs" toStackView:buttonStackView];
    [self addCryptoButtonWithTitle:@"GitHub repo" address:@"ns" toStackView:buttonStackView];
}

- (void)addCryptoButtonWithTitle:(NSString *)cryptoTitle address:(NSString *)address toStackView:(UIStackView *)stackView {
    NSString *buttonTitle = [NSString stringWithFormat:@"%@\n%@", cryptoTitle, address];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:buttonTitle];
    
    [attributedText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:12]
                           range:NSMakeRange(0, cryptoTitle.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName
                           value:[UIColor whiteColor]
                           range:NSMakeRange(0, cryptoTitle.length)];
    
    [attributedText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:12]
                           range:NSMakeRange(cryptoTitle.length + 1, address.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName
                           value:[[UIColor whiteColor] colorWithAlphaComponent:0.6]
                           range:NSMakeRange(cryptoTitle.length + 1, address.length)];

    UIButton *button = [self createButtonWithTitle:nil action:@selector(copyAddressToClipboard:)];
    button.backgroundColor = [UIColor clearColor];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
    [button setAttributedTitle:attributedText forState:UIControlStateNormal];
    button.accessibilityLabel = address;
    [stackView addArrangedSubview:button];
}

#pragma mark - Copy Address

- (void)copyAddressToClipboard:(UIButton *)sender {
    if ([sender.titleLabel.text hasPrefix:@"GitHub repo"]) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://github.com/notsofter/External-iOS-App"]];
    } else {
        NSString *address = sender.accessibilityLabel;
        if (address) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = address;

            [self highlightButton:sender];
            self.notificationView.textLabel.text = @"Copied";
            [self.notificationView start];
        }
    }
}

#pragma mark - Button Highlighting

- (void)highlightButton:(UIButton *)button {
    [UIView animateWithDuration:0.1 animations:^{
        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            button.backgroundColor = [UIColor clearColor];
        }];
    }];
}

@end
