#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <IOKit/IOKitLib.h>
#import "Version.h"

typedef NS_ENUM(NSUInteger, CPUFamily) {
    CPUFamilyUnknown,
    CPUFamilyA8,
    CPUFamilyA9,
    CPUFamilyA10,
    CPUFamilyA11,
    CPUFamilyA12,
    CPUFamilyA13,
    CPUFamilyA14,
    CPUFamilyA15,
    CPUFamilyA16,
};

@interface Device : NSObject

@property (nonatomic, strong) Version *version;
@property (nonatomic, assign) BOOL isArm64e;
@property (nonatomic, assign) BOOL supportsOTA;
@property (nonatomic, assign) BOOL isSupported;
@property (nonatomic, assign) BOOL isOnSupported17Beta;
@property (nonatomic, assign) CPUFamily cpuFamily;

- (instancetype)init;
- (NSString *)modelIdentifier;
- (BOOL)supportsDirectInstall;
+ (NSString *)getDocumentsApp;
@end
