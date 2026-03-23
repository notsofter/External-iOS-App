#import <UIKit/UIKit.h>

@interface LoadingView : UIView

@property (nonatomic, strong) UIView *customActivityIndicator;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) CAShapeLayer *checkmarkLayer;

- (void)setStatusText:(NSString *)text;
- (void)showCheckmark;

@end