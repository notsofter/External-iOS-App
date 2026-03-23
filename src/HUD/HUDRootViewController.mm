#import <IOKit/hid/IOHIDEventSystemClient.h>
#import <objc/runtime.h>
#import <imgui/imgui.h>
#import <imgui/imgui_internal.h>
#import <imgui/imgui_impl_metal.h>

#import "HUDRootViewController.h"

#import "../Helpers/private_headers/FBSOrientationUpdate.h"
#import "../Helpers/private_headers/FBSOrientationObserver.h"
#import "../Helpers/private_headers/LSApplicationProxy.h"
#import "../Helpers/private_headers/LSApplicationWorkspace.h"
#import "../Helpers/private_headers/SpringBoardServices.h"
#import "../Helpers/private_headers/SBSAccessibilityWindowHostingController.h"
#import "../Helpers/private_headers/UIWindow+Private.h"
#import "../Helpers/KernelManager.h"

#import "../Menu/MenuView.h"
#import "../UI/LoadingView.h"
#import "../Cheat/Cheat.h"

#define timer(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_main_queue(), ^

static void SpringBoardLockStatusChanged
(CFNotificationCenterRef center,
 void *observer,
 CFStringRef name,
 const void *object,
 CFDictionaryRef userInfo)
{
    HUDRootViewController *rootViewController = (__bridge HUDRootViewController *)observer;
    NSString *lockState = (__bridge NSString *)name;
    if ([lockState isEqualToString:@NOTIFY_UI_LOCKSTATE])
    {
        mach_port_t sbsPort = SBSSpringBoardServerPort();
        
        if (sbsPort == MACH_PORT_NULL)
            return;
        
        BOOL isLocked;
        BOOL isPasscodeSet;
        SBGetScreenLockStatus(sbsPort, &isLocked, &isPasscodeSet);

        if (!isLocked)
        {
            [rootViewController.view setHidden:NO];
        }
        else
        {
            [rootViewController.view setHidden:YES];
        }
    }
}

@implementation HUDRootViewController {
    FBSOrientationObserver *_orientationObserver;
    UIInterfaceOrientation _orientation;
    UIView *hideShowView;
    ImGuiDrawView *drawableView;
    LoadingView *loadingView;
    bool isLaunchMode;
}

#pragma mark - Orientation Methods

- (BOOL) isLandscapeOrientation
{
    BOOL isLandscape;
    if (_orientation == UIInterfaceOrientationUnknown) {
        isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    } else {
        isLandscape = UIInterfaceOrientationIsLandscape(_orientation);
    }
    return isLandscape;
}

#pragma mark - Initialization and Deallocation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
        __weak HUDRootViewController *weakSelf = self;
        [_orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
            HUDRootViewController *strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf updateOrientation:(UIInterfaceOrientation)orientationUpdate.orientation animateWithDuration:orientationUpdate.duration];
            });
        }];

        CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(
            darwinCenter,
            (__bridge const void *)self,
            SpringBoardLockStatusChanged,
            CFSTR(NOTIFY_UI_LOCKSTATE),
            NULL,
            CFNotificationSuspensionBehaviorCoalesce
        );
    }
    return self;
}

- (void)dealloc
{
    [_orientationObserver invalidate];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    Vars::qwerty = [UITextField new];
    UIView *viewity = Vars::qwerty.subviews[0];
    _contentView = viewity;
    _contentView.frame = self.view.bounds;
    _contentView.backgroundColor = [UIColor clearColor];
    [_contentView setUserInteractionEnabled:YES];
    [self.view addSubview:_contentView];

    NSString *currentLaunchModeButtonTapped = [[CustomDefaults sharedInstance] stringForKey:@"launchMode"];
    isLaunchMode = false;

    if([currentLaunchModeButtonTapped isEqualToString:@"Kernel"]) {
        loadingView = [[LoadingView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        loadingView.center = _contentView.center;
        loadingView.alpha = 0.9;
        [loadingView bs_setHitTestingDisabled:true];
        [_contentView addSubview:loadingView];

        KernelManager *kernelManager = [KernelManager new];
        kernelManager.loadingView = loadingView;
        [kernelManager doInstallWithCompletion:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    timer(2) {
                        [UIView animateWithDuration:0.3 animations:^{
                            kernelManager.loadingView.alpha = 0;
                        } completion:^(BOOL finished) {
                            if(finished) {
                                isLaunchMode = false;
                                [self setupMenu];
                                [kernelManager.loadingView removeFromSuperview];
                                kernelManager.loadingView = nil;
                            }
                        }];
                    });         
                }
            });
        }];
    } else if([currentLaunchModeButtonTapped isEqualToString:@"User"]) {
        isLaunchMode = true;
        [self setupMenu];
    }

}

-(void)setupMenu {
    [self setupButtonMenu];

    menuView = [[MenuView alloc] initWithFrame:CGRectMake(0, 0, 300, 240)];
    menuView.verticalPadding = _contentView.frame.size.height * 0.053;
    menuView.horizontalPadding = _contentView.frame.size.width * 0.02;
    menuView.center = _contentView.center;
    [_contentView addSubview:menuView];

    [menuView addPage:@"Aimbot"];
    [menuView addPage:@"Visuals"];
    [menuView addPage:@"Misc"];
    
    NSArray *aimbot_bones_items = @[@"Head", @"Neck", @"Body"];
    #define _ Vars:: 
    _ aimbot                      = [menuView addSwitchCellWithTitle:@"Aimbot" toPage:@"Aimbot"];
    _ aimbot_psilent              = [menuView addSwitchCellWithTitle:@"pSilent(Test)" toPage:@"Aimbot"];
    _ aimbot_visibility_check     = [menuView addSwitchCellWithTitle:@"Visibility check" toPage:@"Aimbot"];
    _ aimbot_scoping_check        = [menuView addSwitchCellWithTitle:@"Scoping check" toPage:@"Aimbot"];
    _ aimbot_shooting_check       = [menuView addSwitchCellWithTitle:@"Shooting check" toPage:@"Aimbot"];
    _ aimbot_untouchable_check    = [menuView addSwitchCellWithTitle:@"Untouchable check" toPage:@"Aimbot"];
    _ aimbot_recover_aimpunch     = [menuView addSwitchCellWithTitle:@"Recover aimpunch" toPage:@"Aimbot"];
    _ aimbot_draw_line_to_target  = [menuView addSwitchCellWithTitle:@"Draw line to target" toPage:@"Aimbot"];
    _ aimbot_draw_recoil_point    = [menuView addSwitchCellWithTitle:@"Draw recoil point" toPage:@"Aimbot"];
    _ aimbot_show_fov             = [menuView addSwitchCellWithTitle:@"Draw FOV" toPage:@"Aimbot"];
    _ aimbot_bone                 = [menuView addSegmentedControlCellWithTitle:@"Aimbot Bone" toPage:@"Aimbot" items:aimbot_bones_items];
    _ aimbot_fov                  = [menuView addSliderCellWithTitle:@"Aimbot FOV" toPage:@"Aimbot" minValue:0 maxValue:_contentView.frame.size.width / 2];
    _ aimbot_smooth               = [menuView addSliderCellWithTitle:@"Aimbot Smooth" toPage:@"Aimbot" minValue:0.001 maxValue:1];

    _ visuals                     = [menuView addSwitchCellWithTitle:@"Visuals" toPage:@"Visuals"];
    _ visuals_box                 = [menuView addSwitchCellWithTitle:@"Box" toPage:@"Visuals"];
    _ visuals_line                = [menuView addSwitchCellWithTitle:@"Line" toPage:@"Visuals"];
    _ visuals_skeleton            = [menuView addSwitchCellWithTitle:@"Skeleton" toPage:@"Visuals"];
    _ visuals_infobar             = [menuView addSwitchCellWithTitle:@"Info bar" toPage:@"Visuals"];
    _ visuals_weaponname          = [menuView addSwitchCellWithTitle:@"Weapon name" toPage:@"Visuals"];
    _ visuals_footsteps           = [menuView addSwitchCellWithTitle:@"Footsteps" toPage:@"Visuals"];
    _ visuals_hitinfo             = [menuView addSwitchCellWithTitle:@"Hit info" toPage:@"Visuals"];
    _ visuals_offscreen           = [menuView addSwitchCellWithTitle:@"Offscreen" toPage:@"Visuals"];
    _ visuals_offscreen_radius    = [menuView addSliderCellWithTitle:@"Offscreen radius" toPage:@"Visuals" minValue:0 maxValue:_contentView.frame.size.width / 2];
    _ visuals_offscreen_size      = [menuView addSliderCellWithTitle:@"Offscreen size" toPage:@"Visuals" minValue:10 maxValue:20];

    _ overlay_switch              = [menuView addSwitchCellWithTitle:@"Overlay" toPage:@"Misc"];
    _ misc_no_recoil              = [menuView addSwitchCellWithTitle:@"No Recoil" toPage:@"Misc"];
    _ misc_increased_firerate     = [menuView addSwitchCellWithTitle:@"Increased Firerate" toPage:@"Misc"];
    _ misc_infinity_ammo          = [menuView addSwitchCellWithTitle:@"Infinity Ammo" toPage:@"Misc"];
    _ misc_shoot_throught_walls   = [menuView addSwitchCellWithTitle:@"Shoot Throught Walls" toPage:@"Misc"];

    [menuView addButtonWithTitle:@"Load" action:^(UILabel *startLabel) {
        if(Vars::StateCheat) {
            startLabel.text = @"Load";
            Vars::StateCheat = false;

            [drawableView removeFromSuperview];
            drawableView = nil;
        } else {
            if (cheat->tryLaunch(isLaunchMode)) {
                startLabel.text = @"Unload";
                Vars::StateCheat = true;

                drawableView = [ImGuiDrawView.alloc initWithFrame:_contentView.bounds];
                drawableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [drawableView bs_setHitTestingDisabled:true];
                [_contentView addSubview:drawableView];
            }
        }
    }];

    [Vars::qwerty setSecureTextEntry:Vars::overlay_switch.isOn];
}

- (void)setupButtonMenu {
    hideShowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    hideShowView.center = _contentView.center;
    hideShowView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.001];
    [_contentView addSubview:hideShowView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handle)];
    [hideShowView addGestureRecognizer:tapGesture];
}

- (void)handle {
    [UIView animateWithDuration:0.1 animations:^{
        if (menuView.alpha == 1.0) {
            menuView.transform = CGAffineTransformMakeScale(0.5, 0.5);
            menuView.alpha = 0.0;
        } else {
            menuView.transform = CGAffineTransformIdentity;
            menuView.alpha = 1.0;
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self layoutContentView];
}

#pragma mark - Layout Methods

- (void)layoutContentView {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if ([self isLandscapeOrientation]) {
        insets = UIEdgeInsetsZero;
    } else {
        insets = UIEdgeInsetsZero;
    }
    CGRect frame = UIEdgeInsetsInsetRect(self.view.bounds, insets);
    _contentView.frame = frame;
}

static inline CGFloat orientationAngle(UIInterfaceOrientation orientation)
{
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        default:
            return 0;
    }
}

static inline CGRect orientationBounds(UIInterfaceOrientation orientation, CGRect bounds)
{
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        default:
            return bounds;
    }
}

- (void)updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration
{
    __weak typeof(self) weakSelf = self;
    if (orientation == _orientation) {
        return;
    }

    _orientation = orientation;

    CGRect bounds = orientationBounds(orientation, [UIScreen mainScreen].bounds);
    [self layoutContentView];
    [self.view setHidden:YES];
    [self.view setBounds:bounds];

    if(cheat) cheat->setScreenProperties(bounds.size.width, bounds.size.height);

    if(_contentView) _contentView.frame = self.view.bounds;

    if(hideShowView) hideShowView.center = _contentView.center;

    if(menuView) {
        menuView.verticalPadding = _contentView.frame.size.height * 0.053;
        menuView.horizontalPadding = _contentView.frame.size.width * 0.02;

        menuView.center = _contentView.center;
    }
    if (drawableView) drawableView.frame = _contentView.bounds;
    if (loadingView) loadingView.center = _contentView.center;

    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    } completion:^(BOOL finished) {
        [weakSelf.view setHidden:NO];
    }];
}

@end
