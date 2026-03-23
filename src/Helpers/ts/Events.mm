#import <dlfcn.h>
#import <string.h>
#import <CoreFoundation/CoreFoundation.h>
#import "Events.h"
#import "../private_headers/UIEvent+Private.h"
#import "../private_headers/UITouch-KIFAdditions.h"
#import "../private_headers/UIApplication+Private.h"

static UITouch *_currentTouch = nil;
static CFRunLoopSourceRef _source = NULL;

static UITouch *toRemove = nil;
static UITouch *toStationarify = nil;

static void __EventsCallback(void *info)
{
    static UIApplication *app = [UIApplication sharedApplication];
    UIEvent *event = [app _touchesEvent];
    
    // Retain objects from being released
    [event _clearTouches];

    if (_currentTouch)
    {
        switch (_currentTouch.phase) {
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                toRemove = _currentTouch;
                break;
            case UITouchPhaseBegan:
                toStationarify = _currentTouch;
                break;
            default:
                break;
        }
        [event _addTouch:_currentTouch forDelayedDelivery:NO];
    }
    [app sendEvent:event];
}

@implementation Events

+ (void)load
{
    CFRunLoopSourceContext context;
    memset(&context, 0, sizeof(CFRunLoopSourceContext));
    context.perform = __EventsCallback;
    
    // Content of context is copied
    _source = CFRunLoopSourceCreate(kCFAllocatorDefault, -2, &context);
    CFRunLoopRef loop = CFRunLoopGetMain();
    CFRunLoopAddSource(loop, _source, kCFRunLoopCommonModes);
}

+ (NSInteger)receiveAXEventID:(NSInteger)eventId
           atGlobalCoordinate:(CGPoint)coordinate
               withTouchPhase:(UITouchPhase)phase
                     inWindow:(UIWindow *)window
                       onView:(UIView *)view
{
    BOOL deleted = NO;

    if (toRemove != nil)
    {
        _currentTouch = nil;
        toRemove = nil;
        deleted = YES;
    }

    if (toStationarify != nil)
    {
        if (_currentTouch.phase == UITouchPhaseBegan)
            [_currentTouch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
        toStationarify = nil;
    }

    if (!_currentTouch)
    {
        if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled)
            return deleted;
        _currentTouch = [[UITouch alloc] initAtPoint:coordinate inWindow:window onView:view];
    }
    else
    {
        if (_currentTouch.phase == UITouchPhaseBegan && phase == UITouchPhaseMoved)
            return deleted;
        [_currentTouch setLocationInWindow:coordinate];
    }

    [_currentTouch setPhaseAndUpdateTimestamp:phase];

    CFRunLoopSourceSignal(_source);
    return deleted;
}

@end