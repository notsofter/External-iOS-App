#import "KernelManager.h"

void post_kernel_exploit(bool iOS14) {
    if (!iOS14) {
        jbinfo_initialize_boot_constants();
    }
    libjailbreak_translation_init();
    libjailbreak_IOSurface_primitives_init();
}

bool build_physrw_primitive(void) {
    int r = libjailbreak_physrw_pte_init(false);
    return r == 0;
}

@implementation KernelManager {
    NSString *kernelPath;
    Device *device;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        device = [[Device alloc] init];
        kernelPath = [[Device getDocumentsApp] stringByAppendingPathComponent:@"cache"];
    }
    return self;
}

- (void)doInstallWithCompletion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [self doDirectInstall];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success);
        });
    });
}

- (BOOL)getKernel:(Device *)device {
    if (![[NSFileManager defaultManager] fileExistsAtPath:kernelPath]) {
        NSString *bundleKernelPath = [[NSBundle mainBundle] pathForResource:@"cache" ofType:nil];
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundleKernelPath]) {
            NSError *error;
            [[NSFileManager defaultManager] copyItemAtPath:bundleKernelPath toPath:kernelPath error:&error];
            if (error) {
                [self updateStatus:@"Error 101"];
                return NO;
            }
        }
        [self updateStatus:@"Loading"];
        if (!grab_kernelcache(kernelPath)) {
            [self updateStatus:@"Error 102"];
            return NO;
        }
    }
    return YES;
}

- (KernelExploit *)getExploit {
    NSString *flavour = [[CustomDefaults sharedInstance] stringForKey:@"method"];

    if ([flavour isEqualToString:@"landa"]) return landa;
    else if ([flavour isEqualToString:@"smith"]) return smith;
    else if ([flavour isEqualToString:@"physpuppet"]) return physpuppet;
}

- (BOOL)doDirectInstall {
    KernelExploit *exploit = [self getExploit];

    BOOL iOS14 = [device.version compare:[[Version alloc] initWithVersionString:@"15.0"]] == NSOrderedAscending;

    BOOL supportsFullPhysRW = !(device.cpuFamily == 0x2C91A47E && [device.version compare:[[Version alloc] initWithVersionString:@"15.1.1"]] == NSOrderedDescending)
        && ((device.isArm64e && [device.version compare:[[Version alloc] initWithMajor:15 minor:2 patch:nil]] != NSOrderedAscending)
        || (!device.isArm64e && [device.version compare:[[Version alloc] initWithVersionString:@"15.0"]] != NSOrderedAscending));

    if (!iOS14) {
        if (![self getKernel:device]) {
            [self updateStatus:@"Error 103"];
            return NO;
        }
    }

    [self updateStatus:@"Initializing"];
    if (!initialise_kernel_info(kernelPath.UTF8String, iOS14)) {
        [self updateStatus:@"Error 104"];
        return NO;
    }

    [self updateStatus:[NSString stringWithFormat:@"%@", exploit.name]];

    if (!exploit.initialise()) {
        [self updateStatus:@"Error 105"];
        return NO;
    }
    [self updateStatus:@"Initialized"];

    post_kernel_exploit(iOS14);

    if (supportsFullPhysRW) {
        if (device.isArm64e) {
            [self updateStatus:[NSString stringWithFormat:@"Bypassing"]];
            if (!dmaFail.initialise()) {
                [self updateStatus:@"Error 106"];
                return NO;
            }
        }

        if (@available(iOS 16, *)) {
            libjailbreak_kalloc_pt_init();
        }

        if (!build_physrw_primitive()) {
            [self updateStatus:@"Error 107"];
            return NO;
        }

        if (device.isArm64e) {
            [self updateStatus:[NSString stringWithFormat:@"Remove"]];
            if (!dmaFail.deinitialise()) {
                [self updateStatus:[NSString stringWithFormat:@"Error 108"]];
                return NO;
            }
        }
    }

    [self updateStatus:[NSString stringWithFormat:@"Clear"]];
    if (!exploit.deinitialise()) {
        [self updateStatus:[NSString stringWithFormat:@"Error 109"]];
        return NO;
    }

    [self updateStatus:@"Success"];
    [self.loadingView showCheckmark];
    
    return YES;
}

- (void)updateStatus:(NSString *)message {
    [self.loadingView setStatusText:message];
}

@end
