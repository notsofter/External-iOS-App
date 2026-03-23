#import "HUDMainWindow.h"

@implementation HUDMainWindow
- (BOOL)_isWindowServerHostingManaged { return NO; }
+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_ignoresHitTest { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }
@end