#import <UIKit/UIKit.h>

@interface Slider : UIView

@property (nonatomic, assign) float minimumValue;
@property (nonatomic, assign) float maximumValue;
@property (nonatomic, assign) float value;

@property (nonatomic, copy) NSString *defaultsKey;
- (instancetype)initWithFrame:(CGRect)frame andKey:(NSString *)defaultsKey;
- (void)addTarget:(id)target action:(SEL)action;
@end
