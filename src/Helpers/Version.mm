#import "Version.h"

@implementation Version

- (instancetype)initWithMajor:(int)major minor:(int)minor patch:(NSNumber *)patch {
    self = [super init];
    if (self) {
        _major = major;
        _minor = minor;
        _patch = patch;
    }
    return self;
}

- (instancetype)initWithVersionString:(NSString *)version {
    NSArray *components = [version componentsSeparatedByString:@"."];
    int major = [components[0] intValue];
    int minor = [components[1] intValue];
    NSNumber *patch = nil;
    if (components.count == 3) {
        patch = @([components[2] intValue]);
    }
    return [self initWithMajor:major minor:minor patch:patch];
}

- (NSString *)readableString {
    if (self.patch) {
        return [NSString stringWithFormat:@"%d.%d.%@", self.major, self.minor, self.patch];
    } else {
        return [NSString stringWithFormat:@"%d.%d", self.major, self.minor];
    }
}

- (NSComparisonResult)compare:(Version *)other {
    if (self.major < other.major) return NSOrderedAscending;
    if (self.major > other.major) return NSOrderedDescending;
    if (self.minor < other.minor) return NSOrderedAscending;
    if (self.minor > other.minor) return NSOrderedDescending;
    if (self.patch && other.patch) {
        return [self.patch compare:other.patch];
    }
    if (self.patch && !other.patch) return NSOrderedDescending;
    if (!self.patch && other.patch) return NSOrderedAscending;
    return NSOrderedSame;
}

@end