#import <Foundation/Foundation.h>

@interface CustomDefaults : NSObject

+ (instancetype)sharedInstance;

- (void)setCustomPath:(NSString *)path;

- (void)saveString:(NSString *)value forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

- (void)saveInteger:(NSInteger)value forKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;

- (void)saveFloat:(float)value forKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;

@end
