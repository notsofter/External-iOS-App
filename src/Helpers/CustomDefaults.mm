#import "CustomDefaults.h"

@interface CustomDefaults ()

@property (nonatomic, strong) NSMutableDictionary *storage;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation CustomDefaults

+ (instancetype)sharedInstance {
    static CustomDefaults *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"cfg.json"];
        _storage = [self loadFromDisk];
        if (!_storage) {
            _storage = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

- (void)setCustomPath:(NSString *)path {
    if (path && ![path isEqualToString:@""]) {
        _filePath = [path stringByAppendingPathComponent:@"cfg.json"];
        _storage = [self loadFromDisk];
        if (!_storage) {
            _storage = [NSMutableDictionary dictionary];
        }
    }
}

- (void)saveString:(NSString *)value forKey:(NSString *)key {
    [self.storage setObject:value forKey:key];
    [self saveToDisk];
}

- (NSString *)stringForKey:(NSString *)key {
    return [self.storage objectForKey:key];
}

- (void)saveInteger:(NSInteger)value forKey:(NSString *)key {
    [self.storage setObject:@(value) forKey:key];
    [self saveToDisk];
}

- (NSInteger)integerForKey:(NSString *)key {
    return [[self.storage objectForKey:key] integerValue];
}

- (void)saveFloat:(float)value forKey:(NSString *)key {
    [self.storage setObject:@(value) forKey:key];
    [self saveToDisk];
}

- (float)floatForKey:(NSString *)key {
    return [[self.storage objectForKey:key] floatValue];
}

- (void)saveToDisk {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.storage
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (jsonData) {
        [jsonData writeToFile:self.filePath atomically:YES];
    }
}

- (NSMutableDictionary *)loadFromDisk {
    NSData *data = [NSData dataWithContentsOfFile:self.filePath];
    if (data) {
        NSError *error;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&error];
        if (!error && [jsonDict isKindOfClass:[NSMutableDictionary class]]) {
            return jsonDict;
        }
    }
    return nil;
}

@end
