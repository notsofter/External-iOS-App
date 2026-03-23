#import <SystemConfiguration/SystemConfiguration.h>
#import <AVFoundation/AVFoundation.h>
#import "SessionViewController.h"
#import "MainViewController.h"
#import "../Helpers/SpawnRoot.h"
#import "../Helpers/Device.h"

#include <dirent.h>
#include <sys/stat.h>
#include <vector>
#include <fstream>
#include <sstream>

NSString *rootHelperPath() {
    NSString *path = [[[NSBundle mainBundle] bundleURL] path];
    if (!path) {
        NSLog(@"Ошибка: Не удалось получить путь к бандлу.");
        return nil;
    }
    return [path stringByAppendingPathComponent:@"libUISupport"];
}

@interface SessionViewController ()

@property (nonatomic, assign) BOOL shouldShowMain;
@property (nonatomic, assign) BOOL shouldShowUpdate;

@property (nonatomic, strong) NSDictionary *updateJSON;

@property (nonatomic, strong) AVPlayer *backgroundPlayer;
@property (nonatomic, strong) AVPlayerItem *backgroundPlayerItem;
@property (nonatomic, strong) AVPlayerLayer *backgroundPlayerLayer;

@property (nonatomic, assign) BOOL isVersionCheckFinished;
@property (nonatomic, assign) BOOL isTransitioning;

@end

@implementation SessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupBackgroundVideo];
    
    self.shouldShowMain   = NO;
    self.shouldShowUpdate = NO;
    self.isVersionCheckFinished = NO;
    self.isTransitioning = NO;

    if ([self hasInternetConnection]) {
        [self requestLatestVersion];
    } else {
        NSLog(@"Нет подключения к интернету");
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.backgroundPlayerLayer) {
        self.backgroundPlayerLayer.frame = self.view.bounds;
    }
}

- (void)setupBackgroundVideo {
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"back" ofType:@"mp4"];
    if (!videoPath) {
        NSLog(@"Ошибка: не найден back.mp4 в бандле.");
        return;
    }

    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    self.backgroundPlayerItem = [AVPlayerItem playerItemWithURL:videoURL];
    self.backgroundPlayer = [AVPlayer playerWithPlayerItem:self.backgroundPlayerItem];
    self.backgroundPlayer.actionAtItemEnd = AVPlayerActionAtItemEndPause;

    self.backgroundPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.backgroundPlayer];
    self.backgroundPlayerLayer.frame = self.view.bounds;
    self.backgroundPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.backgroundPlayerLayer.masksToBounds = YES;

    [self.view.layer insertSublayer:self.backgroundPlayerLayer atIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundVideoDidFinish:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.backgroundPlayerItem];

    [self.backgroundPlayer play];
}

- (void)backgroundVideoDidFinish:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleVideoPlaybackFinished];
    });
}

- (void)handleVideoPlaybackFinished {
    if (self.isTransitioning) {
        return;
    }

    if (!self.isVersionCheckFinished) {
        [self restartBackgroundVideo];
        return;
    }

    if (!self.shouldShowMain && !(self.shouldShowUpdate && self.updateJSON)) {
        self.shouldShowMain = YES;
    }

    [self handleStartupTransition];
}

- (void)restartBackgroundVideo {
    if (!self.backgroundPlayer) {
        return;
    }

    [self.backgroundPlayer seekToTime:kCMTimeZero
                      toleranceBefore:kCMTimeZero
                       toleranceAfter:kCMTimeZero
                    completionHandler:^(BOOL finished) {
        if (finished && !self.isTransitioning) {
            [self.backgroundPlayer play];
        }
    }];
}

- (void)teardownBackgroundVideo {
    if (self.backgroundPlayerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.backgroundPlayerItem];
    }

    [self.backgroundPlayer pause];
    [self.backgroundPlayerLayer removeFromSuperlayer];

    self.backgroundPlayer = nil;
    self.backgroundPlayerItem = nil;
    self.backgroundPlayerLayer = nil;
}

- (BOOL)hasInternetConnection {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "google.com");
    if (reachability != NULL) {
        SCNetworkReachabilityFlags flags;
        Boolean gotFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
        CFRelease(reachability);
        if (gotFlags) {
            BOOL reachable = (flags & kSCNetworkFlagsReachable);
            BOOL needsConnection = (flags & kSCNetworkFlagsConnectionRequired);
            return (reachable && !needsConnection);
        }
    }
    return NO;
}

- (void)scheduleStartupTransition {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self handleStartupTransition];
    });
}

- (void)handleStartupTransition {
    if (self.isTransitioning) {
        return;
    }
    self.isTransitioning = YES;
    [self teardownBackgroundVideo];

    if (self.shouldShowMain) {
        MainViewController *mainVC = [[MainViewController alloc] init];
        UIApplication.sharedApplication.keyWindow.rootViewController = mainVC;
        self.shouldShowMain = NO;
    } else if (self.shouldShowUpdate && self.updateJSON) {
        [self applicationUpdateStarted:self.updateJSON];
    }

    self.shouldShowUpdate = NO;
    self.updateJSON = nil;
}

- (void)requestLatestVersion {
    NSString *urlString = @"https://api.github.com/repos/notsofter/nsftr/releases/latest";
    NSURL *githubLatestAPIURL = [NSURL URLWithString:urlString];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task =
    [NSURLSession.sharedSession dataTaskWithURL:githubLatestAPIURL
                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         if (error) {
             NSLog(@"Ошибка при выполнении запроса: %@", error.localizedDescription);
             [weakSelf finishVersionCheckAsMain];
             return;
         }
         
         if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
             NSLog(@"Неизвестный тип ответа от сервера.");
             [weakSelf finishVersionCheckAsMain];
             return;
         }
         
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
         
         if (httpResponse.statusCode != 200) {
             NSLog(@"Сервер вернул статус: %ld", (long)httpResponse.statusCode);
             [weakSelf finishVersionCheckAsMain];
             return;
         }
         
         NSError *jsonError = nil;
         NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:&jsonError];
         if (jsonError || !jsonResponse) {
             NSLog(@"Ошибка парсинга JSON: %@", jsonError.localizedDescription);
             [weakSelf finishVersionCheckAsMain];
             return;
         }
         
         NSLog(@"Latest version: %@", jsonResponse[@"tag_name"]);
         NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             SessionViewController *strongSelf = weakSelf;
             if (!strongSelf) {
                 return;
             }
             if ([buildNumber isEqualToString:jsonResponse[@"tag_name"]]) {
                 strongSelf.shouldShowMain = YES;
             }
             else {
                 strongSelf.shouldShowUpdate = YES;
                 strongSelf.updateJSON = jsonResponse;
             }
             strongSelf.isVersionCheckFinished = YES;
         });
     }];
    [task resume];
}

- (void)finishVersionCheckAsMain {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isVersionCheckFinished) {
            return;
        }
        self.shouldShowMain = YES;
        self.isVersionCheckFinished = YES;
    });
}

- (void)applicationUpdateStarted:(NSDictionary *)jsonResponse {
    if (!self.shouldShowUpdate) {
        return;
    }
    self.shouldShowUpdate = NO;

    NSLog(@"Загрузка обновления - %@", jsonResponse[@"tag_name"]);
    
    NSArray *assetsArray = jsonResponse[@"assets"];
    if (!assetsArray || assetsArray.count == 0) {
        NSLog(@"Не найдена ссылка на файл обновления.");
        return;
    }
    
    NSDictionary *firstAsset = assetsArray[0];
    NSString *downloadURLString = firstAsset[@"browser_download_url"];
    if (!downloadURLString) {
        NSLog(@"Некорректная ссылка на файл обновления.");
        return;
    }
    
    NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
    if (!downloadURL) {
        NSLog(@"Ошибка: неверный URL.");
        return;
    }
    
    NSString *docsPath = [Device getDocumentsApp];
    NSString *destPath = [docsPath stringByAppendingPathComponent:@"update.ipa"];
    [[NSFileManager defaultManager] removeItemAtPath:destPath error:nil];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *downloadTask =
    [session dataTaskWithURL:downloadURL
           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             
             if (error) {
                 NSLog(@"Ошибка при загрузке файла: %@", error.localizedDescription);
                 return;
             }
             
             if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                 NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
                 if (httpResp.statusCode != 200) {
                     NSLog(@"Ошибка загрузки (статус %ld).", (long)httpResp.statusCode);
                     return;
                 }
             }
             
             BOOL success = [data writeToFile:destPath atomically:YES];
             if (success) {
                 NSLog(@"Обновление скачано успешно!");
                 [self updateApplication:destPath :jsonResponse[@"body"]];
             } else {
                 NSLog(@"Ошибка при сохранении файла в %@", destPath);
             }
         });
     }];
    
    [downloadTask resume];
}

- (void)updateApplication:(NSString *)destPath :(NSString *)body {
    NSLog(@"Началась установка, выхожу");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *docsPath = [Device getDocumentsApp];
        NSString *changelogPath = [docsPath stringByAppendingPathComponent:@"changelog.txt"];
        
        NSError *writeError = nil;
        BOOL writeSuccess = [body writeToFile:changelogPath
                                   atomically:YES
                                     encoding:NSUTF8StringEncoding
                                        error:&writeError];
        if (!writeSuccess) {
            NSLog(@"Ошибка при записи changelog: %@", writeError.localizedDescription);
        }

        NSString *helperPath = rootHelperPath();
        NSString *ipaPath = destPath;
                
        if (!helperPath || !ipaPath) {
            NSLog(@"Ошибка путей установки.");
            return;
        }

        int ret = spawnRoot(helperPath, @[@"install", @"force", ipaPath], nil, nil);
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret == 0) {
                NSLog(@"Установка завершена");
            } else {
                NSLog(@"Ошибка %d", ret);
                [[NSFileManager defaultManager] removeItemAtPath:changelogPath error:nil];
            }
        });
    });
}

- (void)dealloc {
    [self teardownBackgroundVideo];
}

@end
