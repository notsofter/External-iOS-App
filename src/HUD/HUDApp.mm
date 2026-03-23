#import <notify.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>

#import "../Helpers/HUDHelper.h"

#import "../Helpers/ts/Events.h"
#import "../Helpers/private_headers/AXEventRepresentation.h"
#import "../Helpers/private_headers/BackboardServices.h"
#import "../Helpers/private_headers/UIApplication+Private.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/hid/IOHIDService.h>

static __used
void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event)
{

    static UIApplication *app = [UIApplication sharedApplication];
    
    if (@available(iOS 15.1, *)) {}
    else {
        [app _enqueueHIDEvent:event];
    }

    BOOL shouldUseAXEvent = YES;  // Always use AX events now...

    BOOL isExactly15 = NO;
    static NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion == 15 && version.minorVersion == 0 && version.patchVersion == 0) {
        isExactly15 = YES;
    }

    if (@available(iOS 15.0, *)) {
        shouldUseAXEvent = !isExactly15;
    } else {
        shouldUseAXEvent = NO;
    }

    if (shouldUseAXEvent)
    {
        static Class AXEventRepresentationCls = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
            AXEventRepresentationCls = objc_getClass("AXEventRepresentation");
        });

        AXEventRepresentation *rep = [AXEventRepresentationCls representationWithHIDEvent:event hidStreamIdentifier:@"UIApplicationEvents"];

        /* I don't like this. It's too hacky, but it works. */
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                static UIWindow *keyWindow = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    keyWindow = [[app windows] firstObject];
                });

                UIView *keyView = [keyWindow hitTest:[rep location] withEvent:nil];

                UITouchPhase phase = UITouchPhaseEnded;
                if ([rep isTouchDown])
                    phase = UITouchPhaseBegan;
                else if ([rep isMove])
                    phase = UITouchPhaseMoved;
                else if ([rep isCancel])
                    phase = UITouchPhaseCancelled;
                else if ([rep isLift] || [rep isInRange] || [rep isInRangeLift])
                    phase = UITouchPhaseEnded;

                NSInteger pointerId = [[[[rep handInfo] paths] firstObject] pathIdentity];
                if (pointerId > 0)
                    [Events receiveAXEventID:MIN(MAX(pointerId, 1), 98) atGlobalCoordinate:[rep location] withTouchPhase:phase inWindow:keyWindow onView:keyView];
            });
        }
    }
}


#pragma mark -

static NSString *_cachesDirectoryPath = nil;
static NSString *_hudPIDFilePath = nil;
static NSString *GetPIDFilePath(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cachesDirectoryPath = 
        [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _hudPIDFilePath = [_cachesDirectoryPath stringByAppendingPathComponent:@"hud.pid"];
    });
    return _hudPIDFilePath;
}

#pragma mark -

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        if (argc <= 1)
            return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
        
        if (strcmp(argv[1], "-hud") == 0)
        {
            pid_t pid = getpid();
            pid_t pgid = getgid();
            (void)pgid;

            NSString *pidString = [NSString stringWithFormat:@"%d", pid];
            [pidString writeToFile:GetPIDFilePath()
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:nil];
            
            [UIScreen initialize];
            CFRunLoopGetCurrent();

            GSInitialize();
            BKSDisplayServicesStart();
            UIApplicationInitialize();

            UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
            static id<UIApplicationDelegate> appDelegate = [[objc_getClass("HUDMainApplicationDelegate") alloc] init];
            [UIApplication.sharedApplication setDelegate:appDelegate];
            [UIApplication.sharedApplication _accessibilityInit];

            [NSRunLoop currentRunLoop];

            BKSHIDEventRegisterEventCallback(_HUDEventCallback);

            if (@available(iOS 15.0, *)) {
                GSEventInitialize(0);
                GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
            }
            
            [UIApplication.sharedApplication __completeAndRunAsPlugin];
            
            static int _springboardBootToken;
            notify_register_dispatch("SBSpringBoardDidLaunchNotification", &_springboardBootToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l), ^(int token) {
                notify_cancel(token);

                // Re-enable HUD after SpringBoard is launched.
                SetHUDEnabled(YES);

                // Exit the current instance of HUD.
#ifdef NOTIFY_DISMISSAL_HUD
                notify_post(NOTIFY_DISMISSAL_HUD);
#endif
                kill(pid, SIGKILL);
            });

            CFRunLoopRun();
            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-exit") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:GetPIDFilePath()
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];
            
            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                kill(pid, SIGKILL);
                unlink(GetPIDFilePath().UTF8String);
            }

            return EXIT_SUCCESS;
        }
        else if (strcmp(argv[1], "-check") == 0)
        {
            NSString *pidString = [NSString stringWithContentsOfFile:GetPIDFilePath()
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];
            
            if (pidString)
            {
                pid_t pid = (pid_t)[pidString intValue];
                int killed = kill(pid, 0);
                return (killed == 0 ? EXIT_FAILURE : EXIT_SUCCESS);
            }
            else return EXIT_SUCCESS;  // No PID file, so HUD is not running
        }
    }
}