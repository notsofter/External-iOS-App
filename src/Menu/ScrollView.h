#import <UIKit/UIKit.h>

@interface ScrollView : UIView

@property (nonatomic, strong, readonly) UIView *contentView;

- (void)registerClass:(Class)viewClass forReuseIdentifier:(NSString *)identifier;
- (UIView *)dequeueReusableViewWithIdentifier:(NSString *)identifier;

- (void)setScrollIndicatorsHidden:(BOOL)hidden;

@end
