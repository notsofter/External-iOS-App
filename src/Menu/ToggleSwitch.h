#import <UIKit/UIKit.h>

@interface ToggleSwitch : UIView

@property (nonatomic, assign, getter=isOn) BOOL on;
@property (nonatomic, copy) NSString *defaultsKey;

- (instancetype)initWithFrame:(CGRect)frame andKey:(NSString *)defaultsKey;
- (void)setOn:(BOOL)on animated:(BOOL)animated;

@end