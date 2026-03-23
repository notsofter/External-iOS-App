#import "Device.h"

@implementation Device

- (instancetype)init {
    self = [super init];
    if (self) {
        _version = [[Version alloc] initWithVersionString:[[UIDevice currentDevice] systemVersion]];
        
        // Check if arm64e
        int32_t cpusubtype = 0;
        size_t len = sizeof(cpusubtype);
        sysctlbyname("hw.cpusubtype", &cpusubtype, &len, NULL, 0);
        _isArm64e = cpusubtype == CPU_SUBTYPE_ARM64E;
        
        // Check if device supports TrollHelperOTA
        if (_isArm64e) {
            _supportsOTA = [_version compare:[[Version alloc] initWithVersionString:@"15.7"]] == NSOrderedAscending;
        } else {
            _supportsOTA = ([_version compare:[[Version alloc] initWithVersionString:@"15.0"]] != NSOrderedAscending) &&
                           ([_version compare:[[Version alloc] initWithVersionString:@"15.5"]] == NSOrderedAscending);
        }

        // Set the CPU family
        uint32_t deviceCPU = 0;
        len = sizeof(deviceCPU);
        sysctlbyname("hw.cpufamily", &deviceCPU, &len, NULL, 0);
        
        switch (deviceCPU) {
            case 0x2C91A47E:
                _cpuFamily = CPUFamilyA8;
                break;
            case 0x92FB37C8:
                _cpuFamily = CPUFamilyA9;
                break;
            case 0x67CEEE93:
                _cpuFamily = CPUFamilyA10;
                break;
            case 0xE81E7EF6:
                _cpuFamily = CPUFamilyA11;
                break;
            case 0x07D34B9F:
                _cpuFamily = CPUFamilyA12;
                break;
            case 0x462504D2:
                _cpuFamily = CPUFamilyA13;
                break;
            case 0x1B588BB3:
                _cpuFamily = CPUFamilyA14;
                break;
            case 0xDA33D83D:
                _cpuFamily = CPUFamilyA15;
                break;
            case 0x8765EDEA:
                _cpuFamily = CPUFamilyA16;
                break;
            default:
                _cpuFamily = CPUFamilyUnknown;
                break;
        }
        
        // Check build number
        char buildNumber[256];
        len = sizeof(buildNumber);
        sysctlbyname("kern.osversion", buildNumber, &len, NULL, 0);
        NSString *buildNumberStr = [NSString stringWithCString:buildNumber encoding:NSUTF8StringEncoding];
        
        NSArray *supportedBuildNumbers = @[@"21A5248v", @"21A5268h", @"21A5277j", @"21A5291h", @"21A5291j"];
        _isOnSupported17Beta = [supportedBuildNumbers containsObject:buildNumberStr];
        
        BOOL isM2 = NO;
        io_registry_entry_t registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen");
        CFDataRef chipIDData = (CFDataRef)IORegistryEntryCreateCFProperty(registryEntry, CFSTR("chip-id"), kCFAllocatorDefault, 0);
        
        if (chipIDData) {
            const int *chipID = (const int *)CFDataGetBytePtr(chipIDData);
            isM2 = *chipID == 0x8112;
            CFRelease(chipIDData);
        }
        
        if (_cpuFamily == CPUFamilyA8) {
            _isSupported = [_version compare:[[Version alloc] initWithVersionString:@"15.2"]] == NSOrderedAscending;
        } else {
            _isSupported = ([_version compare:[[Version alloc] initWithVersionString:@"16.6.1"]] != NSOrderedDescending) ||
                            (_isOnSupported17Beta && !((_cpuFamily == CPUFamilyA15 && !isM2) || _cpuFamily == CPUFamilyA16));
        }
    }
    return self;
}

- (NSString *)modelIdentifier {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

- (BOOL)supportsDirectInstall {
    if (!_isArm64e) return YES;
    if (_cpuFamily == CPUFamilyA15 || _cpuFamily == CPUFamilyA16) {
        return [_version compare:[[Version alloc] initWithVersionString:@"16.5.1"]] == NSOrderedAscending;
    } else {
        return [_version compare:[[Version alloc] initWithVersionString:@"16.6"]] == NSOrderedAscending;
    }
}

+ (NSString *)getDocumentsApp {
    NSString *path = @"/private/var/mobile/Containers/Data/Application/";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *appDirectories = [fileManager contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        return nil;
    }
    
    for (NSString *appDir in appDirectories) {
        NSString *fullPath = [NSString stringWithFormat:@"%@%@/.com.apple.mobile_container_manager.metadata.plist", path, appDir];
        NSDictionary *metadata = [NSDictionary dictionaryWithContentsOfFile:fullPath];
        
        if ([metadata isKindOfClass:[NSDictionary class]]) {
            NSString *bundleID = metadata[@"MCMMetadataIdentifier"];
            
            if ([bundleID isKindOfClass:[NSString class]] && [bundleID isEqualToString:@"gh.notsofter"]) {
                return [NSString stringWithFormat:@"%@%@/Documents", path, appDir];
            }
        }
    }
    
    return nil;
}

@end
