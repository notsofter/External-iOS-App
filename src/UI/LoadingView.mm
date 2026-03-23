#import "LoadingView.h"

@implementation LoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
        
        self.customActivityIndicator = [[UIView alloc] init];
        self.customActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.customActivityIndicator];
        [self createCustomActivityIndicator];
        
        self.statusLabel = [[UILabel alloc] init];
        self.statusLabel.text = @"Loading";
        self.statusLabel.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.8];
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.statusLabel];

        [self setupCheckmarkLayer];

        [NSLayoutConstraint activateConstraints:@[
            [self.customActivityIndicator.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.customActivityIndicator.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-13],
            [self.customActivityIndicator.widthAnchor constraintEqualToConstant:50],
            [self.customActivityIndicator.heightAnchor constraintEqualToConstant:50],
            
            [self.statusLabel.topAnchor constraintEqualToAnchor:self.customActivityIndicator.bottomAnchor constant:40],
            [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
        ]];
    }
    return self;
}

- (void)createCustomActivityIndicator {
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    CGPoint center = CGPointMake(25, 25);
    CGFloat radius = 35;
    
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center
                                                              radius:radius
                                                          startAngle:0
                                                            endAngle:M_PI
                                                           clockwise:YES];
    
    circleLayer.path = circlePath.CGPath;
    circleLayer.strokeColor = [UIColor.whiteColor colorWithAlphaComponent:0.8].CGColor;
    circleLayer.fillColor = [UIColor clearColor].CGColor;
    circleLayer.lineWidth = 4;
    circleLayer.lineCap = kCALineCapRound;
    
    [self.customActivityIndicator.layer addSublayer:circleLayer];
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.toValue = @(M_PI * 2);
    rotationAnimation.duration = 1.0;
    rotationAnimation.repeatCount = INFINITY;
    
    [self.customActivityIndicator.layer addAnimation:rotationAnimation forKey:@"rotation"];
}

- (void)setupCheckmarkLayer {
    self.checkmarkLayer = [CAShapeLayer layer];
    self.checkmarkLayer.fillColor = UIColor.clearColor.CGColor;
    self.checkmarkLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.checkmarkLayer.lineWidth = 5;
    self.checkmarkLayer.lineCap = kCALineCapRound;
    self.checkmarkLayer.lineJoin = kCALineJoinRound;
    self.checkmarkLayer.strokeEnd = 0;
    //self.checkmarkLayer.position = self.center;
    [self.layer addSublayer:self.checkmarkLayer];
    
    UIBezierPath *checkmarkPath = [UIBezierPath bezierPath];
    CGFloat startX = self.bounds.size.width / 2 - 15;
    CGFloat startY = self.bounds.size.height / 2 - 10;
    [checkmarkPath moveToPoint:CGPointMake(startX, startY)];
    [checkmarkPath addLineToPoint:CGPointMake(startX + 10, startY + 20)];
    [checkmarkPath addLineToPoint:CGPointMake(startX + 40, startY - 10)];
    self.checkmarkLayer.path = checkmarkPath.CGPath;
}

- (void)setStatusText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = text;
    });
}

- (void)showCheckmark {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.customActivityIndicator.layer removeAllAnimations];
        self.customActivityIndicator.hidden = YES;
    
        CABasicAnimation *checkmarkAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        checkmarkAnimation.fromValue = @(0);
        checkmarkAnimation.toValue = @(1);
        checkmarkAnimation.duration = 0.5;
        self.checkmarkLayer.strokeEnd = 1;
        [self.checkmarkLayer addAnimation:checkmarkAnimation forKey:@"checkmarkAnimation"];
        self.checkmarkLayer.hidden = NO;
    });
}

@end
