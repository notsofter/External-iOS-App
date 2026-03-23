#import "MainViewController.h"
#import "Views/MainMenuView.h"
#import "Views/UpdateInfoMenu.h"
#import "../Helpers/HUDHelper.h"
#import "../Helpers/Device.h"
#import "jbdetect.h"

@interface MainViewController ()

@property (nonatomic, strong) MainMenuView *mainMenuView;
@property (nonatomic, strong) UIButton *runButton;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *brandLabel;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation MainViewController {
    UpdateInfoMenu *updateInfoMenu;
}

static const CGFloat kBackgroundParallaxRange = 35.0f;

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (!updateInfoMenu) {
        updateInfoMenu = [[UpdateInfoMenu alloc] initWithStackView:self.stackView];
        [self displayChangelogIfAvailable];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupSnowEmitter];
    
    if (self.isRunning) {
        return;
    }
    
    int jailbreakResult = detect_jailbreak();
    if (jailbreakResult) {
        self.view.userInteractionEnabled = NO;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning!"
                                                                       message:@"Traces of a jailbreak have been detected on your device!\nContinuing to play may result in a ban!\nClean your device and try again."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"OK"
                                                             style:UIAlertActionStyleDestructive
                                                           handler:^(UIAlertAction * _Nonnull action) {
            exit(0);
        }];
        
        [alert addAction:exitAction];
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
}

- (void)setupUI {
    self.isRunning = IsHUDEnabled();
    
    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGRect backgroundFrame = CGRectInset(self.view.bounds, -kBackgroundParallaxRange, -kBackgroundParallaxRange);
    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:backgroundFrame];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (isPad) {
        bgImageView.image = [UIImage imageNamed:@"ipa.png"];
    } else {
        bgImageView.image = [UIImage imageNamed:@"iph.png"];
    }
    [self.view addSubview:bgImageView];
    [self.view sendSubviewToBack:bgImageView];
    [self applyParallaxToView:bgImageView];
    
    self.brandLabel = [[UILabel alloc] init];
    self.brandLabel.numberOfLines = 0;
    self.brandLabel.textAlignment = NSTextAlignmentCenter;
    self.brandLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSString *brandText = @"nsftr";
    NSString *tgText = @"t.me/<nil>";
    NSString *trollstoreText = @"TrollStore";
    NSString *fullText = [NSString stringWithFormat:@"%@\n%@\n%@", brandText, tgText, trollstoreText];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:fullText];
    [attributedText addAttribute:NSFontAttributeName
                           value:[UIFont boldSystemFontOfSize:36]
                           range:NSMakeRange(0, brandText.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName
                           value:[UIColor whiteColor]
                           range:NSMakeRange(0, brandText.length)];
    
    NSUInteger tgTextStartIndex = brandText.length + 1;
    [attributedText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:18]
                           range:NSMakeRange(tgTextStartIndex, tgText.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName
                           value:[[UIColor whiteColor] colorWithAlphaComponent:0.6]
                           range:NSMakeRange(tgTextStartIndex, tgText.length)];
    
    NSUInteger trollstoreTextStartIndex = tgTextStartIndex + tgText.length + 1;
    [attributedText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:18]
                           range:NSMakeRange(trollstoreTextStartIndex, trollstoreText.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName
                           value:[[UIColor whiteColor] colorWithAlphaComponent:0.6]
                           range:NSMakeRange(trollstoreTextStartIndex, trollstoreText.length)];
    
    self.brandLabel.attributedText = attributedText;
    
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.layer.shadowColor = [UIColor whiteColor].CGColor;
    backgroundView.layer.shadowOffset = CGSizeMake(0, 4);
    backgroundView.layer.shadowOpacity = 0.7;
    backgroundView.layer.shadowRadius = 8.0;
    
    self.iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.layer.masksToBounds = YES;
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.mainMenuView = [[MainMenuView alloc] initWithFrame:CGRectZero];
    self.mainMenuView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.runButton = [self createButtonWithTitle:(self.isRunning ? @"Exit" : @"Run")
                                         selector:@selector(runButtonTapped)];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.runButton addSubview:self.activityIndicator];
    
    self.stackView = [[UIStackView alloc] initWithArrangedSubviews:@[backgroundView,
                                                                     self.brandLabel,
                                                                     self.mainMenuView,
                                                                     self.runButton]];
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    self.stackView.spacing = 20;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.stackView];
    [backgroundView addSubview:self.iconImageView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        
        [backgroundView.heightAnchor constraintEqualToConstant:100],
        [backgroundView.widthAnchor constraintEqualToConstant:100],
        
        [self.iconImageView.centerXAnchor constraintEqualToAnchor:backgroundView.centerXAnchor],
        [self.iconImageView.centerYAnchor constraintEqualToAnchor:backgroundView.centerYAnchor],
        [self.iconImageView.heightAnchor constraintEqualToConstant:150],
        [self.iconImageView.widthAnchor constraintEqualToConstant:150],
        
        [self.mainMenuView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.7],
        
        [self.runButton.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.5],
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.runButton.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.runButton.centerYAnchor]
    ]];
}

- (void)applyParallaxToView:(UIView *)view {
    if (UIAccessibilityIsReduceMotionEnabled()) {
        return;
    }
    
    UIInterpolatingMotionEffect *horizontalEffect =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                        type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kBackgroundParallaxRange);
    horizontalEffect.maximumRelativeValue = @(kBackgroundParallaxRange);
    
    UIInterpolatingMotionEffect *verticalEffect =
        [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                        type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kBackgroundParallaxRange);
    verticalEffect.maximumRelativeValue = @(kBackgroundParallaxRange);
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[horizontalEffect, verticalEffect];
    [view addMotionEffect:group];
}

- (UIButton *)createButtonWithTitle:(NSString *)title selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:20];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)runButtonTapped {
    if (!self.isRunning) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning!"
                                                                       message:@"By pressing the notification button below, you acknowledge the consequences and agree that you bear full responsibility."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK, I agree"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
            [self toggleHUD];
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"-"]];
        }];
        [alert addAction:okAction];
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    } else {
        [self toggleHUD];
    }
}

- (void)toggleHUD {
    [self.activityIndicator startAnimating];
    
    self.isRunning = !self.isRunning;
    SetHUDEnabled(self.isRunning);
    self.runButton.userInteractionEnabled = NO;
    [self.runButton setTitle:@"" forState:UIControlStateNormal];
    
    waitForNotification(^{
        [self.runButton setTitle:self.isRunning ? @"Exit" : @"Run" forState:UIControlStateNormal];
        self.runButton.userInteractionEnabled = YES;
        [self.activityIndicator stopAnimating];
    }, self.isRunning);
}

- (void)setupSnowEmitter {
    CAEmitterLayer *emitterLayer = [CAEmitterLayer layer];
    emitterLayer.emitterPosition = CGPointMake(self.view.bounds.size.width / 2.0, -20);
    emitterLayer.emitterSize = CGSizeMake(self.view.bounds.size.width, 1);
    emitterLayer.emitterShape = kCAEmitterLayerLine;
    emitterLayer.emitterMode = kCAEmitterLayerSurface;
    
    UIImage *snowflakeImage = [self createSnowflakeImage];
    
    CAEmitterCell *smallFlake = [CAEmitterCell emitterCell];
    smallFlake.contents = (id)snowflakeImage.CGImage;
    smallFlake.birthRate = 5.0;
    smallFlake.lifetime = 18.0;
    smallFlake.velocity = 35;
    smallFlake.velocityRange = 20;
    smallFlake.yAcceleration = 8;
    smallFlake.xAcceleration = -5;
    smallFlake.emissionLongitude = M_PI_2;
    smallFlake.emissionRange = M_PI_4;
    smallFlake.scale = 0.12;
    smallFlake.scaleRange = 0.06;
    smallFlake.alphaRange = 0.3;
    smallFlake.alphaSpeed = -0.015;
    
    CAEmitterCell *largeFlake = [CAEmitterCell emitterCell];
    largeFlake.contents = (id)snowflakeImage.CGImage;
    largeFlake.birthRate = 2.0;
    largeFlake.lifetime = 16.0;
    largeFlake.velocity = 25;
    largeFlake.velocityRange = 15;
    largeFlake.yAcceleration = 6;
    largeFlake.xAcceleration = -3;
    largeFlake.emissionLongitude = M_PI_2;
    largeFlake.emissionRange = M_PI_4;
    largeFlake.scale = 0.22;
    largeFlake.scaleRange = 0.1;
    largeFlake.alphaRange = 0.2;
    largeFlake.alphaSpeed = -0.01;
    
    emitterLayer.emitterCells = @[smallFlake, largeFlake];
    
    [self.view.layer insertSublayer:emitterLayer below:self.stackView.layer];
}

- (UIImage *)createSnowflakeImage {
    CGSize size = CGSizeMake(24, 24);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGPoint center = CGPointMake(size.width / 2.0, size.height / 2.0);
    CGFloat radius = size.width / 2.0;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.98f, 0.99f, 1.00f, 0.9f,
        0.85f, 0.92f, 1.00f, 0.0f
    };
    CGFloat locations[] = {0.0f, 1.0f};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, 2);
    CGContextDrawRadialGradient(context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *snowflakeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snowflakeImage;
}

- (void)displayChangelogIfAvailable {
    NSString *docsPath = [Device getDocumentsApp];
    NSString *changelogPath = [docsPath stringByAppendingPathComponent:@"changelog.txt"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:changelogPath]) {
        NSError *readError = nil;
        NSString *changelogContent = [NSString stringWithContentsOfFile:changelogPath
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&readError];
        
        if (changelogContent && !readError) {
            NSLog(@"Changelog найден:\n%@", changelogContent);
            
            timer(1) {
                [updateInfoMenu showViewMenu];
                [updateInfoMenu setChangelogText:changelogContent];
                
                [fileManager removeItemAtPath:changelogPath error:nil];
            });
        } else {
            NSLog(@"Ошибка при чтении changelog: %@", readError.localizedDescription);
        }
    } else {
        NSLog(@"Файл changelog.txt не найден.");
    }
}

@end
