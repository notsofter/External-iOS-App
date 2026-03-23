#import <UIKit/UIKit.h>
#import "ImGuiDrawView.h"

#define NOTIFY_UI_LOCKSTATE    "com.apple.springboard.lockstate"

NS_ASSUME_NONNULL_BEGIN

@interface HUDRootViewController: UIViewController
@property (nonatomic, strong) UIView *contentView;
@end

NS_ASSUME_NONNULL_END