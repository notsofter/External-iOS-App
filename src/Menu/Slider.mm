#import "Slider.h"

@interface Slider ()

@property (nonatomic, strong) UIView *leftTrackView;
@property (nonatomic, strong) UIView *rightTrackView;
@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@end

@implementation Slider

- (instancetype)initWithFrame:(CGRect)frame andKey:(NSString *)defaultsKey {
    self = [super initWithFrame:frame];
    
    if (self) {
        _minimumValue = 0.0f;
        _maximumValue = 1.0f;
        _defaultsKey = [defaultsKey copy];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:_defaultsKey] != nil) {
            _value = [defaults floatForKey:_defaultsKey];
        } else {
            _value = _minimumValue;
        }
        
        [self setupViews];
        [self updateThumbPosition];
    }
    
    return self;
}

- (void)setupViews {
    CGFloat trackHeight = 4.0;
    CGFloat thumbSize = self.bounds.size.height;
    CGFloat trackY = (self.bounds.size.height - trackHeight) / 2;
    
    self.leftTrackView = [[UIView alloc] initWithFrame:CGRectMake(0, trackY, 0, trackHeight)];
    self.leftTrackView.backgroundColor = [UIColor colorWithRed:0.26 green:0.80 blue:0.46 alpha:1.0];
    self.leftTrackView.layer.cornerRadius = trackHeight / 2;
    [self addSubview:self.leftTrackView];
    
    self.rightTrackView = [[UIView alloc] initWithFrame:CGRectMake(0, trackY, self.bounds.size.width, trackHeight)];
    self.rightTrackView.backgroundColor = [UIColor lightGrayColor];
    self.rightTrackView.layer.cornerRadius = trackHeight / 2;
    [self addSubview:self.rightTrackView];
    
    self.thumbView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thumbSize, thumbSize)];
    self.thumbView.backgroundColor = [UIColor whiteColor];
    self.thumbView.layer.cornerRadius = thumbSize / 2;
    self.thumbView.center = CGPointMake(thumbSize / 2, self.bounds.size.height / 2);
    [self addSubview:self.thumbView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.thumbView addGestureRecognizer:panGesture];
    self.thumbView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)setValue:(float)value {
    _value = MIN(MAX(value, self.minimumValue), self.maximumValue);
    [self updateThumbPosition];
    [self saveValue];
}

- (void)updateThumbPosition {
    CGFloat ratio = (self.value - self.minimumValue) / (self.maximumValue - self.minimumValue);
    CGFloat thumbX = ratio * (self.bounds.size.width - self.thumbView.bounds.size.width);
    CGFloat thumbCenterX = thumbX + self.thumbView.bounds.size.width / 2;
    self.thumbView.center = CGPointMake(thumbCenterX, self.bounds.size.height / 2);
    
    CGFloat trackY = (self.bounds.size.height - self.leftTrackView.bounds.size.height) / 2;
    self.leftTrackView.frame = CGRectMake(0, trackY, thumbCenterX, self.leftTrackView.bounds.size.height);
    self.rightTrackView.frame = CGRectMake(thumbCenterX, trackY, self.bounds.size.width - thumbCenterX, self.rightTrackView.bounds.size.height);
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    CGPoint thumbCenter = self.thumbView.center;
    thumbCenter.x += translation.x;
    CGFloat halfWidth = self.thumbView.bounds.size.width / 2;
    thumbCenter.x = MIN(MAX(thumbCenter.x, halfWidth), self.bounds.size.width - halfWidth);
    self.thumbView.center = thumbCenter;
    
    [gesture setTranslation:CGPointZero inView:self];
    
    CGFloat ratio = (thumbCenter.x - halfWidth) / (self.bounds.size.width - self.thumbView.bounds.size.width);
    self.value = self.minimumValue + ratio * (self.maximumValue - self.minimumValue);
    
    [self sendActions];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    CGFloat halfWidth = self.thumbView.bounds.size.width / 2;
    CGFloat thumbCenterX = MIN(MAX(location.x, halfWidth), self.bounds.size.width - halfWidth);
    self.thumbView.center = CGPointMake(thumbCenterX, self.bounds.size.height / 2);
    
    CGFloat ratio = (thumbCenterX - halfWidth) / (self.bounds.size.width - self.thumbView.bounds.size.width);
    self.value = self.minimumValue + ratio * (self.maximumValue - self.minimumValue);
    
    [self sendActions];
}

- (void)sendActions {
    [self updateThumbPosition];

    if (self.target && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop
    }
}

- (void)addTarget:(id)target action:(SEL)action {
    self.target = target;
    self.action = action;
}

#pragma mark - Persistence

- (void)saveValue {
    if (self.defaultsKey) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:self.value forKey:self.defaultsKey];
        [defaults synchronize];
    }
}

@end
