#import "MenuView.h"

@interface MenuView ()
@property (nonatomic, strong) UIView *buttonsPanel;
@property (nonatomic, strong) NSMutableArray<UIView *> *pageViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *pageViewsDict;
@property (nonatomic, strong) UIView *contentPanel;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ScrollView *> *pagesDict;
@property (nonatomic, strong) NSString *currentPageName;

@end

@implementation MenuView {
    UIImageView *headerImageView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //self.layer.shouldRasterize = YES;
        //self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.layer.cornerRadius = 15;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];
        
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    CGFloat panelWidth = self.bounds.size.width * 0.3;
    CGFloat contentWidth = self.bounds.size.width - panelWidth;

    self.buttonsPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelWidth, self.bounds.size.height)];
    self.buttonsPanel.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    [self addSubview:self.buttonsPanel];

    [self addHeaderImageView];
    
    self.pageViews = [NSMutableArray array];
    self.pageViewsDict = [NSMutableDictionary dictionary];
    
    self.contentPanel = [[UIView alloc] initWithFrame:CGRectMake(panelWidth, 15, contentWidth, self.bounds.size.height - 30)];
    self.contentPanel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentPanel];
    
    self.pagesDict = [NSMutableDictionary dictionary];
}

- (void)addHeaderImageView {
    CGFloat imageSize = self.buttonsPanel.bounds.size.width / 2 - 10;
    headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.buttonsPanel.center.x - imageSize / 2, imageSize / 2, imageSize, imageSize)];
    headerImageView.contentMode = UIViewContentModeScaleAspectFit;
    headerImageView.userInteractionEnabled = true;
    [self.buttonsPanel addSubview:headerImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handle)];
    [headerImageView addGestureRecognizer:tapGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [headerImageView addGestureRecognizer:panGesture];

    UIImage *image = [UIImage imageNamed:@"logo.png"];
    headerImageView.image = image;
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGPoint translation = [sender translationInView:self.superview];
        CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);

        newCenter.y = MAX(newCenter.y, self.frame.size.height / 2 + self.verticalPadding);
        newCenter.y = MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2 - self.verticalPadding);
        newCenter.x = MAX(newCenter.x, self.frame.size.width / 2 + self.horizontalPadding);
        newCenter.x = MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2 - self.horizontalPadding);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.center = newCenter;
            [sender setTranslation:CGPointZero inView:self.superview];
        });
    });
}

- (void)downloadImageWithURL:(NSURL *)url saveAs:(NSString *)imageName {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url
                                                       completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSString *documentsPath = [Device getDocumentsApp];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:imageName];
            NSError *fileError = nil;
            
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&fileError];
            if (!fileError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                    headerImageView.image = image;
                });
            }
        }
    }];
    
    [downloadTask resume];
}

#pragma mark - Public Methods

- (void)addButtonWithTitle:(NSString *)title action:(void (^)(UILabel *titleLabel))actionBlock {
    if (self.pagesDict[title]) {
        return;
    }
    
    UIView *pageView = [[UIView alloc] init];
    CGFloat viewHeight = 40;
    CGFloat viewY = self.pageViews.count * viewHeight + CGRectGetMaxY(headerImageView.frame) + 15;
    pageView.frame = CGRectMake(0, viewY, self.buttonsPanel.bounds.size.width, viewHeight);
    pageView.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:pageView.bounds];
    label.text = title;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    [pageView addSubview:label];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonTapped:)];
    [pageView addGestureRecognizer:tapGesture];
    
    [self.buttonsPanel addSubview:pageView];
    
    [self.pageViews addObject:pageView];
    self.pageViewsDict[title] = pageView;

    objc_setAssociatedObject(tapGesture, "buttonAction", actionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)buttonTapped:(UITapGestureRecognizer *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            sender.view.backgroundColor = [UIColor clearColor];
            void (^actionBlock)(UILabel *) = objc_getAssociatedObject(sender, "buttonAction");
            if (actionBlock) {
                actionBlock(sender.view.subviews.firstObject);
            }
        }];
    }];
}

- (void)addPage:(NSString *)pageName {
    if (self.pagesDict[pageName]) {
        return;
    }
    
    UIView *pageView = [[UIView alloc] init];
    CGFloat viewHeight = 40;
    CGFloat viewY = self.pageViews.count * viewHeight + CGRectGetMaxY(headerImageView.frame) + 15;
    pageView.frame = CGRectMake(0, viewY, self.buttonsPanel.bounds.size.width, viewHeight);
    pageView.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:pageView.bounds];
    label.text = pageName;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    [pageView addSubview:label];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageViewTapped:)];
    [pageView addGestureRecognizer:tapGesture];
    
    [self.buttonsPanel addSubview:pageView];
    
    [self.pageViews addObject:pageView];
    self.pageViewsDict[pageName] = pageView;
   
    ScrollView *scrollView = [[ScrollView alloc] initWithFrame:self.contentPanel.bounds];
    [scrollView registerClass:[UIView class] forReuseIdentifier:@"Cell"];
    [self.pagesDict setObject:scrollView forKey:pageName];
    
    if (self.pagesDict.count == 1) {
        [self showPage:pageName animated:NO];
    }
}

- (ToggleSwitch *)addSwitchCellWithTitle:(NSString *)cellTitle toPage:(NSString *)pageName {
    NSString *switchKey = [NSString stringWithFormat:@"ToggleSwitch_%@", cellTitle];
    
    CGFloat switchWidth = 46;
    CGFloat switchHeight = 26;
    CGRect switchFrame = CGRectMake(0, 0, switchWidth, switchHeight);
    ToggleSwitch *toggleSwitch = [[ToggleSwitch alloc] initWithFrame:switchFrame andKey:switchKey];
    
    [self addCell:cellTitle toPage:pageName withView:toggleSwitch];

    return toggleSwitch;
}

- (Slider *)addSliderCellWithTitle:(NSString *)cellTitle toPage:(NSString *)pageName minValue:(float)min maxValue:(float)max {
    NSString *sliderKey = [NSString stringWithFormat:@"Slider_%@", cellTitle];

    CGFloat sliderHeight = 30;
    CGRect sliderFrame = CGRectMake(10, 30, self.contentPanel.bounds.size.width - 25, sliderHeight);
    Slider *slider = [[Slider alloc] initWithFrame:sliderFrame andKey:sliderKey];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = slider.value;

    [slider addTarget:self action:@selector(sliderValueChanged:)];

    [self addCell:cellTitle toPage:pageName withView:slider];

    for (UIView *subview in slider.superview.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *sliderValueLabel = (UILabel *)subview;
            sliderValueLabel.text = [NSString stringWithFormat:@"%@: %.3f", cellTitle, slider.value];

            objc_setAssociatedObject(slider, "sliderValueLabel", sliderValueLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(slider, "cellTitle", cellTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            break;
        }
    }
    return slider;
}

- (void)sliderValueChanged:(Slider *)sender {
    UILabel *sliderValueLabel = objc_getAssociatedObject(sender, "sliderValueLabel");
    UILabel *cellTitle = objc_getAssociatedObject(sender, "cellTitle");
    if (sliderValueLabel && cellTitle) {
        sliderValueLabel.text = [NSString stringWithFormat:@"%@: %.3f", cellTitle, sender.value];
    }
}

- (SegmentedControl *)addSegmentedControlCellWithTitle:(NSString *)cellTitle toPage:(NSString *)pageName items:(NSArray<NSString *> *)items {
    NSString *defaultsKey = [NSString stringWithFormat:@"SegmentedControl_%@", cellTitle];
    
    CGFloat controlHeight = 30;
    CGRect controlFrame = CGRectMake(0, 0, self.contentPanel.bounds.size.width - 25, controlHeight);
    SegmentedControl *segmentedControl = [[SegmentedControl alloc] initWithFrame:controlFrame items:items defaultsKey:defaultsKey];
    
    [self addCell:cellTitle toPage:pageName withView:segmentedControl];
    
    return segmentedControl;
}

- (void)addCell:(NSString *)cellTitle toPage:(NSString *)pageName withView:(UIView *)accessoryView {
    ScrollView *scrollView = self.pagesDict[pageName];
    if (!scrollView) {
        return;
    }
    
    UIView *cell = [scrollView dequeueReusableViewWithIdentifier:@"Cell"];
    
    CGFloat cellHeight = 50;
    if ([accessoryView isKindOfClass:[Slider class]] || [accessoryView isKindOfClass:[SegmentedControl class]]) {
        cellHeight = 60;
    }
    
    CGFloat currentContentHeight = 0;
    for (UIView *subview in scrollView.contentView.subviews) {
        currentContentHeight += subview.frame.size.height;
    }
    
    cell.frame = CGRectMake(0, currentContentHeight, scrollView.bounds.size.width, cellHeight);
    cell.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cell.bounds.size.width - 20, 30)];
    label.text = cellTitle;
    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    [cell addSubview:label];
    
    if ([accessoryView isKindOfClass:[Slider class]] || [accessoryView isKindOfClass:[SegmentedControl class]]) {
        CGFloat accessoryHeight = accessoryView.bounds.size.height;
        accessoryView.frame = CGRectMake(10, label.frame.size.height, cell.bounds.size.width - 25, accessoryHeight);
        [cell addSubview:accessoryView];
    } else if ([accessoryView isKindOfClass:[ToggleSwitch class]]) {
        label.frame = CGRectMake(10, 11, cell.bounds.size.width - 20, 30);
        CGFloat accessoryWidth = accessoryView.bounds.size.width;
        accessoryView.frame = CGRectMake(cell.bounds.size.width - accessoryWidth - 15, (cellHeight - accessoryView.bounds.size.height) / 2, accessoryWidth, accessoryView.bounds.size.height);
        [cell addSubview:accessoryView];
    }
    
    [scrollView.contentView addSubview:cell];
}

- (void)pageViewTapped:(UITapGestureRecognizer *)gestureRecognizer {
    UIView *tappedView = gestureRecognizer.view;
    NSString *pageName = nil;
    
    for (NSString *key in self.pageViewsDict) {
        if (self.pageViewsDict[key] == tappedView) {
            pageName = key;
            break;
        }
    }
    
    if (pageName) {
        [self showPage:pageName animated:NO];
    }
}

- (void)showPage:(NSString *)pageName animated:(BOOL)animated {
    if ([self.currentPageName isEqualToString:pageName]) {
        return;
    }
    
    ScrollView *newScrollView = self.pagesDict[pageName];
    if (!newScrollView) {
        return;
    }
    
    self.currentPageName = pageName;
    
    [self.contentPanel.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.contentPanel addSubview:newScrollView];
    
    [self updatePageViewStates];
}

- (void)updatePageViewStates {
    for (UIView *pageView in self.pageViews) {
        UILabel *label = pageView.subviews.firstObject;
        if ([label isKindOfClass:[UILabel class]]) {
            if ([label.text isEqualToString:self.currentPageName]) {
                pageView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
            } else {
                pageView.backgroundColor = [UIColor clearColor];
            }
        }
    }
}

- (void)handle {
    [UIView animateWithDuration:0.1 animations:^{
        if (self.alpha == 1.0) {
            self.transform = CGAffineTransformMakeScale(0.5, 0.5);
            self.alpha = 0.0;
        } else {
            self.transform = CGAffineTransformIdentity;
            self.alpha = 1.0;
        }
    }];
}

@end
