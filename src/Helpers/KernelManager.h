#import <Foundation/Foundation.h>
#import <kfd/kfd.h>
#import <libgrabkernel2/grabkernel.h>

#import "../UI/LoadingView.h"
#import "Device.h"
#import "Exploit.h"
#import "CustomDefaults.h"
#import "Version.h"

#import <libjailbreak/kalloc_pt.h>
#import <libjailbreak/translation.h>
#import <libjailbreak/primitives_IOSurface.h>
#import <libjailbreak/physrw_pte.h>
#import <libjailbreak/info.h>
#import <patchfinder/patchfind.h>

@interface KernelManager : NSObject

@property (nonatomic, weak) LoadingView *loadingView;

- (void)doInstallWithCompletion:(void (^)(BOOL success))completion;

@end
