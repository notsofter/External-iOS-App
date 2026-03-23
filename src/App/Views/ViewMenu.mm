#import "ViewMenu.h"

@implementation ViewMenu {
    UIVisualEffectView *blurEffectView;
    UIView *fromView;
    UIScrollView *scrollView;
    UIStackView *headerStackView;
    UIView *containerView;
}

- (id)initWithView:(UIView *)view {
    containerView = UIApplication.sharedApplication.keyWindow.rootViewController.view;

    self = [super initWithFrame:CGRectMake(0, 0,
                                           containerView.bounds.size.width * 0.75,
                                           containerView.bounds.size.height * 0.5)];
    if (self) {
        fromView = view;
        
        self.alpha = 0;
        self.layer.cornerRadius = 15;
        self.center = containerView.center;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        [blurEffectView setFrame:containerView.bounds];
        blurEffectView.alpha = 0;
        blurEffectView.userInteractionEnabled = YES;

        self.notificationView = [[ഘഫഭറളഠഠഔഉഘഢധഏഊഷഠഞഒഛഖ alloc]
                                  initWithSize:CGSizeMake(containerView.bounds.size.width * 0.75, 30)];
        self.notificationView.layer.cornerRadius = 10;
        [blurEffectView.contentView addSubview:self.notificationView];

        UITapGestureRecognizer *tapHideViewMenu = [[UITapGestureRecognizer alloc]
                                                   initWithTarget:self
                                                   action:@selector(removeViewMenu)];
        [blurEffectView addGestureRecognizer:tapHideViewMenu];

        [containerView addSubview:blurEffectView];
        [containerView addSubview:self];

        [self setupScrollView];
    }
    return self;
}

#pragma mark - ScrollView Setup

- (void)setupScrollView {
    scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:scrollView];
    
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

#pragma mark - UI Setup

- (void)setupUI {
    self.mainStackView = [[UIStackView alloc] init];
    self.mainStackView.axis = UILayoutConstraintAxisVertical;
    self.mainStackView.spacing = 15;
    self.mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    headerStackView = [[UIStackView alloc] init];
    headerStackView.axis = UILayoutConstraintAxisVertical;
    headerStackView.alignment = UIStackViewAlignmentFill;
    headerStackView.spacing = 15;
    headerStackView.translatesAutoresizingMaskIntoConstraints = NO;

    [scrollView addSubview:headerStackView];
    [scrollView addSubview:self.mainStackView];

    [NSLayoutConstraint activateConstraints:@[
        [headerStackView.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:15],
        [headerStackView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:24],
        [headerStackView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor constant:-24],
        [self.mainStackView.topAnchor constraintEqualToAnchor:headerStackView.bottomAnchor constant:25],
        [self.mainStackView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:24],
        [self.mainStackView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor constant:-24],
        [self.mainStackView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-24],
        [self.mainStackView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-48]
    ]];

    [self setupHeaderSection];
}

#pragma mark - Header Section with Divider

- (void)setupHeaderSection {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = self.title;
    titleLabel.font = [UIFont systemFontOfSize:18];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    
    [headerStackView addArrangedSubview:titleLabel];
    [headerStackView addArrangedSubview:divider];
    
    [divider.heightAnchor constraintEqualToConstant:1].active = YES;
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35];
    button.layer.cornerRadius = 8;

    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - Blur handling

- (void)showBlurEffectView {
    [UIView animateWithDuration:0.2 animations:^{
        blurEffectView.alpha = 1;
    }];
}

- (void)removeBlurEffectView {
    [UIView animateWithDuration:0.2 animations:^{
        blurEffectView.alpha = 0;
    }];
}

- (void)showViewMenu {
    [self showBlurEffectView];
        
    self.alpha = 0;
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7, 0.7);
        
    if (fromView) {
        fromView.transform = CGAffineTransformIdentity;
    }

    [UIView animateWithDuration:0.6
                          delay:0.0
         usingSpringWithDamping:0.9
          initialSpringVelocity:2.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
            
        if (fromView) {
            fromView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7, 0.7); // Zoom out
        }
    } completion:nil];
}

- (void)removeViewMenu {
    [self removeBlurEffectView];

    [UIView animateWithDuration:0.6
                          delay:0.0
         usingSpringWithDamping:0.9
          initialSpringVelocity:2.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1); // Zoom out
        self.alpha = 0;

        fromView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setInteractableBlurView:(BOOL)arg {
    blurEffectView.userInteractionEnabled = arg;
}

@end
