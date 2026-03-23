#import "MainMenuView.h"
#import "ViewMenu.h"
#import "SettingsViewMenu.h"
#import "CreditsViewMenu.h"

@implementation MainMenuView {
    SettingsViewMenu *settingsViewMenu;
    CreditsViewMenu *creditsViewMenu;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if(!settingsViewMenu)
        settingsViewMenu = [[SettingsViewMenu alloc] initWithStackView:self.superview];
    if(!creditsViewMenu)
        creditsViewMenu = [[CreditsViewMenu alloc] initWithStackView:self.superview];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    self.layer.cornerRadius = 15.0;
    self.layer.masksToBounds = YES;
    
    NSArray *buttonTitles = @[@"Settings", @"Credits"];
    NSArray *buttonImages = @[@"gear", @""];
    
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSMutableArray<UIView *> *lines = [NSMutableArray array];
    
    for (NSInteger i = 0; i < buttonTitles.count; i++) {
        UIButton *button = [self createButtonWithTitle:buttonTitles[i] imageName:buttonImages[i] selector:@selector(buttonTapped:)];
        [buttons addObject:button];
        [self addSubview:button];
        
        if (i < buttonTitles.count - 1) {
            UIView *separatorLine = [[UIView alloc] init];
            separatorLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
            separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
            [lines addObject:separatorLine];
            [self addSubview:separatorLine];
        }
    }
    
    for (NSInteger i = 0; i < buttons.count; i++) {
        UIButton *button = buttons[i];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (i == 0) {
            [NSLayoutConstraint activateConstraints:@[
                [button.topAnchor constraintEqualToAnchor:self.topAnchor constant:20],
                [button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
                [button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
                [button.heightAnchor constraintEqualToConstant:44]
            ]];
        } else {
            UIButton *previousButton = buttons[i - 1];
            UIView *line = lines[i - 1];
            [NSLayoutConstraint activateConstraints:@[
                [line.topAnchor constraintEqualToAnchor:previousButton.bottomAnchor constant:10],
                [line.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
                [line.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
                [line.heightAnchor constraintEqualToConstant:1]
            ]];
            [NSLayoutConstraint activateConstraints:@[
                [button.topAnchor constraintEqualToAnchor:line.bottomAnchor constant:10],
                [button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
                [button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
                [button.heightAnchor constraintEqualToConstant:44]
            ]];
        }
    }
    
    UIButton *lastButton = buttons.lastObject;
    [NSLayoutConstraint activateConstraints:@[
        [lastButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-20]
    ]];
}

- (UIButton *)createButtonWithTitle:(NSString *)title imageName:(NSString *)imageName selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"greaterthan"]];
    [arrowImageView setTintColor:[[UIColor whiteColor] colorWithAlphaComponent:0.2]];
    arrowImageView.userInteractionEnabled = NO;
    arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [button addSubview:arrowImageView];

    [NSLayoutConstraint activateConstraints:@[
        [arrowImageView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [arrowImageView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-10],
        [arrowImageView.widthAnchor constraintEqualToConstant:15],
        [arrowImageView.heightAnchor constraintEqualToConstant:30]
    ]];

    if (imageName.length != 0) {
        [button setImage:[UIImage systemImageNamed:imageName] forState:UIControlStateNormal];
        [button setTintColor:[UIColor whiteColor]];
        
        [button setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];

        [button.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [button.titleLabel.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
        ]];
    }
    return button;
}

- (void)buttonTapped:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"Settings"]) {
        [settingsViewMenu showViewMenu];
    } else if ([sender.titleLabel.text isEqualToString:@"Credits"]) {
        [creditsViewMenu showViewMenu];
    }
}

@end
