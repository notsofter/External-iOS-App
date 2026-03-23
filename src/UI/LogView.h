// Copyright (c) 2019 bR34Kr
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface LogView : UITextView

- (id)initWithFrame:(CGRect)frame maxLines:(unsigned int)_maxLines;
- (void)setup;
-(void)log:(NSString*)string;
-(void)updateText;
-(void)clear;

@end