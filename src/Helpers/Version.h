#import <Foundation/Foundation.h>

@interface Version : NSObject
@property (nonatomic, assign) int major;
@property (nonatomic, assign) int minor;
@property (nonatomic, strong) NSNumber *patch;

- (instancetype)initWithMajor:(int)major minor:(int)minor patch:(NSNumber *)patch;
- (instancetype)initWithVersionString:(NSString *)version;
- (NSString *)readableString;
- (NSComparisonResult)compare:(Version *)other;

@end