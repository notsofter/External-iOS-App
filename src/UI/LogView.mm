#import "LogView.h"

@implementation LogView {
  NSMutableArray *logArray;
  unsigned int maxLines;
}

- (id)initWithFrame:(CGRect)frame maxLines:(unsigned int)_maxLines
{
    self = [super initWithFrame:frame];
    self->maxLines = _maxLines;
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{    
    UIEdgeInsets logViewInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0); //top, left, bottom, right
    self.contentInset = logViewInsets;
    self.scrollIndicatorInsets = logViewInsets;

    self.font = [UIFont systemFontOfSize:14.0];
    self.backgroundColor = [UIColor clearColor];
    self.textColor = [UIColor redColor];
    self.scrollEnabled = NO;
    self.alwaysBounceVertical = NO;
    self.editable = NO;
    self.clipsToBounds = YES;
    [self setUserInteractionEnabled:NO];
    logArray = [[NSMutableArray alloc]init];
}

-(void)log:(NSString*)string {
    [logArray addObject:string];
    if ([logArray count] > maxLines) {
        [logArray removeObjectAtIndex:1];
    }
    [self updateText];
}

-(void)updateText {
    self.text = @"";
    for (unsigned int i = 0; i < [logArray count]; i++) {
        self.text = [NSString stringWithFormat:@"%@\n%@", self.text, [logArray objectAtIndex:i]];
    }
}

-(void)clear {
[logArray removeAllObjects];
[self updateText];
}

@end
