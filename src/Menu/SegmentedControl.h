#import <UIKit/UIKit.h>
#import "ScrollView.h"

@interface SegmentedControl : UIView

@property (nonatomic, copy) NSArray<NSString *> *items;
@property (nonatomic, assign) int selectedIndex;
@property (nonatomic, copy) void (^valueChangedHandler)(int selectedIndex);

@property (nonatomic, copy) NSString *defaultsKey;

- (instancetype)initWithFrame:(CGRect)frame items:(NSArray<NSString *> *)items defaultsKey:(NSString *)defaultsKey;

@end
