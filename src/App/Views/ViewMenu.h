#import <UIKit/UIKit.h>
#import "../../UI/NotificationView.h"

@interface ViewMenu : UIView
@property (nonatomic, strong) UIStackView *mainStackView;
@property (nonatomic, strong) ഘഫഭറളഠഠഔഉഘഢധഏഊഷഠഞഒഛഖ *notificationView;
@property (nonatomic, strong) NSString *title;
- (id)initWithView:(UIView *)view;
- (void)setupUI;
- (void)setInteractableBlurView:(BOOL)arg;
- (void)showViewMenu;
- (void)removeViewMenu;
- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action;

@end

