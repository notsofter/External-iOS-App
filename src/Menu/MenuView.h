#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "../Helpers/Device.h"
#import "ToggleSwitch.h"
#import "Slider.h"
#import "ScrollView.h"
#import "SegmentedControl.h"

typedef void(^ButtonActionBlock)(UILabel *titleLabel);

@interface MenuView : UIView

@property (nonatomic, assign) CGFloat verticalPadding;
@property (nonatomic, assign) CGFloat horizontalPadding;

- (void)addPage:(NSString *)pageName;
- (void)addCell:(NSString *)cellTitle toPage:(NSString *)pageName;

- (ToggleSwitch *)addSwitchCellWithTitle:(NSString *)cellTitle toPage:(NSString *)pageName;

- (Slider *)addSliderCellWithTitle:(NSString *)cellTitle toPage:(NSString *)pageName minValue:(float)min maxValue:(float)max;

- (SegmentedControl *)addSegmentedControlCellWithTitle:(NSString *)cellTitle toPage:(NSString *)pageName items:(NSArray<NSString *> *)items;

- (void)addButtonWithTitle:(NSString *)title action:(ButtonActionBlock)action;

- (void)handle;

@end

static MenuView *menuView;