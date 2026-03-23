#import "ToggleSwitch.h"

@interface ToggleSwitch ()

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIView *thumbView;

@end

@implementation ToggleSwitch

- (instancetype)initWithFrame:(CGRect)frame andKey:(NSString *)defaultsKey {
    self = [super initWithFrame:frame];
    if (self) {
        _defaultsKey = [defaultsKey copy];
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
    self.backgroundView.layer.cornerRadius = CGRectGetHeight(self.frame) / 2;
    [self addSubview:self.backgroundView];
    
    CGFloat thumbSize = CGRectGetHeight(self.frame) - 4;
    self.thumbView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, thumbSize, thumbSize)];
    self.thumbView.backgroundColor = [UIColor whiteColor];
    self.thumbView.layer.cornerRadius = thumbSize / 2;
    self.thumbView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.thumbView.layer.shadowOpacity = 0.3;
    self.thumbView.layer.shadowRadius = 3.0;
    self.thumbView.layer.shadowOffset = CGSizeMake(0, 2);
    self.thumbView.layer.masksToBounds = NO;
    [self addSubview:self.thumbView];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.on = [defaults boolForKey:self.defaultsKey];
    [self setOn:self.on animated:NO];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSwitch)];
    [self addGestureRecognizer:tapGesture];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:on forKey:self.defaultsKey];
    [defaults synchronize];
    
    UIColor *backgroundColor = on ? [UIColor colorWithRed:0.26 green:0.80 blue:0.46 alpha:1.0] : [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
    CGFloat thumbX = on ? CGRectGetWidth(self.frame) - CGRectGetWidth(self.thumbView.frame) - 2 : 2;
    
    void (^animations)(void) = ^{
        self.thumbView.frame = CGRectMake(thumbX, 2, CGRectGetWidth(self.thumbView.frame), CGRectGetHeight(self.thumbView.frame));
        self.backgroundView.backgroundColor = backgroundColor;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    } else {
        animations();
    }
}

- (void)toggleSwitch {
    [self setOn:!self.isOn animated:YES];
}

@end
