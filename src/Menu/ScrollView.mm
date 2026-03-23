#import "ScrollView.h"

@interface ScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, assign) CGPoint lastTouchPoint;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *reuseQueues;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *registeredClasses;

@property (nonatomic, strong) UIView *verticalScrollIndicator;
@property (nonatomic, strong) UIView *horizontalScrollIndicator;

@property (nonatomic, strong) NSTimer *verticalIndicatorTimer;
@property (nonatomic, strong) NSTimer *horizontalIndicatorTimer;

@property (nonatomic, assign) BOOL indicatorsHidden;

@end

@implementation ScrollView {
    CGFloat indicatorThickness;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_contentView];
        
        self.reuseQueues = [NSMutableDictionary dictionary];
        self.registeredClasses = [NSMutableDictionary dictionary];
        
        [self setupScrollIndicators];
        
        self.userInteractionEnabled = YES;
        
        self.indicatorsHidden = NO;
    }
    
    return self;
}

#pragma mark - Scroll Indicators Setup

- (void)setupScrollIndicators {
    indicatorThickness = 10.0;
    
    self.verticalScrollIndicator = [[UIView alloc] init];
    self.verticalScrollIndicator.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    self.verticalScrollIndicator.userInteractionEnabled = YES;
    self.verticalScrollIndicator.alpha = 0;
    self.verticalScrollIndicator.layer.cornerRadius = indicatorThickness / 2;
    self.verticalScrollIndicator.clipsToBounds = YES;
    [self addSubview:self.verticalScrollIndicator];
    
    UIPanGestureRecognizer *verticalPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleVerticalIndicatorPan:)];
    verticalPan.delegate = self;
    [self.verticalScrollIndicator addGestureRecognizer:verticalPan];
    
    self.horizontalScrollIndicator = [[UIView alloc] init];
    self.horizontalScrollIndicator.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    self.horizontalScrollIndicator.userInteractionEnabled = YES;
    self.horizontalScrollIndicator.alpha = 0;
    self.horizontalScrollIndicator.layer.cornerRadius = indicatorThickness / 2;
    self.horizontalScrollIndicator.clipsToBounds = YES;
    [self addSubview:self.horizontalScrollIndicator];
    
    UIPanGestureRecognizer *horizontalPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalIndicatorPan:)];
    horizontalPan.delegate = self;
    [self.horizontalScrollIndicator addGestureRecognizer:horizontalPan];
}

- (void)setScrollIndicatorsHidden:(BOOL)hidden {
    self.indicatorsHidden = hidden;
    self.verticalScrollIndicator.hidden = hidden;
    self.horizontalScrollIndicator.hidden = hidden;
}

- (void)updateScrollIndicators {
    if (self.indicatorsHidden) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGFloat contentHeight = self.contentView.bounds.size.height;
        CGFloat contentWidth = self.contentView.bounds.size.width;
        CGFloat visibleHeight = self.bounds.size.height;
        CGFloat visibleWidth = self.bounds.size.width;
    
        contentHeight = MAX(contentHeight, visibleHeight);
        contentWidth = MAX(contentWidth, visibleWidth);
    
        CGFloat yRatio = visibleHeight / contentHeight;
        CGFloat xRatio = visibleWidth / contentWidth;
    
        CGFloat verticalIndicatorHeight = MAX(yRatio * visibleHeight, 30);
        CGFloat verticalIndicatorY = -self.contentView.frame.origin.y / contentHeight * visibleHeight;
    
        CGFloat horizontalIndicatorWidth = MAX(xRatio * visibleWidth, 30);
        CGFloat horizontalIndicatorX = -self.contentView.frame.origin.x / contentWidth * visibleWidth;

        if (isnan(verticalIndicatorY) || isnan(horizontalIndicatorX)) {
            NSLog(@"Error: Calculated NaN values for scroll indicators.");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.verticalScrollIndicator.hidden = YES;
                self.horizontalScrollIndicator.hidden = YES;
            });
            return;
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            self.horizontalScrollIndicator.frame = CGRectMake(horizontalIndicatorX, self.bounds.size.height - indicatorThickness, horizontalIndicatorWidth, indicatorThickness);
            self.verticalScrollIndicator.frame = CGRectMake(self.bounds.size.width - indicatorThickness, verticalIndicatorY, indicatorThickness, verticalIndicatorHeight);
    
            self.verticalScrollIndicator.hidden = contentHeight <= visibleHeight;
            self.horizontalScrollIndicator.hidden = contentWidth <= visibleWidth;
    
            [self showScrollIndicators];
        });
    });
}

- (void)showScrollIndicators {
    [UIView animateWithDuration:0.2 animations:^{
        self.verticalScrollIndicator.alpha = 1.0;
        self.horizontalScrollIndicator.alpha = 1.0;
    }];
    
    [self resetIndicatorTimers];
}

- (void)hideScrollIndicators {
    [UIView animateWithDuration:0.3 animations:^{
        self.verticalScrollIndicator.alpha = 0.0;
        self.horizontalScrollIndicator.alpha = 0.0;
    }];
}

- (void)resetIndicatorTimers {
    [self.verticalIndicatorTimer invalidate];
    [self.horizontalIndicatorTimer invalidate];
    
    self.verticalIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hideScrollIndicators) userInfo:nil repeats:NO];
    self.horizontalIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hideScrollIndicators) userInfo:nil repeats:NO];
}

- (void)handleVerticalIndicatorPan:(UIPanGestureRecognizer *)gesture {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGPoint translation = [gesture translationInView:self];
        CGFloat contentHeight = self.contentView.bounds.size.height;
        CGFloat visibleHeight = self.bounds.size.height;
        CGFloat maxContentOffsetY = contentHeight - visibleHeight;
    
        CGFloat contentOffsetY = -self.contentView.frame.origin.y;
        CGFloat deltaY = translation.y * (contentHeight / visibleHeight);
        contentOffsetY += deltaY;
        contentOffsetY = MIN(MAX(contentOffsetY, 0), maxContentOffsetY);
    
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.y = -contentOffsetY;

        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentView.frame = contentFrame;    
            [gesture setTranslation:CGPointZero inView:self];
            [self updateScrollIndicators];
        });
    });
}

- (void)handleHorizontalIndicatorPan:(UIPanGestureRecognizer *)gesture {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGPoint translation = [gesture translationInView:self];
        CGFloat contentWidth = self.contentView.bounds.size.width;
        CGFloat visibleWidth = self.bounds.size.width;
        CGFloat maxContentOffsetX = contentWidth - visibleWidth;
    
        CGFloat contentOffsetX = -self.contentView.frame.origin.x;
        CGFloat deltaX = translation.x * (contentWidth / visibleWidth);
        contentOffsetX += deltaX;
        contentOffsetX = MIN(MAX(contentOffsetX, 0), maxContentOffsetX);
    
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.x = -contentOffsetX;

        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentView.frame = contentFrame;    
            [gesture setTranslation:CGPointZero inView:self];
            [self updateScrollIndicators];
        });
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return NO;
}

#pragma mark - Reusable Views Management

- (void)registerClass:(Class)viewClass forReuseIdentifier:(NSString *)identifier {
    self.registeredClasses[identifier] = viewClass;
    self.reuseQueues[identifier] = [NSMutableSet set];
}

- (UIView *)dequeueReusableViewWithIdentifier:(NSString *)identifier {
    NSMutableSet *queue = self.reuseQueues[identifier];
    UIView *view = [queue anyObject];
    if (view) {
        [queue removeObject:view];
    } else {
        Class viewClass = self.registeredClasses[identifier];
        if (viewClass) {
            view = [[viewClass alloc] init];
        } else {
            NSLog(@"Error: No class registered for identifier %@", identifier);
            return nil;
        }
    }
    return view;
}

- (void)enqueueReusableView:(UIView *)view withIdentifier:(NSString *)identifier {
    if (!self.reuseQueues[identifier]) {
        self.reuseQueues[identifier] = [NSMutableSet set];
    }
    [self.reuseQueues[identifier] addObject:view];
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    if (CGRectContainsPoint(self.verticalScrollIndicator.frame, touchPoint) ||
        CGRectContainsPoint(self.horizontalScrollIndicator.frame, touchPoint)) {
        return;
    }
    
    self.lastTouchPoint = touchPoint;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    
    CGFloat deltaX = currentPoint.x - self.lastTouchPoint.x;
    CGFloat deltaY = currentPoint.y - self.lastTouchPoint.y;
    
    CGPoint newOrigin = CGPointMake(self.contentView.frame.origin.x + deltaX, self.contentView.frame.origin.y + deltaY);
    
    CGFloat maxX = 0;
    CGFloat minX = self.bounds.size.width - self.contentView.bounds.size.width;
    CGFloat maxY = 0;
    CGFloat minY = self.bounds.size.height - self.contentView.bounds.size.height;
    
    if (self.contentView.bounds.size.width < self.bounds.size.width) {
        minX = maxX = (self.bounds.size.width - self.contentView.bounds.size.width) / 2;
    }
    
    if (self.contentView.bounds.size.height < self.bounds.size.height) {
        minY = maxY = (self.bounds.size.height - self.contentView.bounds.size.height) / 2;
    }
    
    newOrigin.x = MIN(MAX(newOrigin.x, minX), maxX);
    newOrigin.y = MIN(MAX(newOrigin.y, minY), maxY);
    
    self.contentView.frame = CGRectMake(newOrigin.x, newOrigin.y, self.contentView.frame.size.width, self.contentView.frame.size.height);
    
    [self updateScrollIndicators];
    
    self.lastTouchPoint = currentPoint;
}

#pragma mark - Layout and Content Size

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateContentSize];
    
    [self updateScrollIndicators];
}

- (void)updateContentSize {
    CGFloat maxWidth = self.bounds.size.width;
    CGFloat maxHeight = self.bounds.size.height;
    
    for (UIView *subview in self.contentView.subviews) {
        CGFloat subviewMaxX = CGRectGetMaxX(subview.frame);
        CGFloat subviewMaxY = CGRectGetMaxY(subview.frame);
        
        if (subviewMaxX > maxWidth) {
            maxWidth = subviewMaxX;
        }
        if (subviewMaxY > maxHeight) {
            maxHeight = subviewMaxY;
        }
    }
    
    maxWidth = MAX(maxWidth, self.bounds.size.width);
    maxHeight = MAX(maxHeight, self.bounds.size.height);
    
    CGSize newContentSize = CGSizeMake(maxWidth, maxHeight);
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size = newContentSize;
    self.contentView.frame = contentViewFrame;
    
    CGFloat maxX = 0;
    CGFloat minX = self.bounds.size.width - self.contentView.bounds.size.width;
    CGFloat maxY = 0;
    CGFloat minY = self.bounds.size.height - self.contentView.bounds.size.height;
    
    if (self.contentView.bounds.size.width < self.bounds.size.width) {
        minX = maxX = (self.bounds.size.width - self.contentView.bounds.size.width) / 2;
    }
    if (self.contentView.bounds.size.height < self.bounds.size.height) {
        minY = maxY = (self.bounds.size.height - self.contentView.bounds.size.height) / 2;
    }
    
    CGPoint origin = contentViewFrame.origin;
    origin.x = MIN(MAX(origin.x, minX), maxX);
    origin.y = MIN(MAX(origin.y, minY), maxY);
    self.contentView.frame = CGRectMake(origin.x, origin.y, contentViewFrame.size.width, contentViewFrame.size.height);
}

@end
