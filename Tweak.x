#import "TikTokHeaders.h"
#import <objc/runtime.h>

// ==========================================
// 全局定义与辅助宏
// ==========================================

NSArray *jailbreakPaths;
static BOOL globalElementsHidden = NO;

// 弱引用宏
#ifndef WEAKify
#define WEAKify(var) __weak typeof(var) AHKWeak_##var = var;
#endif

#ifndef STRONGify
#define STRONGify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = AHKWeak_##var; \
_Pragma("clang diagnostic pop")
#endif

// ==========================================
// 接口声明 (修复编译错误的关键部分)
// ==========================================

// 注意：已移除 AWEAwemePlayInteractionView 的定义以修复 duplicate interface 错误

// 如果 TikTokHeaders.h 中没有包含以下类的完整定义，保留这些声明
@interface AWEVideoPlayViewController : UIViewController
@end

@interface AWEVideoPlayerController : UIViewController
@end

@interface AWEVideoPlayerView : UIView
@end

@interface AWEVideoDetailViewController : UIViewController
@end

// 声明新增的方法，解决 "no visible @interface" 报错
@interface AWEFeedViewTemplateCell (BHTikTokAdditions)
- (void)setupCustomButtons;
- (void)downloadButtonHandler:(UIButton *)sender;
- (void)hideElementButtonHandler:(UIButton *)sender;
- (void)downloadVideo:(id)rootVC;
- (void)downloadHDVideo:(id)rootVC;
- (void)downloadMusic:(id)rootVC;
- (void)copyVideo:(id)rootVC;
- (void)startDownload:(NSURL *)url;
@end

// 修复：补全 AWEAwemeDetailTableViewCell 的方法声明
@interface AWEAwemeDetailTableViewCell (BHTikTokAdditions)
- (void)setupCustomButtons;
- (void)downloadButtonHandler:(UIButton *)sender;
- (void)downloadVideo:(id)rootVC;    // 新增
- (void)startDownload:(NSURL *)url;  // 新增
@end

// 现有 Category 声明
@interface UIViewController (BHTikTokAdditions)
- (AWEAwemeModel *)model;
- (AWEAwemeModel *)currentAwemeModel;
- (AWEAwemeBaseViewController *)viewController;
@end

@interface NSObject (BHTikTokAdditions)
- (void)updateVideoModels;
@end

// ==========================================
// 辅助函数
// ==========================================

static UIViewController *topMostController() {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

static void showAlert(NSString *title, NSString *message, NSString *okTitle, NSString *cancelTitle, void (^okHandler)(void)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class alertViewClass = NSClassFromString(@"AWEUIAlertView");
        if (alertViewClass && [alertViewClass respondsToSelector:@selector(showAlertWithTitle:description:image:actionButtonTitle:cancelButtonTitle:actionBlock:cancelBlock:)]) {
            [alertViewClass showAlertWithTitle:title description:message image:nil actionButtonTitle:okTitle cancelButtonTitle:cancelTitle actionBlock:okHandler ? ^{ okHandler(); } : nil cancelBlock:nil];
        } else {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            if (cancelTitle) {
                [ac addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:nil]];
            }
            [ac addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                if (okHandler) okHandler();
            }]];
            [topMostController() presentViewController:ac animated:YES completion:nil];
        }
    });
}

static void showConfirmation(void (^okHandler)(void)) {
    showAlert([BHIManager L:@"BHTikTok, Hi"], [BHIManager L:@"Are you sure?"], [BHIManager L:@"Yes"], [BHIManager L:@"No"], okHandler);
}

// 核心逻辑：获取当前 View 对应的视频数据模型
static AWEAwemeModel *getCurrentVideoModel(UIView *view) {
    AWEAwemeModel *model = objc_getAssociatedObject(view, "currentVideoModel");
    if (model) return model;
    
    UIViewController *vc = [view yy_viewController];
    if (vc) {
        if ([vc respondsToSelector:@selector(currentAwemeModel)]) model = [vc currentAwemeModel];
        else if ([vc respondsToSelector:@selector(model)]) model = [vc model];
        
        if (!model) model = objc_getAssociatedObject(vc, "currentVideoModel");
    }
    return model;
}

static void updateInteractionViewModel(UIView *view, AWEAwemeModel *model) {
    if (!model || !view) return;
    objc_setAssociatedObject(view, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if ([BHIManager videoUploadDate]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [view setNeedsLayout];
        });
    }
}

// ==========================================
// App 生命周期与初始化 Hook
// ==========================================
%hook AppDelegate

- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedLanguage = [defaults objectForKey:@"BHTikTok_Language"];
    
    if (!savedLanguage) {
        NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
        NSString *systemLanguage = languages.firstObject;
        savedLanguage = [systemLanguage hasPrefix:@"zh"] ? @"zh-Hans" : @"en";
        [defaults setObject:savedLanguage forKey:@"BHTikTok_Language"];
        [defaults synchronize];
    }
    
    [self applyLanguageSetting:savedLanguage];
    
    if (![defaults objectForKey:@"BHTikTokFirstRun"]) {
        [defaults setValue:@"BHTikTokFirstRun" forKey:@"BHTikTokFirstRun"];
        [defaults setBool:true forKey:@"hide_ads"];
        [defaults setBool:true forKey:@"download_button"];
        [defaults setBool:true forKey:@"remove_elements_button"];
        [defaults setBool:true forKey:@"show_porgress_bar"];
        [defaults setBool:true forKey:@"save_profile"];
        [defaults setBool:true forKey:@"copy_profile_information"];
        [defaults setBool:true forKey:@"extended_bio"];
        [defaults setBool:true forKey:@"extendedComment"];
    }
    
    [BHIManager cleanCache];
    
    if ([defaults boolForKey:@"flex_enebaled"]) {
        [[%c(FLEXManager) performSelector:@selector(sharedManager)] performSelector:@selector(showExplorer)];
    }
    
    return %orig;
}

%new - (void)applyLanguageSetting:(NSString *)language {
    [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"BHTikTok_Language"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSBundle mainBundle] localizedStringForKey:@"" value:@"" table:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LanguageChanged" object:language];
}

static BOOL isAuthenticationShowed = FALSE;

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    if ([BHIManager appLock] && !isAuthenticationShowed) {
        UIViewController *rootController = [[self window] rootViewController];
        SecurityViewController *securityViewController = [SecurityViewController new];
        securityViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [rootController presentViewController:securityViewController animated:YES completion:nil];
        isAuthenticationShowed = TRUE;
    }
}

- (void)applicationWillEnterForeground:(id)arg1 {
    %orig;
    isAuthenticationShowed = FALSE;
}
%end

// ==========================================
// 播放速度控制
// ==========================================
%hook TTKMediaSpeedControlService
- (void)setPlaybackRate:(CGFloat)arg1 {
    if ([BHIManager speedEnabled]) {
        NSNumber *speed = [BHIManager selectedSpeed];
        if (speed && ![speed isEqualToNumber:@1]) {
            return %orig([speed floatValue]);
        }
    }
    return %orig;
}
%end

// ==========================================
// 个人主页/视频列表显示上传日期和点赞
// ==========================================
%hook AWEUserWorkCollectionViewCell
- (void)configWithModel:(id)arg1 isMine:(BOOL)arg2 {
    %orig;
    
    if (![BHIManager videoUploadDate]) return;

    AWEAwemeModel *model = [self model];
    if (!model) return;
    
    UILabel *likeCountLabel = [self.contentView viewWithTag:1001];
    UILabel *uploadDateLabel = [self.contentView viewWithTag:1002];
    UIImageView *heartImage = [self.contentView viewWithTag:1003];
    UIImageView *clockImage = [self.contentView viewWithTag:1004];

    NSNumber *createTime = [model createTime] ?: [model valueForKey:@"createTimeFromServer"];
    if (!createTime) return;

    if (!uploadDateLabel) {
        if ([BHIManager videoLikeCount]) {
            heartImage = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart"]];
            heartImage.tintColor = [UIColor whiteColor];
            heartImage.tag = 1003;
            heartImage.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:heartImage];
            
            likeCountLabel = [UILabel new];
            likeCountLabel.textColor = [UIColor whiteColor];
            likeCountLabel.font = [UIFont boldSystemFontOfSize:13.0];
            likeCountLabel.tag = 1001;
            likeCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView addSubview:likeCountLabel];
        }

        clockImage = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"clock"]];
        clockImage.tintColor = [UIColor whiteColor];
        clockImage.tag = 1004;
        clockImage.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:clockImage];

        uploadDateLabel = [UILabel new];
        uploadDateLabel.textColor = [UIColor whiteColor];
        uploadDateLabel.font = [UIFont boldSystemFontOfSize:13.0];
        uploadDateLabel.tag = 1002;
        uploadDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:uploadDateLabel];
        
        CGFloat baseTop = 110;
        if ([BHIManager videoLikeCount]) {
             [NSLayoutConstraint activateConstraints:@[
                [heartImage.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:baseTop],
                [heartImage.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:4],
                [heartImage.widthAnchor constraintEqualToConstant:16],
                [heartImage.heightAnchor constraintEqualToConstant:16],
                
                [likeCountLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:baseTop-1],
                [likeCountLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:23],
                [likeCountLabel.widthAnchor constraintEqualToConstant:200],
                [likeCountLabel.heightAnchor constraintEqualToConstant:16]
            ]];
            baseTop += 18;
        }
        
        [NSLayoutConstraint activateConstraints:@[
            [clockImage.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:baseTop],
            [clockImage.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:4],
            [clockImage.widthAnchor constraintEqualToConstant:16],
            [clockImage.heightAnchor constraintEqualToConstant:16],
            
            [uploadDateLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:baseTop-1],
            [uploadDateLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:23],
            [uploadDateLabel.widthAnchor constraintEqualToConstant:200],
            [uploadDateLabel.heightAnchor constraintEqualToConstant:16]
        ]];
    }

    if ([BHIManager videoLikeCount]) {
        NSNumber *likeCount = [[model statistics] diggCount];
        likeCountLabel.text = [self formattedNumber:[likeCount integerValue]];
    }
    
    NSString *formattedDate = [self formattedDateStringFromTimestamp:[createTime doubleValue]];
    uploadDateLabel.text = formattedDate;
}

%new - (NSString *)formattedNumber:(NSInteger)number {
    if (number >= 1000000) return [NSString stringWithFormat:@"%.1fm", number / 1000000.0];
    if (number >= 1000) return [NSString stringWithFormat:@"%.1fk", number / 1000.0];
    return [NSString stringWithFormat:@"%ld", (long)number];
}

%new - (NSString *)formattedDateStringFromTimestamp:(NSTimeInterval)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd"; 
    return [dateFormatter stringFromDate:date];
}
%end

// ==========================================
// 自动播放与自动滑动
// ==========================================
%hook AWEPlayVideoPlayerController

- (void)playerWillLoopPlaying:(id)arg1 {
    if ([BHIManager autoPlay]) {
        UIViewController *parentVC = self.container.parentViewController;
        if ([parentVC isKindOfClass:%c(AWENewFeedTableViewController)]) {
            [(AWENewFeedTableViewController *)parentVC scrollToNextVideo];
            return;
        }
    }
    %orig;
}

- (void)playerDidPlayToEnd:(id)arg1 {
    if ([BHIManager autoPlay]) {
        UIViewController *targetVC = nil;
        if ([self.container.parentViewController isKindOfClass:%c(AWENewFeedTableViewController)]) {
            targetVC = self.container.parentViewController;
        }
        
        if (!targetVC && self.container) {
            UIResponder *next = self.container.nextResponder;
            while (next) {
                if ([next isKindOfClass:%c(AWENewFeedTableViewController)]) {
                    targetVC = (UIViewController *)next;
                    break;
                }
                next = next.nextResponder;
            }
        }
        
        if (targetVC) {
            [(AWENewFeedTableViewController *)targetVC scrollToNextVideo];
            return;
        }
    }
    %orig;
}

- (void)containerDidFullyDisplayWithReason:(NSInteger)arg1 {
    if ([[[self container] parentViewController] isKindOfClass:%c(AWENewFeedTableViewController)] && [BHIManager skipRecommendations]) {
        AWENewFeedTableViewController *rootVC = [[self container] parentViewController];
        AWEAwemeModel *currentModel = [rootVC currentAweme];
        if ([currentModel isUserRecommendBigCard]) {
            [rootVC scrollToNextVideo];
        }
    } else {
        %orig;
    }
}
%end

// ==========================================
// IP 属地显示
// ==========================================
static NSMutableDictionary *countryNameCache = nil;

static NSString *getCountryNameForCode(NSString *countryCode) {
    if (!countryCode || countryCode.length == 0) return nil;
    if (!countryNameCache) countryNameCache = [NSMutableDictionary dictionary];
    
    if (countryNameCache[countryCode]) return countryNameCache[countryCode];
    
    NSLocale *chineseLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    NSString *name = [chineseLocale displayNameForKey:NSLocaleCountryCode value:countryCode];
    
    if (!name) {
        name = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
    }
    
    NSString *result = name ?: countryCode;
    countryNameCache[countryCode] = result;
    return result;
}

%hook AWEPlayInteractionAuthorView
- (void)layoutSubviews {
    %orig;
    if (![BHIManager uploadRegion]) return;
    
    BOOL adjusted = NO;
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UIStackView class]]) {
            CGRect frame = sub.frame;
            if (frame.origin.x != 39.5) {
                frame.origin.x = 39.5;
                sub.frame = frame;
                adjusted = YES;
            }
        }
    }
    
    UILabel *regionLabel = [self viewWithTag:666];
    if (regionLabel && !adjusted && regionLabel.text.length > 0) return;

    AWEFeedCellViewController *rootVC = [self yy_viewController];
    AWEAwemeModel *model = rootVC.model;
    NSString *countryID = model.region;

    if (!countryID || [countryID isEqualToString:@"?"]) {
        regionLabel.hidden = YES;
        return;
    }

    NSString *locationName = getCountryNameForCode(countryID);
    if (!locationName) return;

    if (!regionLabel) {
        regionLabel = [[UILabel alloc] init];
        regionLabel.tag = 666;
        regionLabel.font = [UIFont systemFontOfSize:14];
        regionLabel.textAlignment = NSTextAlignmentLeft;
        regionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        regionLabel.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        regionLabel.layer.shadowOpacity = 0.3;
        regionLabel.layer.shadowRadius = 0.5;
        [self addSubview:regionLabel];
    }
    
    regionLabel.hidden = NO;
    regionLabel.text = [NSString stringWithFormat:@"%@·", locationName];
    
    NSString *hexColor = [BHIManager uploadRegionLabelColor];
    if ([BHIManager uploadRegionRandomGradient]) {
        NSArray *colors = @[@"FF6B6B", @"4ECDC4", @"45B7D1", @"96CEB4", @"FFEAA7"];
        hexColor = colors[arc4random_uniform((int)colors.count)];
    }
    
    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexColor];
    [scanner scanHexInt:&rgbValue];
    regionLabel.textColor = [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];

    [regionLabel sizeToFit];
    CGRect f = regionLabel.frame;
    f.origin.x = 0;
    f.origin.y = 2.0;
    
    CGFloat offset = [BHIManager uploadRegionVerticalOffset];
    if (offset != 0) {
        f.origin.y -= offset;
    }
    
    CGFloat maxWidth = self.bounds.size.width * 0.3;
    if (f.size.width > maxWidth) f.size.width = maxWidth;
    regionLabel.frame = f;
}
%end

// ==========================================
// AWEFeedViewTemplateCell
// ==========================================
%hook AWEFeedViewTemplateCell
%property (nonatomic, strong) JGProgressHUD *hud;
%property (nonatomic, retain) NSString *fileextension;
%property (nonatomic, retain) UIProgressView *progressView;

- (void)configWithModel:(id)model {
    %orig;
    [self setupCustomButtons];
}

- (void)configureWithModel:(id)model {
    %orig;
    [self setupCustomButtons];
}

%new - (void)setupCustomButtons {
    if ([BHIManager downloadButton] && ![self viewWithTag:998]) {
        UIButton *dlBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        dlBtn.tag = 998;
        dlBtn.tintColor = [UIColor whiteColor];
        [dlBtn setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
        [dlBtn addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
        dlBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:dlBtn];
        [NSLayoutConstraint activateConstraints:@[
            [dlBtn.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [dlBtn.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [dlBtn.widthAnchor constraintEqualToConstant:30],
            [dlBtn.heightAnchor constraintEqualToConstant:30],
        ]];
    }
    
    if ([BHIManager hideElementButton] && ![self viewWithTag:999]) {
        UIButton *hideBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        hideBtn.tag = 999;
        hideBtn.tintColor = [UIColor whiteColor];
        [hideBtn setImage:[UIImage systemImageNamed:globalElementsHidden ? @"eye" : @"eye.slash"] forState:UIControlStateNormal];
        [hideBtn addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
        hideBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:hideBtn];
        [NSLayoutConstraint activateConstraints:@[
            [hideBtn.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:50],
            [hideBtn.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [hideBtn.widthAnchor constraintEqualToConstant:30],
            [hideBtn.heightAnchor constraintEqualToConstant:30],
        ]];
        
        if (globalElementsHidden) {
             AWEAwemeBaseViewController *rootVC = self.viewController;
             if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                 [rootVC.interactionController hideAllElements:true exceptArray:nil];
             }
        }
    }
}

%new - (void)downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    WEAKify(self);
    
    UIAction *videoAction = [UIAction actionWithTitle:@"Download Video" image:[UIImage systemImageNamed:@"film"] identifier:nil handler:^(UIAction *a){
        STRONGify(self);
        [self downloadVideo:rootVC];
    }];
    
    UIAction *hdVideoAction = [UIAction actionWithTitle:@"Download HD Video" image:[UIImage systemImageNamed:@"film"] identifier:nil handler:^(UIAction *a){
        STRONGify(self);
        [self downloadHDVideo:rootVC];
    }];
    
    UIAction *musicAction = [UIAction actionWithTitle:@"Download Music" image:[UIImage systemImageNamed:@"music.note"] identifier:nil handler:^(UIAction *a){
        STRONGify(self);
        [self downloadMusic:rootVC];
    }];
    
    UIAction *copyLinkAction = [UIAction actionWithTitle:@"Copy Video Link" image:[UIImage systemImageNamed:@"link"] identifier:nil handler:^(UIAction *a){
        STRONGify(self);
        [self copyVideo:rootVC];
    }];

    UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[videoAction, hdVideoAction, musicAction, copyLinkAction]];
    sender.menu = menu;
    sender.showsMenuAsPrimaryAction = YES;
}

%new - (void)hideElementButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
        TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
        globalElementsHidden = !globalElementsHidden;
        [interactionController hideAllElements:globalElementsHidden exceptArray:nil];
        [sender setImage:[UIImage systemImageNamed:globalElementsHidden ? @"eye" : @"eye.slash"] forState:UIControlStateNormal];
    }
}

%new - (void)downloadVideo:(AWEAwemeBaseViewController *)rootVC {
    if (!rootVC.model) return;
    NSURL *url = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    [self startDownload:url];
}

%new - (void)downloadHDVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *itemID = rootVC.model.itemID;
    if (!itemID) return;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", itemID]];
    self.fileextension = @"mp4";
    [self startDownload:url];
}

%new - (void)downloadMusic:(AWEAwemeBaseViewController *)rootVC {
    NSURL *url = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = @"mp3";
    [self startDownload:url];
}

%new - (void)copyVideo:(AWEAwemeBaseViewController *)rootVC {
    NSURL *url = [rootVC.model.video.playURL bestURLtoDownload];
    if (url) {
        [UIPasteboard generalPasteboard].string = url.absoluteString;
    }
}

%new - (void)startDownload:(NSURL *)url {
    if (!url) return;
    BHDownload *dwManager = [[BHDownload alloc] init];
    [dwManager downloadFileWithURL:url];
    [dwManager setDelegate:self];
    
    self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    self.hud.textLabel.text = @"Downloading";
    [self.hud showInView:topMostController().view];
}

%new - (void)downloadProgress:(float)progress {
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
}

%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *newPath = [[NSURL fileURLWithPath:docPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], self.fileextension]];
    
    [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:newPath error:nil];
    [self.hud dismiss];
    
    if ([BHIManager shareSheet]) {
        [BHIManager showSaveVC:@[newPath]];
    } else {
        [BHIManager saveMedia:newPath fileExtension:self.fileextension];
    }
}

%new - (void)downloadDidFailureWithError:(NSError *)error {
    [self.hud dismiss];
}
%end

// ==========================================
// AWEAwemeDetailTableViewCell
// ==========================================
%hook AWEAwemeDetailTableViewCell
%property (nonatomic, strong) JGProgressHUD *hud;
%property (nonatomic, retain) NSString *fileextension;

- (void)configWithModel:(id)model {
    %orig;
    [self setupCustomButtons];
}

%new - (void)setupCustomButtons {
    if ([BHIManager downloadButton] && ![self viewWithTag:998]) {
        UIButton *dlBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        dlBtn.tag = 998;
        dlBtn.tintColor = [UIColor whiteColor];
        [dlBtn setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
        [dlBtn addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
        dlBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:dlBtn];
        [NSLayoutConstraint activateConstraints:@[
            [dlBtn.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [dlBtn.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [dlBtn.widthAnchor constraintEqualToConstant:30],
            [dlBtn.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}

%new - (void)downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    WEAKify(self);
    
    UIAction *videoAction = [UIAction actionWithTitle:@"Download Video" image:[UIImage systemImageNamed:@"film"] identifier:nil handler:^(UIAction *a){
        STRONGify(self);
        [self downloadVideo:rootVC];
    }];
    
    // 简化版只放一个 Action 演示，逻辑同上
    UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[videoAction]];
    sender.menu = menu;
    sender.showsMenuAsPrimaryAction = YES;
}

%new - (void)downloadVideo:(AWEAwemeBaseViewController *)rootVC {
    if (!rootVC.model) return;
    NSURL *url = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    [self startDownload:url];
}

%new - (void)startDownload:(NSURL *)url {
    if (!url) return;
    BHDownload *dwManager = [[BHDownload alloc] init];
    [dwManager downloadFileWithURL:url];
    [dwManager setDelegate:self];
    
    self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    self.hud.textLabel.text = @"Downloading";
    [self.hud showInView:topMostController().view];
}

%new - (void)downloadProgress:(float)progress {
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
}

%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *newPath = [[NSURL fileURLWithPath:docPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], self.fileextension]];
    [[NSFileManager defaultManager] moveItemAtURL:filePath toURL:newPath error:nil];
    [self.hud dismiss];
    if ([BHIManager shareSheet]) {
        [BHIManager showSaveVC:@[newPath]];
    } else {
        [BHIManager saveMedia:newPath fileExtension:self.fileextension];
    }
}

%new - (void)downloadDidFailureWithError:(NSError *)error {
    [self.hud dismiss];
}
%end

// ==========================================
// 播放交互层显示上传日期
// ==========================================
%hook AWEAwemePlayInteractionView

- (void)layoutSubviews {
    %orig;
    
    if (![BHIManager videoUploadDate]) return;
    
    AWEAwemeModel *model = getCurrentVideoModel(self);
    if (!model) return;
    
    NSNumber *ts = model.createTime ?: [model valueForKey:@"createTimeFromServer"];
    if (!ts) return;
    
    UILabel *dateLabel = [self viewWithTag:42006];
    BOOL isNew = NO;
    if (!dateLabel) {
        dateLabel = [[UILabel alloc] init];
        dateLabel.tag = 42006;
        dateLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        dateLabel.textColor = [UIColor colorWithWhite:1 alpha:0.92];
        dateLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        dateLabel.layer.cornerRadius = 4;
        dateLabel.clipsToBounds = YES;
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:dateLabel];
        isNew = YES;
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts.doubleValue];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    dateLabel.text = [NSString stringWithFormat:@"上传时间: %@", [fmt stringFromDate:date]];
    
    if (isNew) {
        UIView *progressBar = nil;
        for (UIView *sub in self.subviews) {
            if ([sub isKindOfClass:NSClassFromString(@"AWEProgressBar")]) {
                progressBar = sub;
                break;
            }
        }
        
        if (progressBar) {
             [NSLayoutConstraint activateConstraints:@[
                [dateLabel.bottomAnchor constraintEqualToAnchor:progressBar.topAnchor constant:-8],
                [dateLabel.leadingAnchor constraintEqualToAnchor:progressBar.leadingAnchor],
                [dateLabel.heightAnchor constraintEqualToConstant:24],
                [dateLabel.widthAnchor constraintEqualToConstant:200]
            ]];
        } else {
             [NSLayoutConstraint activateConstraints:@[
                [dateLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-10],
                [dateLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
                [dateLabel.heightAnchor constraintEqualToConstant:24],
                [dateLabel.widthAnchor constraintEqualToConstant:200]
            ]];
        }
    }
}
%end

// ==========================================
// 视频模型捕获
// ==========================================

%hook AWEVideoPlayViewController
- (void)setCurrentAwemeModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        objc_setAssociatedObject(self, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        AWEAwemePlayInteractionView *interactionView = [self valueForKey:@"_interactionView"];
        updateInteractionViewModel(interactionView, model);
    }
}
%end

%hook AWEVideoPlayerController
- (void)setModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        AWEAwemePlayInteractionView *interactionView = [self valueForKey:@"_interactionView"];
        updateInteractionViewModel(interactionView, model);
    }
}
%end

%hook AWEVideoDetailViewController
- (void)setCurrentAwemeModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        objc_setAssociatedObject(self, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        AWEAwemePlayInteractionView *interactionView = [self valueForKey:@"_interactionView"];
        updateInteractionViewModel(interactionView, model);
    }
}
%end

// ==========================================
// 其他杂项
// ==========================================

%hook TTKProfileRootView
- (void)layoutSubviews {
    %orig;
    if ([BHIManager profileVideoCount] && ![self viewWithTag:888]){
        TTKProfileOtherViewController *rootVC = [self yy_viewController];
        NSNumber *count = [[rootVC user] visibleVideosCount];
        if (count){
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0,2,100,20.5)];
            lbl.tag = 888;
            lbl.text = [NSString stringWithFormat:@"Video Count: %@", count];
            lbl.font = [UIFont systemFontOfSize:9.0];
            [self addSubview:lbl];
        }
    }
}
%end

%hook BDImageView
- (void)layoutSubviews {
    %orig;
    if ([BHIManager profileSave]) {
        for (UIGestureRecognizer *g in self.gestureRecognizers) {
            if ([g isKindOfClass:[UILongPressGestureRecognizer class]]) return;
        }
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.3;
        [self addGestureRecognizer:longPress];
    }
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        showAlert([BHIManager L:@"Save profile image"], nil, [BHIManager L:@"Yes"], [BHIManager L:@"No"], ^{
            UIImageWriteToSavedPhotosAlbum([self bd_baseImage], nil, nil, nil);
        });
    }
}
%end

%hook AWEAwemeModel
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    return [BHIManager hideAds] && self.isAds ? nil : orig;
}
- (BOOL)progressBarDraggable { return [BHIManager progressBar] || %orig; }
- (BOOL)progressBarVisible { return [BHIManager progressBar] || %orig; }
%end

%hook AWEPlayInteractionWarningElementView
- (id)warningImage { return [BHIManager disableWarnings] ? nil : %orig; }
- (id)warningLabel { return [BHIManager disableWarnings] ? nil : %orig; }
%end

%hook AWEMaskInfoModel
- (BOOL)showMask { return [BHIManager disableUnsensitive] ? 0 : %orig; }
%end

%hook AWEAwemeACLItem
- (void)setWatermarkType:(NSUInteger)arg1 {
    %orig([BHIManager removeWatermark] ? 1 : arg1);
}
%end

// ==========================================
// 越狱检测绕过
// ==========================================

%hook NSFileManager
-(BOOL)fileExistsAtPath:(id)arg1 {
    if ([jailbreakPaths containsObject:arg1]) return NO;
    return %orig;
}
-(BOOL)fileExistsAtPath:(id)arg1 isDirectory:(BOOL*)arg2 {
    if ([jailbreakPaths containsObject:arg1]) return NO;
    return %orig;
}
%end

%hook BDADeviceHelper
+(bool)isJailBroken { return NO; }
%end
%hook UIDevice
+(bool)btd_isJailBroken { return NO; }
%end
%hook TTInstallUtil
+(bool)isJailBroken { return NO; }
%end
%hook AppsFlyerUtils
+(bool)isJailbrokenWithSkipAdvancedJailbreakValidation:(bool)arg2 { return NO; }
%end
%hook PIPOIAPStoreManager
-(bool)_pipo_isJailBrokenDeviceWithProductID:(id)arg2 orderID:(id)arg3 { return NO; }
%end
%hook IESLiveDeviceInfo
+(bool)isJailBroken { return NO; }
%end
%hook PIPOStoreKitHelper
-(bool)isJailBroken { return NO; }
%end
%hook BDInstallNetworkUtility
+(bool)isJailBroken { return NO; }
%end
%hook TTAdSplashDeviceHelper
+(bool)isJailBroken { return NO; }
%end

%ctor {
    jailbreakPaths = @[
        @"/Applications/Cydia.app", @"/Applications/blackra1n.app", @"/Applications/FakeCarrier.app", 
        @"/Applications/Icy.app", @"/Applications/IntelliScreen.app", @"/Applications/MxTube.app",
        @"/Applications/RockApp.app", @"/Applications/SBSettings.app", @"/Applications/WinterBoard.app",
        @"/Applications/Sileo.app", @"/Applications/Zebra.app",
        @"/usr/libexec/cydia", @"/usr/libexec/ssh-keysign", @"/usr/libexec/sftp-server",
        @"/usr/bin/ssh", @"/usr/bin/sshd", @"/usr/sbin/sshd", @"/usr/sbin/frida-server",
        @"/var/lib/cydia", @"/var/log/apt", @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/bin/bash", @"/bin/sh", @"/etc/apt"
    ];
    %init;
}