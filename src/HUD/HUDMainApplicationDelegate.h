#import <UIKit/UIKit.h>
#import "HUDMainWindow.h"
#import "../Helpers/CustomDefaults.h"
#import "../Helpers/Device.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUDMainApplicationDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) HUDMainWindow *window;
@end

NS_ASSUME_NONNULL_END