#ifdef __cplusplus
extern "C" {
#endif

@import Foundation;
#import <CoreServices/LSApplicationProxy.h>
#define TrollStoreErrorDomain @"TrollStoreErrorDomain"

void chineseWifiFixup(void);
void loadMCMFramework(void);
NSString* safe_getExecutablePath();
NSString* getNSStringFromFile(int fd);
void printMultilineNSString(NSString* stringToPrint);
int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
void killall(NSString* processName);
void respring(void);
char* getPatchedLaunchdCopy(void);
char* return_boot_manifest_hash_main(void);

#ifdef __cplusplus
}
#endif