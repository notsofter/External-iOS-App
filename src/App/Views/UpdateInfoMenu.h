#import <UIKit/UIKit.h>
#import "ViewMenu.h"

@interface UpdateInfoMenu : ViewMenu

- (instancetype)initWithStackView:(UIStackView *)stackView;

- (void)setChangelogText:(NSString *)text;

@end
