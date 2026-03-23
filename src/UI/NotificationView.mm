#import "NotificationView.h"

@implementation ഘഫഭറളഠഠഔഉഘഢധഏഊഷഠഞഒഛഖ {
    CGFloat statusBarHeight;
}

- (instancetype)initWithSize:(CGSize)size {
    CGFloat viewWidth = size.width;
    CGFloat viewHeight = size.height;
    statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height + 10;
    CGFloat centerX = ([UIScreen mainScreen].bounds.size.width - viewWidth) / 2.0;
    CGFloat centerY = ([UIScreen mainScreen].bounds.size.height - viewHeight) / 2.0;

    self = [super initWithFrame:CGRectMake(centerX, centerY, viewWidth, viewHeight)];
    if (self) {
        self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
        self.alpha = 0.0;

        CGFloat labelWidth = self.frame.size.width;
        CGFloat labelHeight = self.frame.size.height;
        CGRect labelFrame = CGRectMake(0, 0, labelWidth, labelHeight);

        self.textLabel = [[UILabel alloc] initWithFrame:labelFrame];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.font = [UIFont systemFontOfSize:labelHeight / 2];
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)start {
    self.alpha = 0.0;
    self.frame = CGRectMake(self.frame.origin.x, -(self.frame.size.height + statusBarHeight), self.frame.size.width, self.frame.size.height);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        self.frame = CGRectMake(self.frame.origin.x, statusBarHeight, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL completed) {
        //if (completed) {
            [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
                [self stop];
            }];
        //}
    }];
}

- (void)stop {
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(self.frame.origin.x, -(self.frame.size.height + statusBarHeight), self.frame.size.width, self.frame.size.height);
        self.alpha = 0.0;
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view == self) {
        self.textLabel.alpha = 0.4;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view == self) {
        self.textLabel.alpha = 1.0;
    }
}

@end
