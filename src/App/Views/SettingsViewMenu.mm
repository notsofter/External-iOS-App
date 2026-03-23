#import "SettingsViewMenu.h"
#import "../../Helpers/Device.h"
#import "../../Helpers/Exploit.h"
#import "../../Helpers/CustomDefaults.h"

@interface SettingsViewMenu ()
@property (nonatomic, strong) UIStackView *kernelStackView;
@property (nonatomic, strong) Device *device;
@property (nonatomic, assign) BOOL isKernelSectionVisible;
@end

@implementation SettingsViewMenu

- (id)initWithStackView:(UIStackView *)stackView {
    self = [super initWithView:stackView];
    if (self) {
        self.title = @"Settings";
        self.device = [[Device alloc] init];

        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    [self setupLaunchModeSection];
}

#pragma mark - Launch Mode Section

- (void)setupLaunchModeSection {
    UILabel *sectionLabel = [[UILabel alloc] init];
    sectionLabel.text = @"Launch mode";
    sectionLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];

    UIStackView *settingsStackView = [[UIStackView alloc] init];
    settingsStackView.axis = UILayoutConstraintAxisHorizontal;
    settingsStackView.alignment = UIStackViewAlignmentFill;
    settingsStackView.distribution = UIStackViewDistributionFillEqually;
    settingsStackView.spacing = 10;
    settingsStackView.translatesAutoresizingMaskIntoConstraints = NO;

    if ([self.device supportsDirectInstall]) {
        UIButton *kernelButton = [self createButtonWithTitle:@"Kernel" action:@selector(launchModeButtonTapped:)];
        UIButton *userButton = [self createButtonWithTitle:@"User" action:@selector(launchModeButtonTapped:)];

        [settingsStackView addArrangedSubview:kernelButton];
        [settingsStackView addArrangedSubview:userButton];
        [self.mainStackView addArrangedSubview:sectionLabel];
        [self.mainStackView addArrangedSubview:settingsStackView];

        NSString *currentLaunchModeButtonTapped = [[CustomDefaults sharedInstance] stringForKey:@"launchMode"];

        if([currentLaunchModeButtonTapped isEqualToString:@"Kernel"]) {
            [self launchModeButtonTapped:kernelButton];
        } else if([currentLaunchModeButtonTapped isEqualToString:@"User"]) {
            [self launchModeButtonTapped:userButton];
        } else {
            [self launchModeButtonTapped:kernelButton];
        }
    } else {
        UIButton *userButton = [self createButtonWithTitle:@"User" action:@selector(launchModeButtonTapped:)];
        [settingsStackView addArrangedSubview:userButton];
        [self.mainStackView addArrangedSubview:sectionLabel];
        [self.mainStackView addArrangedSubview:settingsStackView];

        [self launchModeButtonTapped:userButton];
    }
}

#pragma mark - Kernel Section Setup

- (void)setupKernelSection {
    if (!self.kernelStackView) {
        self.kernelStackView = [[UIStackView alloc] init];
        self.kernelStackView.axis = UILayoutConstraintAxisVertical;
        self.kernelStackView.spacing = 14;
        self.kernelStackView.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *selectMethodStackView = [[UIStackView alloc] init];
        selectMethodStackView.axis = UILayoutConstraintAxisVertical;
        selectMethodStackView.spacing = 10;
        selectMethodStackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.kernelStackView addArrangedSubview:selectMethodStackView];

        UILabel *kernelSelectMethodLabel = [[UILabel alloc] init];
        kernelSelectMethodLabel.text = @"Select method";
        kernelSelectMethodLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
        [selectMethodStackView addArrangedSubview:kernelSelectMethodLabel];

        UIStackView *buttonStackView = [[UIStackView alloc] init];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            buttonStackView.axis = UILayoutConstraintAxisHorizontal;
            buttonStackView.distribution = UIStackViewDistributionFillEqually;
        } else {
            buttonStackView.axis = UILayoutConstraintAxisVertical;
        }
        buttonStackView.spacing = 10;
        buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
        [selectMethodStackView addArrangedSubview:buttonStackView];

        if ([smith supportsDevice:self.device] || [physpuppet supportsDevice:self.device]) {
            UIButton *landaButton = [self createButtonWithTitle:@"landa" action:@selector(methodButtonTapped:)];
            UIButton *smithButton = [self createButtonWithTitle:@"smith" action:@selector(methodButtonTapped:)];
            UIButton *physpuppetButton = [self createButtonWithTitle:@"physpuppet" action:@selector(methodButtonTapped:)];

            [buttonStackView addArrangedSubview:landaButton];
            if ([smith supportsDevice:self.device]) {
                [buttonStackView addArrangedSubview:smithButton];
            }
            if ([physpuppet supportsDevice:self.device]) {
                [buttonStackView addArrangedSubview:physpuppetButton];
            }

            NSString *currentMethodButtonTapped = [[CustomDefaults sharedInstance] stringForKey:@"method"];
            if([currentMethodButtonTapped isEqualToString:@"landa"]) {
                [self methodButtonTapped:landaButton];
            } else if([currentMethodButtonTapped isEqualToString:@"smith"]) {
                [self methodButtonTapped:smithButton];
            } else if([currentMethodButtonTapped isEqualToString:@"physpuppet"]) {
                [self methodButtonTapped:physpuppetButton];
            } else {
                if ([landa supportsDevice:self.device]) {
                    [self methodButtonTapped:landaButton];
                } else if ([smith supportsDevice:self.device]) {
                    [self methodButtonTapped:smithButton];
                } else if ([physpuppet supportsDevice:self.device]) {
                    [self methodButtonTapped:physpuppetButton];
                }
            }
        }

        UIStackView *actionsStackView = [[UIStackView alloc] init];
        actionsStackView.axis = UILayoutConstraintAxisVertical;
        actionsStackView.spacing = 10;
        actionsStackView.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *kernelActions = [[UILabel alloc] init];
        kernelActions.text = @"Actions";
        kernelActions.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
        [actionsStackView addArrangedSubview:kernelActions];

        UIButton *clearCacheButton = [self createButtonWithTitle:@"Clear app cache" action:@selector(clearCache:)];
        clearCacheButton.backgroundColor = [UIColor whiteColor];
        [actionsStackView addArrangedSubview:clearCacheButton];
        [self.kernelStackView addArrangedSubview:actionsStackView];

        [self.mainStackView addArrangedSubview:self.kernelStackView];
        self.isKernelSectionVisible = YES;
    }
}

#pragma mark - Button Actions

- (void)launchModeButtonTapped:(UIButton *)sender {
    NSString *buttonTitle = sender.titleLabel.text;
    [[CustomDefaults sharedInstance] saveString:buttonTitle forKey:@"launchMode"];

    [self toggleButton:sender];
    if ([buttonTitle isEqualToString:@"Kernel"]) {
        if (!self.isKernelSectionVisible) {
            [self setupKernelSection];
        }
    } else if ([buttonTitle isEqualToString:@"User"]) {
        if (self.isKernelSectionVisible) {
            [self.kernelStackView removeFromSuperview];
            self.kernelStackView = nil;
            self.isKernelSectionVisible = NO;
        }
    }
}

- (void)methodButtonTapped:(UIButton *)sender {
    [self toggleButton:sender];

    NSString *buttonTitle = sender.titleLabel.text;
    [[CustomDefaults sharedInstance] saveString:buttonTitle forKey:@"method"];
}

- (void)clearCache:(UIButton *)sender {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[[Device getDocumentsApp] stringByAppendingPathComponent:@"cache"] error:&error];
    if (!error) {
        self.notificationView.textLabel.text = @"Clear app cache success";
        [self.notificationView start];
    } else {
        self.notificationView.textLabel.text = error.localizedDescription;
        [self.notificationView start];
    }
}

- (void)toggleButton:(UIButton *)sender {
    [self setButtonSelected:sender];
}

- (void)setButtonSelected:(UIButton *)button {
    UIStackView *parentStackView = (UIStackView *)button.superview;
    for (UIButton *subButton in parentStackView.arrangedSubviews) {
        if ([subButton isKindOfClass:[UIButton class]]) {
            subButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35];
        }
    }
    button.backgroundColor = [UIColor whiteColor];
}

@end
