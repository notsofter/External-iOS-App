#import "SegmentedControl.h"

@interface SegmentedControl ()

@property (nonatomic, strong) ScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UIView *> *segments;

@end

@implementation SegmentedControl

- (instancetype)initWithFrame:(CGRect)frame items:(NSArray<NSString *> *)items defaultsKey:(NSString *)defaultsKey {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = true;
        _items = [items copy];
        _defaultsKey = [defaultsKey copy];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:_defaultsKey] != nil) {
            _selectedIndex = (int)[defaults integerForKey:_defaultsKey];
        } else {
            _selectedIndex = 0;
        }
        
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.scrollView = [[ScrollView alloc] initWithFrame:self.bounds];
    [self.scrollView setScrollIndicatorsHidden:YES];
    [self addSubview:self.scrollView];
    
    self.segments = [NSMutableArray array];
    
    CGFloat x = 10;
    CGFloat segmentHeight = self.bounds.size.height - 10;
    
    for (int i = 0; i < self.items.count; i++) {
        NSString *title = self.items[i];
        
        CGSize textSize = [title sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}];
        CGFloat segmentWidth = textSize.width + 20;
        
        UIView *segmentView = [[UIView alloc] initWithFrame:CGRectMake(x - 10, 5, segmentWidth, segmentHeight)];
        segmentView.backgroundColor = (i == self.selectedIndex) ? [UIColor colorWithRed:0.26 green:0.80 blue:0.46 alpha:1.0] : [UIColor grayColor];
        segmentView.layer.cornerRadius = 5;
        segmentView.clipsToBounds = YES;
        segmentView.userInteractionEnabled = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:segmentView.bounds];
        label.text = title;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.userInteractionEnabled = false;
        [segmentView addSubview:label];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segmentTapped:)];
        [segmentView addGestureRecognizer:tapGesture];
        
        [self.scrollView.contentView addSubview:segmentView];
        [self.segments addObject:segmentView];
        
        x += segmentWidth + 10;
    }
    
    [self.scrollView layoutSubviews];
}

- (void)segmentTapped:(UITapGestureRecognizer *)gesture {
    UIView *tappedSegment = gesture.view;
    int index = (int)[self.segments indexOfObject:tappedSegment];
    if (index != NSNotFound && index != self.selectedIndex) {
        self.selectedIndex = index;
        [self updateSegmentStates];
        
        if (self.defaultsKey) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:index forKey:self.defaultsKey];
            [defaults synchronize];
        }
        
        if (self.valueChangedHandler) {
            self.valueChangedHandler(index);
        }
    }
}

- (void)setSelectedIndex:(int)selectedIndex {
    _selectedIndex = selectedIndex;
    [self updateSegmentStates];
}

- (void)updateSegmentStates {
    for (int i = 0; i < self.segments.count; i++) {
        UIView *segment = self.segments[i];
        if (i == self.selectedIndex) {
            segment.backgroundColor = [UIColor colorWithRed:0.26 green:0.80 blue:0.46 alpha:1.0];
        } else {
            segment.backgroundColor = [UIColor grayColor];
        }
    }
}

@end
