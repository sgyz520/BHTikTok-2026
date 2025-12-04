#import "TikTokHeaders.h"
#import "BHTikTokLocalization.h"
#import <AVFoundation/AVFoundation.h>

static NSArray *jailbreakPaths;

// 自定义本地化加载函数
NSString *BHTikTokLocalizedString(NSString *key, NSString *comment) {
    // 优先从我们的支持目录加载本地化文件
    NSString *supportPath = @"/Library/Application Support/BHTikTok/zh-Hans.lproj";
    NSBundle *bundle = [NSBundle bundleWithPath:supportPath];
    
    // 如果支持目录中的文件不存在，尝试从动态库目录加载
    if (!bundle) {
        NSString *tweakPath = @"/Library/MobileSubstrate/DynamicLibraries/BHTikTok.dylib";
        NSBundle *tweakBundle = [NSBundle bundleWithPath:tweakPath];
        if (tweakBundle) {
            NSString *localizedPath = [tweakBundle pathForResource:@"zh-Hans" ofType:@"lproj"];
            if (localizedPath) {
                bundle = [NSBundle bundleWithPath:localizedPath];
            }
        }
    }
    
    // 如果都失败了，使用主bundle
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    
    // 加载本地化字符串
    NSString *localizedString = [bundle localizedStringForKey:key value:key table:@"Localizable"];
    return localizedString;
}

// Helper functions are already defined in TikTokHeaders.h

static void showConfirmation(void (^okHandler)(void)) {
  [%c(AWEUIAlertView) showAlertWithTitle:BHTikTokLocalizedString(@"BHTikTok, Hi", nil) description:BHTikTokLocalizedString(@"Are you sure?", nil) image:nil actionButtonTitle:BHTikTokLocalizedString(@"Yes", nil) cancelButtonTitle:BHTikTokLocalizedString(@"No", nil) actionBlock:^{
    okHandler();
  } cancelBlock:nil];
}

%hook AppDelegate
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"flex_enebaled"]) {
        [[%c(FLEXManager) performSelector:@selector(sharedManager)] performSelector:@selector(showExplorer)];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"BHTikTokFirstRun"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"BHTikTokFirstRun" forKey:@"BHTikTokFirstRun"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"hide_ads"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"download_button"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"remove_elements_button"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"show_progress_bar"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"save_profile"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"copy_profile_information"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"extended_bio"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"extendedComment"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"auto_play"]; // 设置自动播放默认值为开启
    }
    [BHIManager cleanCache];
    return true;
}

static BOOL isAuthenticationShowed = FALSE;
- (void)applicationDidBecomeActive:(id)arg1 { // old app lock TODO: add face-id
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

%hook TTKMediaSpeedControlService
- (void)setPlaybackRate:(CGFloat)arg1 {
    NSNumber *speed = [BHIManager selectedSpeed];
    if (![BHIManager speedEnabled] || [speed isEqualToNumber:@1]) {
        return %orig;
    }
    if ([BHIManager speedEnabled]) {
        if ([BHIManager selectedSpeed]) {
            return %orig([speed floatValue]);
        }
    } else {
        return %orig;
    }
}
%end

%hook AWEUserWorkCollectionViewCell
- (void)configWithModel:(id)arg1 isMine:(BOOL)arg2 { // Video like count & upload date lables
    %orig;
    if ([BHIManager videoLikeCount] || [BHIManager videoUploadDate]) {
        // Remove existing views
        for (int i = 0; i < [[self.contentView subviews] count]; i ++) {
            UIView *j = [[self.contentView subviews] objectAtIndex:i];
            if (j.tag == 1001) {
                [j removeFromSuperview];
            } 
            else if (j.tag == 1002) {
                [j removeFromSuperview];
            }
        }

        AWEAwemeModel *model = [self model];
        AWEAwemeStatisticsModel *statistics = [model statistics];
        NSNumber *createTime = [model createTime];
        NSNumber *likeCount = [statistics diggCount];
        NSString *likeCountFormatted = [self formattedNumber:[likeCount integerValue]];
        NSString *formattedDate = [self formattedDateStringFromTimestamp:[createTime doubleValue]];

        UILabel *likeCountLabel = [UILabel new];
        likeCountLabel.text = likeCountFormatted;
        likeCountLabel.textColor = [UIColor whiteColor];
        likeCountLabel.font = [UIFont boldSystemFontOfSize:13.0];
        likeCountLabel.tag = 1001;
        [likeCountLabel setTranslatesAutoresizingMaskIntoConstraints:false];
        
        UIImageView *heartImage = [UIImageView new];
        heartImage.image = [UIImage systemImageNamed:@"heart"];
        heartImage.tintColor = [UIColor whiteColor];
        [heartImage setTranslatesAutoresizingMaskIntoConstraints:false];

        UILabel *uploadDateLabel = [UILabel new];
        uploadDateLabel.text = formattedDate;
        uploadDateLabel.textColor = [UIColor whiteColor];
        uploadDateLabel.font = [UIFont boldSystemFontOfSize:13.0];
        uploadDateLabel.tag = 1002;
        [uploadDateLabel setTranslatesAutoresizingMaskIntoConstraints:false];

        UIImageView *clockImage = [UIImageView new];
        clockImage.image = [UIImage systemImageNamed:@"clock"];
        clockImage.tintColor = [UIColor whiteColor];
        [clockImage setTranslatesAutoresizingMaskIntoConstraints:false];
        
        if ([BHIManager videoLikeCount]) {
            [self.contentView addSubview:heartImage];
            [NSLayoutConstraint activateConstraints:@[
                    [heartImage.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:110],
                    [heartImage.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:4],
                    [heartImage.widthAnchor constraintEqualToConstant:16],
                    [heartImage.heightAnchor constraintEqualToConstant:16],
                ]];
            [self.contentView addSubview:likeCountLabel];
            [NSLayoutConstraint activateConstraints:@[
                    [likeCountLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:109],
                    [likeCountLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:23],
                    [likeCountLabel.widthAnchor constraintEqualToConstant:200],
                    [likeCountLabel.heightAnchor constraintEqualToConstant:16],
                ]];
        }
        if ([BHIManager videoUploadDate]) {
            [self.contentView addSubview:clockImage];
            [NSLayoutConstraint activateConstraints:@[
                    [clockImage.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:128],
                    [clockImage.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:4],
                    [clockImage.widthAnchor constraintEqualToConstant:16],
                    [clockImage.heightAnchor constraintEqualToConstant:16],
                ]];
            [self.contentView addSubview:uploadDateLabel];
            [NSLayoutConstraint activateConstraints:@[
                    [uploadDateLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:127],
                    [uploadDateLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:23],
                    [uploadDateLabel.widthAnchor constraintEqualToConstant:200],
                    [uploadDateLabel.heightAnchor constraintEqualToConstant:16],
                ]];
        }
    }
}
%new - (NSString *)formattedNumber:(NSInteger)number {

    if (number >= 1000000) {
        return [NSString stringWithFormat:@"%.1fm", number / 1000000.0];
    } else if (number >= 1000) {
        return [NSString stringWithFormat:@"%.1fk", number / 1000.0];
    } else {
        return [NSString stringWithFormat:@"%ld", (long)number];
    }

}
%new - (NSString *)formattedDateStringFromTimestamp:(NSTimeInterval)timestamp {

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd"; 
    return [dateFormatter stringFromDate:date];

}
%end

%hook TTKProfileRootView
- (void)layoutSubviews { // Video count
    %orig;
    if ([BHIManager profileVideoCount]){
        TTKProfileOtherViewController *rootVC = [self yy_viewController];
        AWEUserModel *user = [rootVC user];
        NSNumber *userVideoCount = [user visibleVideosCount];
        if (userVideoCount){
            UILabel *userVideoCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,2,100,20.5)];
            userVideoCountLabel.text = [NSString stringWithFormat:BHTikTokLocalizedString(@"Video Count: %@", nil), userVideoCount];
            userVideoCountLabel.font = [UIFont systemFontOfSize:9.0];
            [self addSubview:userVideoCountLabel];
        }
    }
}
%end

%hook BDImageView
- (void)layoutSubviews { // Profile save
    %orig;
    if ([BHIManager profileSave]) {
        [self addHandleLongPress];
    }
}
%new - (void)addHandleLongPress {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.3;
    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [%c(AWEUIAlertView) showAlertWithTitle:BHTikTokLocalizedString(@"Save profile image", nil) description:BHTikTokLocalizedString(@"Do you want to save this image", nil) image:nil actionButtonTitle:BHTikTokLocalizedString(@"Yes", nil) cancelButtonTitle:BHTikTokLocalizedString(@"No", nil) actionBlock:^{
            UIImageWriteToSavedPhotosAlbum([self bd_baseImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
  } cancelBlock:nil];
    }
}
%new - (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"Error saving image: %@", error.localizedDescription);
    } else {
        NSLog(@"Image successfully saved to Photos app");
    }
}
%end

%hook AWEUserNameLabel // fake verification
- (void)layoutSubviews {
    %orig;
    if ([self.yy_viewController isKindOfClass:(%c(TTKProfileHomeViewController))] && [BHIManager fakeVerified]) {
        [self addVerifiedIcon:true];
    }
}
%end

%hook TTTAttributedLabel // copy profile decription
- (void)layoutSubviews {
    %orig;
    if ([BHIManager profileCopy]){
        [self addHandleLongPress];
    }
}
%new - (void)addHandleLongPress {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.3;
    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSString *profileDescription = [self text];
        [%c(AWEUIAlertView) showAlertWithTitle:@"Copy bio" description:@"Do you want to copy this text to clipboard" image:nil actionButtonTitle:@"Yes" cancelButtonTitle:@"No" actionBlock:^{
             if (profileDescription) {
                                                                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                                    pasteboard.string = profileDescription;
                                                                }
  } cancelBlock:nil];
    }
}
%end

%hook TTKSettingsBaseCellPlugin
- (void)didSelectItemAtIndex:(NSInteger)index {
    if ([self.itemModel.identifier isEqualToString:@"bhtiktok_settings"]) {
        UINavigationController *BHTikTokSettings = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
        [topMostController() presentViewController:BHTikTokSettings animated:true completion:nil];
    } else {
        return %orig;
    }
}
%end

%hook AWESettingsNormalSectionViewModel
- (void)viewDidLoad {
    %orig;
    if ([self.sectionIdentifier isEqualToString:@"account"]) {
        TTKSettingsBaseCellPlugin *BHTikTokSettingsPluginCell = [[%c(TTKSettingsBaseCellPlugin) alloc] initWithPluginContext:self.context];

        AWESettingItemModel *BHTikTokSettingsItemModel = [[%c(AWESettingItemModel) alloc] initWithIdentifier:@"bhtiktok_settings"];
        [BHTikTokSettingsItemModel setTitle:BHTikTokLocalizedString(@"BHTikTok++ settings", nil)];
        [BHTikTokSettingsItemModel setDetail:BHTikTokLocalizedString(@"BHTikTok++ settings", nil)];
        [BHTikTokSettingsItemModel setIconImage:[UIImage systemImageNamed:@"gear"]];
        [BHTikTokSettingsItemModel setType:99];

        [BHTikTokSettingsPluginCell setItemModel:BHTikTokSettingsItemModel];

        [self insertModel:BHTikTokSettingsPluginCell atIndex:0 animated:true];
    }
}
%end

%hook SparkViewController // alwaysOpenSafari
- (void)viewWillAppear:(BOOL)animated {
    if (![BHIManager alwaysOpenSafari]) {
        return %orig;
    }
    
    // NSURL *url = self.originURL;
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.originURL resolvingAgainstBaseURL:NO];
    NSString *searchParameter = @"url";
    NSString *searchValue = nil;
    
    for (NSURLQueryItem *queryItem in components.queryItems) {
        if ([queryItem.name isEqualToString:searchParameter]) {
            searchValue = queryItem.value;
            break;
        }
    }
    
    // In-app browser is used for two-factor authentication with security key,
    // login will not complete successfully if it's redirected to Safari
    // if ([urlStr containsString:@"twitter.com/account/"] || [urlStr containsString:@"twitter.com/i/flow/"]) {
    //     return %orig;
    // }

    if (searchValue) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:searchValue] options:@{} completionHandler:nil];
        [self didTapCloseButton];
    } else {
        return %orig;
    }
}
%end

%hook CTCarrier // changes country 
- (NSString *)mobileCountryCode {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"mcc"];
        }
        return %orig;
    }
    return %orig;
}

- (void)setIsoCountryCode:(NSString *)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}

- (NSString *)isoCountryCode {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}

- (NSString *)mobileNetworkCode {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"mnc"];
        }
        return %orig;
    }
    return %orig;
}
%end
%hook TTKStoreRegionService
- (id)storeRegion {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (id)getStoreRegion {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig([selectedRegion[@"code"] lowercaseString]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end
%hook TIKTOKRegionManager
+ (NSString *)systemRegion {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)region {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)mccmnc {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [NSString stringWithFormat:@"%@%@", selectedRegion[@"mcc"], selectedRegion[@"mnc"]];
        }
        return %orig;
    }
    return %orig;
}
+ (id)storeRegion {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)currentRegionV2 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
+ (id)localRegion {
        if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}

%end

%hook TTKPassportAppStoreRegionModel
- (id)storeRegion {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig([selectedRegion[@"code"] lowercaseString]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
- (void)setLocalizedCountryName:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig(selectedRegion[@"name"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
- (id)localizedCountryName {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"name"];
        }
        return %orig;
    }
    return %orig;
}
%end

%hook ATSRegionCacheManager
- (id)getRegion {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (id)storeRegionFromCache {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (id)storeRegionFromTTNetNotification:(id)arg1 {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
- (void)setRegion:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig([selectedRegion[@"code"] lowercaseString]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
- (id)region {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return [selectedRegion[@"code"] lowercaseString];
        }
        return %orig;
    }
    return %orig;
}
%end

%hook TTKStoreRegionModel
- (id)storeRegion {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end

%hook TTInstallIDManager
- (id)currentAppRegion {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
- (void)setCurrentAppRegion:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end

%hook BDInstallGlobalConfig
- (id)currentAppRegion {
 if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return selectedRegion[@"code"];
        }
        return %orig;
    }
    return %orig;
}
- (void)setCurrentAppRegion:(id)arg1 {
    if ([BHIManager regionChangingEnabled]) {
        if ([BHIManager selectedRegion]) {
            NSDictionary *selectedRegion = [BHIManager selectedRegion];
            return %orig(selectedRegion[@"code"]);
        }
        return %orig(arg1);
    }
    return %orig(arg1);
}
%end

%hook ACCCreationPublishAction
- (BOOL)is_open_hd {
    if ([BHIManager uploadHD]) {
        return 1;
    }
    return %orig;
}
- (void)setIs_open_hd:(BOOL)arg1 {
    if ([BHIManager uploadHD]) {
        %orig(1);
    }
    else {
        return %orig;
    }
}
- (BOOL)is_have_hd {
    if ([BHIManager uploadHD]) {
        return 1;
    }
    return %orig;
}
- (void)setIs_have_hd:(BOOL)arg1 {
    if ([BHIManager uploadHD]) {
        %orig(1);
    }
    else {
        return %orig;
    }
}

%end

%hook TTKCommentPanelViewController
- (void)viewDidLoad {
    %orig;
    if ([BHIManager transparentCommnet]){
        UIView *commnetView = [self view];
        [commnetView setAlpha:0.90];
    }
}
%end

%hook AWEAwemeModel // no ads, show porgress bar
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    return [BHIManager hideAds] && self.isAds ? nil : orig;
}
- (id)init {
    id orig = %orig;
    return [BHIManager hideAds] && self.isAds ? nil : orig;
}

- (BOOL)progressBarDraggable {
    return [BHIManager progressBar] || %orig;
}
- (BOOL)progressBarVisible {
    BOOL shouldShow = [BHIManager progressBar] || %orig;
    if (shouldShow) {
        // 显示当前播放时间和总时长
        // 注意：这里需要找到正确的位置来添加时间标签
        // 由于无法直接获取当前播放时间，我们将在后续步骤中实现
    }
    return shouldShow;
}
- (void)live_callInitWithDictyCategoryMethod:(id)arg1 {
    if (![BHIManager disableLive]) {
        %orig;
    }
}
+ (id)liveStreamURLJSONTransformer {
    if ([BHIManager disableLive]) {
        return nil;
    }
    return %orig;
}
+ (id)relatedLiveJSONTransformer {
    if ([BHIManager disableLive]) {
        return nil;
    }
    return %orig;
}
+ (id)rawModelFromLiveRoomModel:(id)arg1 {
    if ([BHIManager disableLive]) {
        return nil;
    }
    return %orig;
}
+ (id)aweLiveRoom_subModelPropertyKey {
    if ([BHIManager disableLive]) {
        return nil;
    }
    return %orig;
}
%end

%hook AWEPlayInteractionWarningElementView
- (id)warningImage {
    if ([BHIManager disableWarnings]) {
        return nil;
    }
    return %orig;
}
- (id)warningLabel {
    if ([BHIManager disableWarnings]) {
        return nil;
    }
    return %orig;
}
%end

%hook TUXLabel
- (void)setText:(NSString*)arg1 {
    if ([BHIManager showUsername]) {
        if ([[[self superview] superview] isKindOfClass:%c(AWEPlayInteractionAuthorUserNameButton)]){
            AWEFeedCellViewController *rootVC = [[[self superview] superview] yy_viewController];
            AWEAwemeModel *model = rootVC.model;
            AWEUserModel *authorModel = model.author;
            NSString *nickname = authorModel.nickname;
            NSString *username = authorModel.socialName;
            %orig(username);
        }else {
            %orig;
        }
    }else {
        %orig;
    }
}
%end

%hook AWENewFeedTableViewController
- (BOOL)disablePullToRefreshGestureRecognizer {
    if ([BHIManager disablePullToRefresh]){
        return 1;
    }
    return %orig;
}

%end

%hook AWEPlayVideoPlayerController // auto play next video and stop looping video
- (void)playerWillLoopPlaying:(id)arg1 {
    if ([BHIManager autoPlay]) {
        if ([self.container.parentViewController isKindOfClass:%c(AWENewFeedTableViewController)]) {
            [((AWENewFeedTableViewController *)self.container.parentViewController) scrollToNextVideo];
            return;
        }
    }
    %orig;
}

- (BOOL)loop {
    // 如果启用了自动播放，强制返回YES以确保视频循环
    if ([BHIManager autoPlay]) {
        return YES;
    }
    if ([BHIManager stopPlay]) {
        return 0;
    }
    return %orig; 
}
- (void)setLoop:(BOOL)arg1 {
    // 如果启用了自动播放，强制设置为YES以确保视频循环
    if ([BHIManager autoPlay]) {
        %orig(YES);
    } else if ([BHIManager stopPlay]) {
        %orig(0);
    } else {
        %orig(arg1);
    }
}
%end

%hook AWEMaskInfoModel // Disable Unsensitive Content
- (BOOL)showMask {
    if ([BHIManager disableUnsensitive]) {
        return 0;
    }
    return %orig;
}
- (void)setShowMask:(BOOL)arg1 {
    if ([BHIManager disableUnsensitive]) {
        %orig(0);
    }
    else {
        %orig;
    }
}
%end

%hook AWEAwemeACLItem // remove default watermark
- (void)setWatermarkType:(NSUInteger)arg1 {
    if ([BHIManager removeWatermark]){
        %orig(1);
    }
    else { 
        %orig;
    }
    
}
- (NSUInteger)watermarkType {
    if ([BHIManager removeWatermark]){
        return 1;
    }
    return %orig;
}
%end

%hook UIButton // follow confirmation broken 
- (void)_onTouchUpInside {
    if ([BHIManager followConfirmation] && [self.currentTitle isEqualToString:@"Follow"]) {
        showConfirmation(^(void) { %orig; });
    } else {
        %orig;
    }
}
%end
%hook AWEPlayInteractionUserAvatarElement
- (void)onFollowViewClicked:(id)sender {
    if ([BHIManager followConfirmation]) {
        showConfirmation(^(void) { %orig; });
    } else {
        return %orig;
    }
}
%end

%hook TTKProfileBaseComponentModel // Fake Followers, Fake Following and FakeVerified.

- (NSDictionary *)bizData {
	if ([BHIManager fakeChangesEnabled]) {
		NSDictionary *originalData = %orig;
		NSMutableDictionary *modifiedData = [originalData mutableCopy];
		
		NSNumber *fakeFollowingCount = [self numberFromUserDefaultsForKey:@"following_count"];
		NSNumber *fakeFollowersCount = [self numberFromUserDefaultsForKey:@"follower_count"];
		
		if ([self.componentID isEqualToString:@"relation_info_follower"]) {
			modifiedData[@"follower_count"] = fakeFollowersCount ?: @0; 
		} else if ([self.componentID isEqualToString:@"relation_info_following"]) {
			modifiedData[@"following_count"] = fakeFollowingCount ?: @0; 
			modifiedData[@"formatted_number"] = [self formattedStringFromNumber:fakeFollowingCount ?: @0];
		} 
		return [modifiedData copy];
	}
	return %orig;
}

- (NSArray *)components {
	if ([BHIManager fakeVerified]) {
		NSArray *originalComponents = %orig;
		if ([self.componentID isEqualToString:@"user_account_base_info"] && originalComponents.count == 1) {
			NSMutableArray *modifiedComponents = [originalComponents mutableCopy];
			TTKProfileBaseComponentModel *fakeVerify = [%c(TTKProfileBaseComponentModel) new];
			fakeVerify.componentID = @"user_account_verify";
			fakeVerify.name = @"user_account_verify";
			[modifiedComponents addObject:fakeVerify];
			return [modifiedComponents copy];
		}
	}
	return %orig;
}

%new - (NSNumber *)numberFromUserDefaultsForKey:(NSString *)key {
    NSString *stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    return (stringValue.length > 0) ? @([stringValue doubleValue]) : @0; 
}

%new - (NSString *)formattedStringFromNumber:(NSNumber *)number {
    if (!number) return @"0"; 

    double value = [number doubleValue];
    if (value == 0) return @"0"; 

    NSString *formattedString;
    if (value >= 1e9) {
        formattedString = [NSString stringWithFormat:@"%.1fB", value / 1e9];
    } else if (value >= 1e6) {
        formattedString = [NSString stringWithFormat:@"%.1fM", value / 1e6];
    } else if (value >= 1e3) {
        formattedString = [NSString stringWithFormat:@"%.1fk", value / 1e3];
    } else {
        formattedString = [NSString stringWithFormat:@"%.0f", value];
    }

    return formattedString;
}

%end

%hook AWEFeedVideoButton // like feed confirmation
- (void)_onTouchUpInside {
    if ([BHIManager likeConfirmation] && [self.imageNameString isEqualToString:@"ic_like_fill_1_new"]) {
        showConfirmation(^(void) { %orig; });
    } else {
        %orig;
    }
}
%end
%hook AWECommentPanelCell // like/dislike comment confirmation
- (void)onLikeAction:(id)arg1 {
    if ([BHIManager likeCommentConfirmation]) {
        showConfirmation(^(void) { %orig; });
    } else {
        return %orig;
    }
}
- (void)onDislikeAction:(id)arg1 {
    if ([BHIManager dislikeCommentConfirmation]) {
        showConfirmation(^(void) { %orig; });
    } else {
        return %orig;
    }
}
%end

%hook AWEUserModel // follower, following Count fake  
- (NSNumber *)followerCount {
    if ([BHIManager fakeChangesEnabled]) {
        NSString *fakeCountString = [[NSUserDefaults standardUserDefaults] stringForKey:@"follower_count"];
        if (!(fakeCountString.length == 0)) {
            NSInteger fakeCount = [fakeCountString integerValue];
            return [NSNumber numberWithInt:fakeCount];
        }

        return %orig;
    }

    return %orig;
}
- (NSNumber *)followingCount {
    if ([BHIManager fakeChangesEnabled]) {
        NSString *fakeCountString = [[NSUserDefaults standardUserDefaults] stringForKey:@"following_count"];
        if (!(fakeCountString.length == 0)) {
            NSInteger fakeCount = [fakeCountString integerValue];
            return [NSNumber numberWithInt:fakeCount];
        }

        return %orig;
    }

    return %orig;
}
%end

%hook AWETextInputController
- (NSUInteger)maxLength {
    if ([BHIManager extendedComment]) {
        return 500;
    }

    return %orig;
}
%end
// MARK: - 时间格式化
@interface BHTimeFormatter : NSObject
+ (NSString *)format:(double)seconds;
@end

@implementation BHTimeFormatter
+ (NSString *)format:(double)seconds {
    if (!isnormal(seconds) || seconds < 0) return @"--:--";
    NSInteger total = (NSInteger)seconds;
    NSInteger hours = total / 3600;
    NSInteger minutes = (total % 3600) / 60;
    NSInteger secs = total % 60;
    
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
    } else {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
    }
}
@end

// MARK: - 播放器时间访问器
@interface BHVideoTimeAccessor : NSObject
- (AVPlayer *)findPlayer;
- (double)getCurrentPlaybackTimeFromPlayer:(AVPlayer *)player;
- (double)getVideoDurationFromPlayer:(AVPlayer *)player;
@end

@implementation BHVideoTimeAccessor
- (AVPlayer *)findPlayer {
    UIWindow *window = nil;
    
    // 查找当前key window
    for (UIWindow *w in [[UIApplication sharedApplication] windows]) {
        if (w.isKeyWindow) {
            window = w;
            break;
        }
    }
    
    if (!window) {
        window = [[UIApplication sharedApplication] keyWindow];
    }
    
    if (!window) return nil;
    
    __block AVPlayer *result = nil;
    
    // 深度优先搜索查找AVPlayer
    void (^dfs)(UIView *) = ^(UIView *view) {
        if (result != nil) return;
        
        // 检查当前视图的layer是否是AVPlayerLayer
        if ([view.layer isKindOfClass:[AVPlayerLayer class]]) {
            AVPlayerLayer *playerLayer = (AVPlayerLayer *)view.layer;
            result = playerLayer.player;
            return;
        }
        
        // 检查子layer
        if (view.layer.sublayers) {
            for (CALayer *layer in view.layer.sublayers) {
                if ([layer isKindOfClass:[AVPlayerLayer class]]) {
                    AVPlayerLayer *playerLayer = (AVPlayerLayer *)layer;
                    result = playerLayer.player;
                    return;
                }
            }
        }
        
        // 递归检查子视图
        for (UIView *subview in view.subviews) {
            dfs(subview);
            if (result != nil) return;
        }
    };
    
    dfs(window);
    return result;
}

- (double)getCurrentPlaybackTimeFromPlayer:(AVPlayer *)player {
    if (!player) return 0.0;
    
    CMTime currentTime = player.currentTime;
    if (CMTIME_IS_VALID(currentTime)) {
        return CMTimeGetSeconds(currentTime);
    }
    return 0.0;
}

- (double)getVideoDurationFromPlayer:(AVPlayer *)player {
    if (!player) return 0.0;
    
    AVPlayerItem *currentItem = player.currentItem;
    if (currentItem && currentItem.status == AVPlayerItemStatusReadyToPlay) {
        CMTime duration = currentItem.duration;
        if (CMTIME_IS_VALID(duration) && !CMTIME_IS_INDEFINITE(duration)) {
            return CMTimeGetSeconds(duration);
        }
    }
    return 0.0;
}
@end

// MARK: - 自动滑动控制器
@interface BHGestureController : NSObject
@property (nonatomic, strong) BHVideoTimeAccessor *timeAccessor;

- (void)swipeToNextWithCompletion:(void (^)(BOOL))completion;
- (UIScrollView *)findScrollViewInWindow:(UIWindow *)window;
- (void)performScroll:(UIScrollView *)scrollView withCompletion:(void (^)(BOOL))completion;
@end

@implementation BHGestureController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timeAccessor = [[BHVideoTimeAccessor alloc] init];
    }
    return self;
}

- (void)swipeToNextWithCompletion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_main_queue(), ^{        
        // 获取当前key window
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        
        if (!keyWindow) {
            keyWindow = [[UIApplication sharedApplication] keyWindow];
        }
        
        // 查找滚动视图
        UIScrollView *scrollView = [self findScrollViewInWindow:keyWindow];
        if (scrollView) {
            [self performScroll:scrollView withCompletion:completion];
        } else {
            if (completion) completion(NO);
        }
    });
}

- (UIScrollView *)findScrollViewInWindow:(UIWindow *)window {
    if (!window) return nil;
    
    __block UIScrollView *result = nil;
    
    // 深度优先搜索查找滚动视图
    void (^dfs)(UIView *) = ^(UIView *view) {
        if (result != nil) return;
        
        // 优先查找UICollectionView
        if ([view isKindOfClass:[UICollectionView class]]) {
            result = (UIScrollView *)view;
            return;
        }
        
        // 查找普通UIScrollView
        if ([view isKindOfClass:[UIScrollView class]] && ![view isKindOfClass:[UITableView class]]) {
            result = view;
            return;
        }
        
        // 递归检查子视图
        for (UIView *subview in view.subviews) {
            dfs(subview);
        }
    };
    
    dfs(window.rootViewController.view);
    return result;
}

- (void)performScroll:(UIScrollView *)scrollView withCompletion:(void (^)(BOOL))completion {
    CGFloat screenHeight = scrollView.bounds.size.height;
    CGPoint targetOffset = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y + screenHeight);
    
    // 执行滑动动画
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{        
        [scrollView setContentOffset:targetOffset animated:NO];
    } completion:^(BOOL finished) {        
        // 添加延迟确保视频加载完成
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{            
            if (completion) completion(finished);
        });
    }];
}

@end

// MARK: - 悬浮调试面板类，用于实时显示视频播放信息
@interface BHDebugFloatPanel : UIView
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISwitch *autoSwipeSwitch;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) BHVideoTimeAccessor *timeAccessor;
@property (nonatomic, strong) BHGestureController *gestureController;
@property (nonatomic, strong) NSTimer *autoSwipeTimer;
@property (nonatomic, assign) double autoSwipeThreshold;
@property (nonatomic, assign) BOOL autoSwipeEnabled;
@property (nonatomic, strong) NSDate *lastSwipeTime;

+ (instancetype)sharedInstance;
- (void)show;
- (void)hide;
- (void)updatePlaybackInfo;
- (void)startAutoSwipeMonitoring;
- (void)stopAutoSwipeMonitoring;
@end

@implementation BHDebugFloatPanel

+ (instancetype)sharedInstance {
    static BHDebugFloatPanel *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{        
        instance = [[BHDebugFloatPanel alloc] init];
        [instance setupUI];
    });
    return instance;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(50, 100, 180, 60)];
    if (self) {
        // 初始化默认设置
        self.autoSwipeThreshold = 0.97; // 播放到97%时自动滑动
        self.autoSwipeEnabled = NO;
        
        // 初始化时间访问器
        self.timeAccessor = [[BHVideoTimeAccessor alloc] init];
        
        // 初始化手势控制器
        self.gestureController = [[BHGestureController alloc] init];
        
        // 允许用户拖动
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    self.layer.cornerRadius = 8.0;
    self.layer.masksToBounds = YES;
    
    // 创建自动滑动开关
    self.autoSwipeSwitch = [[UISwitch alloc] init];
    self.autoSwipeSwitch.onTintColor = [UIColor systemGreenColor];
    [self.autoSwipeSwitch addTarget:self action:@selector(autoSwipeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.autoSwipeSwitch];
    
    // 创建自动滑动标签
    UILabel *autoSwipeLabel = [[UILabel alloc] init];
    autoSwipeLabel.text = @"自动下一条";
    autoSwipeLabel.textColor = [UIColor whiteColor];
    autoSwipeLabel.font = [UIFont systemFontOfSize:12];
    [self addSubview:autoSwipeLabel];
    
    // 创建时间标签
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightMedium];
    self.currentTimeLabel.text = @"00:00";
    [self addSubview:self.currentTimeLabel];
    
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.textColor = [UIColor lightGrayColor];
    self.durationLabel.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightMedium];
    self.durationLabel.text = @"--:--";
    [self addSubview:self.durationLabel];
    
    // 创建播放状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = [UIColor systemGreenColor];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.text = @"播放中";
    [self addSubview:self.statusLabel];
    
    // 使用Auto Layout布局
    autoSwipeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoSwipeSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 自动滑动开关和标签约束
    NSLayoutConstraint *autoSwipeLabelLeading = [NSLayoutConstraint constraintWithItem:autoSwipeLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:12];
    NSLayoutConstraint *autoSwipeLabelTop = [NSLayoutConstraint constraintWithItem:autoSwipeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:6];
    
    NSLayoutConstraint *autoSwipeSwitchTrailing = [NSLayoutConstraint constraintWithItem:self.autoSwipeSwitch attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-12];
    NSLayoutConstraint *autoSwipeSwitchCenterY = [NSLayoutConstraint constraintWithItem:self.autoSwipeSwitch attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:autoSwipeLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    
    // 当前时间标签约束
    NSLayoutConstraint *currentTimeLabelLeading = [NSLayoutConstraint constraintWithItem:self.currentTimeLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:12];
    NSLayoutConstraint *currentTimeLabelTop = [NSLayoutConstraint constraintWithItem:self.currentTimeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:autoSwipeLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:2];
    
    // 总时长标签约束
    NSLayoutConstraint *durationLabelLeading = [NSLayoutConstraint constraintWithItem:self.durationLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.currentTimeLabel attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:10];
    NSLayoutConstraint *durationLabelCenterY = [NSLayoutConstraint constraintWithItem:self.durationLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.currentTimeLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    
    // 播放状态标签约束
    NSLayoutConstraint *statusLabelTrailing = [NSLayoutConstraint constraintWithItem:self.statusLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-12];
    NSLayoutConstraint *statusLabelCenterY = [NSLayoutConstraint constraintWithItem:self.statusLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.currentTimeLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *statusLabelLeading = [NSLayoutConstraint constraintWithItem:self.statusLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.durationLabel attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:10];
    
    // 激活所有约束
    [self addConstraints:@[autoSwipeLabelLeading, autoSwipeLabelTop, autoSwipeSwitchTrailing, autoSwipeSwitchCenterY, 
                           currentTimeLabelLeading, currentTimeLabelTop, durationLabelLeading, durationLabelCenterY, 
                           statusLabelTrailing, statusLabelCenterY, statusLabelLeading]];
}

- (void)show {
    // 移除旧的实例
    [self removeFromSuperview];
    
    // 添加到当前key window
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    
    if (!keyWindow) {
        keyWindow = [[UIApplication sharedApplication] keyWindow];
    }
    
    if (keyWindow) {
        [keyWindow addSubview:self];
        [keyWindow bringSubviewToFront:self];
        
        // 开始更新计时器
        [self startUpdateTimer];
        
        // 开始自动滑动监控
        if (self.autoSwipeEnabled) {
            [self startAutoSwipeMonitoring];
        }
    }
}

- (void)hide {
    [self stopUpdateTimer];
    [self stopAutoSwipeMonitoring];
    [self removeFromSuperview];
}

- (void)startUpdateTimer {
    [self stopUpdateTimer];
    // 提高更新频率，使显示更流畅
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatePlaybackInfo) userInfo:nil repeats:YES];
    // 添加到RunLoop，确保在滑动时也能更新
    [[NSRunLoop mainRunLoop] addTimer:self.updateTimer forMode:NSRunLoopCommonModes];
}

- (void)stopUpdateTimer {
    if (self.updateTimer) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    // 确保面板不会超出屏幕边界
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.center = CGPointMake(
        MAX(self.bounds.size.width/2, MIN(screenBounds.size.width - self.bounds.size.width/2, self.center.x)),
        MAX(self.bounds.size.height/2, MIN(screenBounds.size.height - self.bounds.size.height/2, self.center.y))
    );
}

- (void)autoSwipeSwitchChanged:(UISwitch *)sender {
    self.autoSwipeEnabled = sender.isOn;
    
    if (sender.isOn) {
        [self startAutoSwipeMonitoring];
    } else {
        [self stopAutoSwipeMonitoring];
    }
}

- (void)startAutoSwipeMonitoring {
    [self stopAutoSwipeMonitoring];
    
    // 启动自动滑动监控定时器
    self.autoSwipeTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkAutoSwipeCondition) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.autoSwipeTimer forMode:NSRunLoopCommonModes];
}

- (void)stopAutoSwipeMonitoring {
    if (self.autoSwipeTimer) {
        [self.autoSwipeTimer invalidate];
        self.autoSwipeTimer = nil;
    }
}

- (void)checkAutoSwipeCondition {
    if (!self.autoSwipeEnabled) {
        return;
    }
    
    // 防止重复触发
    if (self.lastSwipeTime) {
        NSTimeInterval timeSinceLastSwipe = [[NSDate date] timeIntervalSinceDate:self.lastSwipeTime];
        if (timeSinceLastSwipe < 1.0) {
            return;
        }
    }
    
    // 获取播放信息
    AVPlayer *player = [self.timeAccessor findPlayer];
    if (!player) {
        return;
    }
    
    double currentTime = [self.timeAccessor getCurrentPlaybackTimeFromPlayer:player];
    double duration = [self.timeAccessor getVideoDurationFromPlayer:player];
    
    // 检查是否达到自动滑动条件
    if (duration > 0 && currentTime / duration >= self.autoSwipeThreshold) {
        [self triggerAutoSwipe];
    }
}

- (void)triggerAutoSwipe {
    self.lastSwipeTime = [NSDate date];
    
    // 执行自动滑动
    [self.gestureController swipeToNextWithCompletion:^(BOOL success) {
        if (success) {
            NSLog(@"自动滑动到下一个视频成功");
        } else {
            NSLog(@"自动滑动到下一个视频失败");
        }
    }];
}

- (void)updatePlaybackInfo {
    // 查找AVPlayer
    AVPlayer *player = [self.timeAccessor findPlayer];
    
    if (player) {
        // 获取播放信息
        double currentTime = [self.timeAccessor getCurrentPlaybackTimeFromPlayer:player];
        double duration = [self.timeAccessor getVideoDurationFromPlayer:player];
        
        // 更新UI
        self.currentTimeLabel.text = [BHTimeFormatter format:currentTime];
        self.durationLabel.text = [BHTimeFormatter format:duration];
        self.statusLabel.text = (player.rate > 0) ? @"播放中" : @"已暂停";
        self.statusLabel.textColor = (player.rate > 0) ? [UIColor systemGreenColor] : [UIColor systemRedColor];
    } else {
        // 未找到播放器
        self.currentTimeLabel.text = @"--:--";
        self.durationLabel.text = @"--:--";
        self.statusLabel.text = @"未播放";
        self.statusLabel.textColor = [UIColor lightGrayColor];
    }
}

@end

%hook AWEPlayVideoPlayerController
// 前置声明我们添加的新方法
@interface AWEPlayVideoPlayerController ()
- (void)stopTimeUpdateTimer;
- (double)currentPlaybackTime;
- (void)startTimeUpdateTimer;
- (void)updateTimeLabels;
@end

- (void)containerDidFullyDisplayWithReason:(NSInteger)arg1 {
    if ([[[self container] parentViewController] isKindOfClass:%c(AWENewFeedTableViewController)] && [BHIManager skipRecommendations]) {
        AWENewFeedTableViewController *rootVC = [[self container] parentViewController];
        AWEAwemeModel *currentModel = [rootVC currentAweme];
        if ([currentModel isUserRecommendBigCard]) {
            [rootVC scrollToNextVideo];
        }
    }else {
        %orig;
    }
}

// 先定义stopTimeUpdateTimer方法，确保在startTimeUpdateTimer中可以使用
%new - (void)stopTimeUpdateTimer {
    NSTimer *timer = [self valueForKey:@"timeUpdateTimer"];
    if (timer) {
        [timer invalidate];
        [self setValue:nil forKey:@"timeUpdateTimer"];
    }
}

// 尝试获取当前播放时间
%new - (double)currentPlaybackTime {
    // 尝试使用KVC获取当前播放时间
    NSNumber *currentTime = [self valueForKeyPath:@"player.currentTime"];
    if (currentTime) {
        return [currentTime doubleValue];
    }
    
    // 尝试其他可能的键路径
    currentTime = [self valueForKeyPath:@"videoPlayer.currentTime"];
    if (currentTime) {
        return [currentTime doubleValue];
    }
    
    currentTime = [self valueForKeyPath:@"avPlayer.currentTime"];
    if (currentTime) {
        return [currentTime doubleValue];
    }
    
    return 0.0;
}

// 定期更新时间标签
%new - (void)startTimeUpdateTimer {
    // 移除旧的定时器
    [self stopTimeUpdateTimer];
    
    // 创建新的定时器，每秒更新一次
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimeLabels) userInfo:nil repeats:YES];
    [self setValue:timer forKey:@"timeUpdateTimer"];
}

%new - (void)updateTimeLabels {
    if (self.container && [self.container isKindOfClass:%c(AWEAwemeBaseViewController)]) {
        AWEAwemeBaseViewController *viewController = (AWEAwemeBaseViewController *)self.container;
        if (viewController.view && [viewController.view isKindOfClass:%c(UITableView)]) {
            UITableView *tableView = (UITableView *)viewController.view;
            // 获取当前可见的单元格
            NSArray *visibleCells = [tableView visibleCells];
            for (UITableViewCell *cell in visibleCells) {
                if ([cell isKindOfClass:%c(AWEFeedViewTemplateCell)]) {
                    AWEFeedViewTemplateCell *templateCell = (AWEFeedViewTemplateCell *)cell;
                    // 使用KVC访问时间标签和进度条属性
                    UILabel *currentTimeLabel = [templateCell valueForKey:@"currentTimeLabel"];
                    UILabel *totalDurationLabel = [templateCell valueForKey:@"totalDurationLabel"];
                    UIProgressView *progressView = [templateCell valueForKey:@"progressView"];
                    
                    if (currentTimeLabel && totalDurationLabel && progressView) {
                        // 更新当前时间标签
                        double currentTime = [self currentPlaybackTime];
                        NSInteger minutes = currentTime / 60;
                        NSInteger seconds = (NSInteger)currentTime % 60;
                        [currentTimeLabel setText:[NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds]];
                        
                        // 更新进度条
                        // 从总时长标签文本解析总时长
                        NSString *totalDurationText = totalDurationLabel.text;
                        if (totalDurationText) {
                            NSArray *components = [totalDurationText componentsSeparatedByString:@":"];
                            if (components.count == 2) {
                                NSInteger totalMinutes = [components[0] integerValue];
                                NSInteger totalSeconds = [components[1] integerValue];
                                double totalDuration = totalMinutes * 60 + totalSeconds;
                                
                                if (totalDuration > 0) {
                                    float progress = (float)(currentTime / totalDuration);
                                    progressView.progress = progress;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// 在视频开始播放时启动定时器
- (void)play {
    %orig;
    [self startTimeUpdateTimer];
}

// 在视频暂停或停止时停止定时器
- (void)pause {
    %orig;
    [self stopTimeUpdateTimer];
}

- (void)stop {
    %orig;
    [self stopTimeUpdateTimer];
}

%end
%hook AWEProfileEditTextViewController
- (NSInteger)maxTextLength {
    if ([BHIManager extendedBio]) {
        return 222;
    }

    return %orig;
}
%end
%hook AWEPlayInteractionAuthorView
%new - (NSString *)emojiForCountryCode:(NSString *)countryCode {
    // 将国家代码转换为中文国家名称
    NSDictionary *countryNames = @{
        // 亚洲
        @"CN": @"中国",
        @"TW": @"台湾",
        @"HK": @"香港",
        @"MO": @"澳门",
        @"JP": @"日本",
        @"KR": @"韩国",
        @"KP": @"朝鲜",
        @"IN": @"印度",
        @"TH": @"泰国",
        @"VN": @"越南",
        @"ID": @"印度尼西亚",
        @"MY": @"马来西亚",
        @"SG": @"新加坡",
        @"PH": @"菲律宾",
        @"PK": @"巴基斯坦",
        @"BD": @"孟加拉国",
        @"MM": @"缅甸",
        @"KH": @"柬埔寨",
        @"LA": @"老挝",
        @"NP": @"尼泊尔",
        @"LK": @"斯里兰卡",
        @"MV": @"马尔代夫",
        @"BT": @"不丹",
        @"MN": @"蒙古",
        @"KZ": @"哈萨克斯坦",
        @"UZ": @"乌兹别克斯坦",
        @"KG": @"吉尔吉斯斯坦",
        @"TJ": @"塔吉克斯坦",
        @"TM": @"土库曼斯坦",
        @"AF": @"阿富汗",
        @"IR": @"伊朗",
        @"IQ": @"伊拉克",
        @"SA": @"沙特阿拉伯",
        @"YE": @"也门",
        @"OM": @"阿曼",
        @"JO": @"约旦",
        @"SY": @"叙利亚",
        @"LB": @"黎巴嫩",
        @"IL": @"以色列",
        @"PS": @"巴勒斯坦",
        @"AE": @"阿联酋",
        @"QA": @"卡塔尔",
        @"BH": @"巴林",
        @"KW": @"科威特",
        @"TR": @"土耳其",
        @"CY": @"塞浦路斯",
        
        // 欧洲
        @"RU": @"俄罗斯",
        @"GB": @"英国",
        @"FR": @"法国",
        @"DE": @"德国",
        @"IT": @"意大利",
        @"ES": @"西班牙",
        @"PT": @"葡萄牙",
        @"GR": @"希腊",
        @"NL": @"荷兰",
        @"BE": @"比利时",
        @"LU": @"卢森堡",
        @"IE": @"爱尔兰",
        @"DK": @"丹麦",
        @"NO": @"挪威",
        @"SE": @"瑞典",
        @"FI": @"芬兰",
        @"IS": @"冰岛",
        @"CH": @"瑞士",
        @"AT": @"奥地利",
        @"CZ": @"捷克",
        @"SK": @"斯洛伐克",
        @"HU": @"匈牙利",
        @"PL": @"波兰",
        @"RO": @"罗马尼亚",
        @"BG": @"保加利亚",
        @"HR": @"克罗地亚",
        @"SI": @"斯洛文尼亚",
        @"EE": @"爱沙尼亚",
        @"LV": @"拉脱维亚",
        @"LT": @"立陶宛",
        @"UA": @"乌克兰",
        @"BY": @"白俄罗斯",
        @"MD": @"摩尔多瓦",
        @"AL": @"阿尔巴尼亚",
        @"ME": @"黑山",
        @"RS": @"塞尔维亚",
        @"BA": @"波黑",
        @"MK": @"北马其顿",
        @"AD": @"安道尔",
        @"MC": @"摩纳哥",
        @"SM": @"圣马力诺",
        @"VA": @"梵蒂冈",
        @"MT": @"马耳他",
        @"LI": @"列支敦士登",
        
        // 美洲
        @"US": @"美国",
        @"CA": @"加拿大",
        @"MX": @"墨西哥",
        @"BR": @"巴西",
        @"AR": @"阿根廷",
        @"CL": @"智利",
        @"PE": @"秘鲁",
        @"CO": @"哥伦比亚",
        @"VE": @"委内瑞拉",
        @"EC": @"厄瓜多尔",
        @"BO": @"玻利维亚",
        @"PY": @"巴拉圭",
        @"UY": @"乌拉圭",
        @"GY": @"圭亚那",
        @"SR": @"苏里南",
        @"GF": @"法属圭亚那",
        @"CU": @"古巴",
        @"JM": @"牙买加",
        @"HT": @"海地",
        @"DO": @"多米尼加",
        @"PR": @"波多黎各",
        @"CR": @"哥斯达黎加",
        @"PA": @"巴拿马",
        @"GT": @"危地马拉",
        @"HN": @"洪都拉斯",
        @"SV": @"萨尔瓦多",
        @"NI": @"尼加拉瓜",
        @"BZ": @"伯利兹",
        @"BB": @"巴巴多斯",
        @"TT": @"特立尼达和多巴哥",
        @"BS": @"巴哈马",
        
        // 非洲
        @"EG": @"埃及",
        @"ZA": @"南非",
        @"NG": @"尼日利亚",
        @"KE": @"肯尼亚",
        @"TZ": @"坦桑尼亚",
        @"UG": @"乌干达",
        @"GH": @"加纳",
        @"CI": @"科特迪瓦",
        @"SN": @"塞内加尔",
        @"MA": @"摩洛哥",
        @"DZ": @"阿尔及利亚",
        @"TN": @"突尼斯",
        @"LY": @"利比亚",
        @"SD": @"苏丹",
        @"ET": @"埃塞俄比亚",
        @"MW": @"马拉维",
        @"ZM": @"赞比亚",
        @"ZW": @"津巴布韦",
        @"BW": @"博茨瓦纳",
        @"NA": @"纳米比亚",
        @"MZ": @"莫桑比克",
        @"AO": @"安哥拉",
        @"CM": @"喀麦隆",
        @"CD": @"刚果(金)",
        @"CG": @"刚果(布)",
        @"GA": @"加蓬",
        @"GQ": @"赤道几内亚",
        @"CF": @"中非",
        @"TD": @"乍得",
        @"NE": @"尼日尔",
        @"BF": @"布基纳法索",
        @"ML": @"马里",
        @"MR": @"毛里塔尼亚",
        @"SL": @"塞拉利昂",
        @"LR": @"利比里亚",
        @"GN": @"几内亚",
        @"GW": @"几内亚比绍",
        @"GM": @"冈比亚",
        @"ST": @"圣多美和普林西比",
        @"CV": @"佛得角",
        @"SC": @"塞舌尔",
        @"MU": @"毛里求斯",
        @"MG": @"马达加斯加",
        @"KM": @"科摩罗",
        @"RE": @"留尼汪",
        @"YT": @"马约特",
        @"SH": @"圣赫勒拿",
        @"BI": @"布隆迪",
        @"RW": @"卢旺达",
        @"SO": @"索马里",
        @"DJ": @"吉布提",
        @"ER": @"厄立特里亚",
        
        // 大洋洲
        @"AU": @"澳大利亚",
        @"NZ": @"新西兰",
        @"PG": @"巴布亚新几内亚",
        @"FJ": @"斐济",
        @"SB": @"所罗门群岛",
        @"VU": @"瓦努阿图",
        @"NC": @"新喀里多尼亚",
        @"PF": @"法属波利尼西亚",
        @"WS": @"萨摩亚",
        @"KI": @"基里巴斯",
        @"TO": @"汤加",
        @"TV": @"图瓦卢",
        @"NR": @"瑙鲁",
        @"PW": @"帕劳",
        @"FM": @"密克罗尼西亚",
        @"MH": @"马绍尔群岛",
        @"GU": @"关岛",
        @"MP": @"北马里亚纳群岛",
        @"AS": @"美属萨摩亚",
        @"CK": @"库克群岛",
        @"NU": @"纽埃",
        @"TK": @"托克劳",
        @"NF": @"诺福克岛"
    };
    
    // 转换为大写
    NSString *uppercaseCountryCode = [countryCode uppercaseString];
    
    // 返回对应的中文名称，如果没有找到则返回原代码
    return countryNames[uppercaseCountryCode] ?: uppercaseCountryCode;
}

- (void)layoutSubviews {
    %orig;
    if ([BHIManager uploadRegion]){
        for (int i = 0; i < [[self subviews] count]; i ++){
            id j = [[self subviews] objectAtIndex:i];
            if ([j isKindOfClass:%c(UIStackView)]){
                CGRect frame = [j frame];
                frame.origin.x = 39.5; 
                [j setFrame:frame];
            }else {
                [[self viewWithTag:666] removeFromSuperview];
            }
        }
        [[self viewWithTag:666] removeFromSuperview];
        AWEFeedCellViewController* rootVC = self.yy_viewController;
        AWEAwemeModel *model = rootVC.model;
        NSString *countryID = model.region;
        NSString *countryName = [self emojiForCountryCode:countryID];
        
        // 获取视频上传日期并格式化
        NSNumber *createTime = [model createTime];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[createTime doubleValue]];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        NSString *formattedDate = [dateFormatter stringFromDate:date];
        
        // 创建包含国家名称和日期的文本
        NSString *fullText = [NSString stringWithFormat:@"%@ • %@", countryName, formattedDate];
        
        // 创建标签并设置文本
        UILabel *uploadLabel = [[UILabel alloc]init];
        uploadLabel.text = fullText;
        uploadLabel.tag = 666;
        [uploadLabel setTextColor: [UIColor whiteColor]];
        [uploadLabel setFont:[UIFont systemFontOfSize:16.0]]; // 设置合适的字体大小
        
        // 先设置文本，然后计算文本宽度
        [uploadLabel sizeToFit];
        CGFloat labelWidth = uploadLabel.frame.size.width;
        
        // 限制最大宽度，避免过长的国家名称占用太多空间
        CGFloat maxWidth = 150.0; // 增加最大宽度以容纳日期
        if (labelWidth > maxWidth) {
            labelWidth = maxWidth;
        }
        
        // 设置最终框架
        uploadLabel.frame = CGRectMake(0, 2, labelWidth, 20.5);
        
        // 调整UIStackView的位置，为更长的国家名称腾出空间
        for (int i = 0; i < [[self subviews] count]; i ++){
            id j = [[self subviews] objectAtIndex:i];
            if ([j isKindOfClass:%c(UIStackView)]){
                CGRect frame = [j frame];
                // 根据国家标签的宽度动态调整UIStackView的位置
                frame.origin.x = labelWidth + 5.0; // 添加5像素的间距
                [j setFrame:frame];
            }
        }
        
        [self addSubview:uploadLabel];
    }
}
%end
%hook TIKTOKProfileHeaderView // copy profile information
- (id)initWithFrame:(CGRect)arg1 {
    self = %orig;
    if ([BHIManager profileCopy]) {
        [self addHandleLongPress];
    }
    return self;
}
%end

%hook AWELiveFeedEntranceView
- (void)switchStateWithTapped:(BOOL)arg1 {
    if (![BHIManager liveActionEnabled] || [BHIManager selectedLiveAction] == 0) {
        %orig;
    } else if ([BHIManager liveActionEnabled] && [[BHIManager selectedLiveAction] intValue] == 1) {
        UINavigationController *BHTikTokSettings = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
        [topMostController() presentViewController:BHTikTokSettings animated:true completion:nil];
    } 
    else {
        %orig;
    }

}
%end


%hook AWEFeedViewTemplateCell
%property (nonatomic, strong) JGProgressHUD *hud;
%property(nonatomic, assign) BOOL elementsHidden;
%property (nonatomic, retain) NSString *fileextension;
%property (nonatomic, retain) UIProgressView *progressView;
%property (nonatomic, retain) UILabel *currentTimeLabel;
%property (nonatomic, retain) UILabel *totalDurationLabel;
- (void)configWithModel:(id)model {
    %orig;
    // 应用全局隐藏状态
    self.elementsHidden = [BHIManager elementsHiddenGlobal];
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
        // 如果全局状态是隐藏，则立即应用隐藏效果
        if (self.elementsHidden) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{                AWEAwemeBaseViewController *rootVC = self.viewController;
                if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                    TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
                    [interactionController hideAllElements:true exceptArray:nil];
                    // 更新按钮图标
                    UIButton *hideButton = (UIButton *)[self viewWithTag:999];
                    if (hideButton) {
                        [hideButton setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
                    }
                }
            });
        }
    }
    
    // 显示悬浮调试面板
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if (rootVC) {
        [[BHDebugFloatPanel sharedInstance] showInViewController:rootVC];
    }
    
    // 初始化进度条和时间标签
    if ([BHIManager progressBar]) {
        // 如果已经存在时间标签和进度条，先移除
        UILabel *existingCurrentTimeLabel = [self valueForKey:@"currentTimeLabel"];
        if (existingCurrentTimeLabel) {
            [existingCurrentTimeLabel removeFromSuperview];
        }
        UILabel *existingTotalDurationLabel = [self valueForKey:@"totalDurationLabel"];
        if (existingTotalDurationLabel) {
            [existingTotalDurationLabel removeFromSuperview];
        }
        
        // 移除旧的进度条
        UIProgressView *existingProgressView = [self valueForKey:@"progressView"];
        if (existingProgressView) {
            [existingProgressView removeFromSuperview];
        }
        
        // 创建并添加进度条
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progressView.tag = 1000; // 设置tag以便后续查找
        progressView.trackTintColor = [UIColor colorWithWhite:0.5 alpha:0.3];
        progressView.progressTintColor = [UIColor whiteColor];
        [self.contentView addSubview:progressView];
        [self setValue:progressView forKey:@"progressView"];
        [progressView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        // 设置进度条约束，放在视频底部上方
        [NSLayoutConstraint activateConstraints:@[
            [progressView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
            [progressView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [progressView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-45],
            [progressView.heightAnchor constraintEqualToConstant:3]
        ]];
        
        // 创建当前时间标签
        UILabel *currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
        currentTimeLabel.textColor = [UIColor whiteColor];
        currentTimeLabel.font = [UIFont systemFontOfSize:12];
        currentTimeLabel.textAlignment = NSTextAlignmentLeft;
        currentTimeLabel.text = @"0:00";
        [self.contentView addSubview:currentTimeLabel];
        [self setValue:currentTimeLabel forKey:@"currentTimeLabel"];
        
        // 创建总时长标签
        UILabel *totalDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
        totalDurationLabel.textColor = [UIColor whiteColor];
        totalDurationLabel.font = [UIFont systemFontOfSize:12];
        totalDurationLabel.textAlignment = NSTextAlignmentRight;
        
        // 从模型中获取总时长
        if ([model respondsToSelector:@selector(video)]) {
            id video = [model video];
            if ([video respondsToSelector:@selector(duration)]) {
                // 使用更安全的方式获取视频时长，避免performSelector
                NSTimeInterval duration = 0.0;
                
                // 首先尝试直接使用KVC
                id durationValue = [video valueForKey:@"duration"];
                if ([durationValue isKindOfClass:[NSNumber class]]) {
                    duration = [(NSNumber *)durationValue doubleValue];
                } else if ([durationValue isKindOfClass:[NSDecimalNumber class]]) {
                    duration = [(NSDecimalNumber *)durationValue doubleValue];
                } else {
                    // 尝试获取原始视频时长
                    id rawDuration = [video valueForKey:@"rawDuration"];
                    if ([rawDuration isKindOfClass:[NSNumber class]]) {
                        duration = [(NSNumber *)rawDuration doubleValue];
                    } else if ([rawDuration isKindOfClass:[NSDecimalNumber class]]) {
                        duration = [(NSDecimalNumber *)rawDuration doubleValue];
                    } else {
                        // 尝试获取视频模型
                        id videoModel = [video valueForKey:@"videoModel"];
                        if (videoModel) {
                            id modelDuration = [videoModel valueForKey:@"duration"];
                            if ([modelDuration isKindOfClass:[NSNumber class]]) {
                                duration = [(NSNumber *)modelDuration doubleValue];
                            } else if ([modelDuration isKindOfClass:[NSDecimalNumber class]]) {
                                duration = [(NSDecimalNumber *)modelDuration doubleValue];
                            }
                        }
                    }
                }
                
                // 设置总时长标签
                NSInteger minutes = duration / 60;
                NSInteger seconds = (NSInteger)duration % 60;
                totalDurationLabel.text = [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
            }
        }
        
        [self.contentView addSubview:totalDurationLabel];
        
        // 设置约束，将时间标签放在进度条附近
        // 注意：这里的约束位置可能需要根据实际UI进行调整
        [currentTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [totalDurationLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        // 找到进度条
        UIView *progressBar = [self.contentView viewWithTag:1000]; // 假设进度条的tag是1000，需要根据实际情况调整
        if (progressBar) {
            // 将时间标签放在进度条下方
            [NSLayoutConstraint activateConstraints:@[
                [currentTimeLabel.leadingAnchor constraintEqualToAnchor:progressBar.leadingAnchor],
                [currentTimeLabel.topAnchor constraintEqualToAnchor:progressBar.bottomAnchor constant:5],
                
                [totalDurationLabel.trailingAnchor constraintEqualToAnchor:progressBar.trailingAnchor],
                [totalDurationLabel.topAnchor constraintEqualToAnchor:progressBar.bottomAnchor constant:5]
            ]];
        } else {
            // 如果找不到进度条，将时间标签放在视频底部
            [NSLayoutConstraint activateConstraints:@[
                [currentTimeLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
                [currentTimeLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20],
                
                [totalDurationLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
                [totalDurationLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20]
            ]];
        }
    }
}
- (void)configureWithModel:(id)model {
    %orig;
    // 应用全局隐藏状态
    self.elementsHidden = [BHIManager elementsHiddenGlobal];
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
        // 如果全局状态是隐藏，则立即应用隐藏效果
        if (self.elementsHidden) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                AWEAwemeBaseViewController *rootVC = self.viewController;
                if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                    TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
                    [interactionController hideAllElements:true exceptArray:nil];
                    // 更新按钮图标
                    UIButton *hideButton = (UIButton *)[self viewWithTag:999];
                    if (hideButton) {
                        [hideButton setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
                    }
                }
            });
        }
    }
}
%new - (void)addDownloadButton {
    // 先检查是否已存在下载按钮
    if ([self viewWithTag:998]) {
        return; // 如果已存在，直接返回
    }
    
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down.circle.fill"] forState:UIControlStateNormal];
    [downloadButton setTintColor:[UIColor whiteColor]];
    [self addSubview:downloadButton];

    [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
        ]];
}
%new - (void)downloadHDVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", as]];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadPhotos:(TTKPhotoAlbumDetailCellController *)rootVC photoIndex:(unsigned long)index {
    AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];
            NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
            AWEPhotoAlbumPhoto *currentPhoto = [photos objectAtIndex:index];

                NSURL *downloadableURL = [currentPhoto.originPhotoURL bestURLtoDownload];
                self.fileextension = [currentPhoto.originPhotoURL bestURLtoDownloadFormat];
                if (downloadableURL) {
                    BHDownload *dwManager = [[BHDownload alloc] init];
                    [dwManager downloadFileWithURL:downloadableURL];
                    [dwManager setDelegate:self];
                    self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                    self.hud.textLabel.text = @"Downloading";
                     [self.hud showInView:topMostController().view];
                }
            
    }

%new - (void)downloadPhotos:(TTKPhotoAlbumDetailCellController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];

            NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
            NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];

            for (AWEPhotoAlbumPhoto *currentPhoto in photos) {
                NSURL *downloadableURL = [currentPhoto.originPhotoURL bestURLtoDownload];
                self.fileextension = [currentPhoto.originPhotoURL bestURLtoDownloadFormat];
                if (downloadableURL) {
                    [fileURLs addObject:downloadableURL];
                }
            }

            BHMultipleDownload *dwManager = [[BHMultipleDownload alloc] init];
            [dwManager setDelegate:self];
            [dwManager downloadFiles:fileURLs];
            self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            self.hud.textLabel.text = @"Downloading";
            [self.hud showInView:topMostController().view];

}
%new - (void)downloadMusic:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = @"mp3";
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)copyMusic:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [((AWEMusicModel *)rootVC.model.music).playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"Could Not Copy Music." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyVideo:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyDecription:(AWEAwemeBaseViewController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    if (video_description) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = video_description;
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)downloadButtonHandler:(UIButton *)sender {
    if ([self.viewController isKindOfClass:%c(TTKPhotoAlbumDetailCellController)]) {
        TTKPhotoAlbumDetailCellController *rootVC = (TTKPhotoAlbumDetailCellController *)self.viewController;
        AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];
        NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
        unsigned long photosCount = [photos count];
        NSMutableArray <UIAction *> *photosActions = [NSMutableArray array];
        for (int i = 0; i < photosCount; i++) {
            NSString *title = [NSString stringWithFormat:BHTikTokLocalizedString(@"Download Photo %d", nil), i+1];
            UIAction *action = [UIAction actionWithTitle:title
                                                   image:[UIImage systemImageNamed:@"photo.fill"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
                [self downloadPhotos:rootVC photoIndex:i];
            }];
            [photosActions addObject:action];

        }
        UIAction *allPhotosAction = [UIAction actionWithTitle:@"Download All Photos"
                                                        image:[UIImage systemImageNamed:@"photo.fill"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadPhotos:rootVC];
        }];
        [photosActions addObject:allPhotosAction];
        UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                                image:[UIImage systemImageNamed:@"music.note"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadMusic:rootVC];
        }];
        UIAction *action3 = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Music Link", nil)
                                                image:[UIImage systemImageNamed:@"link"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self copyMusic:rootVC];
        }];
        UIAction *action4 = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Video Link", nil)
                                                image:[UIImage systemImageNamed:@"link"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self copyVideo:rootVC];
        }];
        UIAction *action5 = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Description", nil)
                                                image:[UIImage systemImageNamed:@"note.text"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self copyDecription:rootVC];
        }];
        UIMenu *PhotosMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Download Photos Menu", nil)
                                          children:photosActions];
        UIMenu *downloadMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Downloads Menu", nil)
                                            children:@[action2]];
        UIMenu *copyMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Copy Menu", nil)
                                        children:@[action3, action4, action5]];
        UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[PhotosMenu, downloadMenu, copyMenu]];
        [sender setMenu:mainMenu];
        sender.showsMenuAsPrimaryAction = YES;
    } else if ([self.viewController isKindOfClass:%c(TTKPhotoAlbumFeedCellController)]) {
        TTKPhotoAlbumFeedCellController *rootVC = (TTKPhotoAlbumFeedCellController *)self.viewController;
        AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];
        NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
        unsigned long photosCount = [photos count];
        NSMutableArray <UIAction *> *photosActions = [NSMutableArray array];
        for (int i = 0; i < photosCount; i++) {
            NSString *title = [NSString stringWithFormat:@"Download Photo %d", i+1];
            UIAction *action = [UIAction actionWithTitle:title
                                                   image:[UIImage systemImageNamed:@"photo.fill"]
                                              identifier:nil
                                                 handler:^(__kindof UIAction * _Nonnull action) {
                [self downloadPhotos:rootVC photoIndex:i];
            }];
            [photosActions addObject:action];

        }
        UIAction *allPhotosAction = [UIAction actionWithTitle:@"Download Photos"
                                                        image:[UIImage systemImageNamed:@"photo.fill"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadPhotos:rootVC];
        }];
        [photosActions addObject:allPhotosAction];
        UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                                image:[UIImage systemImageNamed:@"music.note"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadMusic:rootVC];
        }];
        UIAction *action3 = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Music Link", nil)
                                                image:[UIImage systemImageNamed:@"link"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self copyMusic:rootVC];
        }];
        UIAction *action4 = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Video Link", nil)
                                                image:[UIImage systemImageNamed:@"link"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self copyVideo:rootVC];
        }];
        UIAction *action5 = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Description", nil)
                                                image:[UIImage systemImageNamed:@"note.text"]
                                           identifier:nil
                                              handler:^(__kindof UIAction * _Nonnull action) {
            [self copyDecription:rootVC];
        }];
        UIMenu *PhotosMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Download Photos Menu", nil)
                                          children:photosActions];
        UIMenu *downloadMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Downloads Menu", nil)
                                            children:@[action2]];
        UIMenu *copyMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Copy Menu", nil)
                                        children:@[action3, action4, action5]];
        UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[PhotosMenu, downloadMenu, copyMenu]];
        [sender setMenu:mainMenu];
        sender.showsMenuAsPrimaryAction = YES;
    } else if ([self.viewController isKindOfClass:%c(AWEAwemeBaseViewController)]) {
        // 处理普通视频的情况
        AWEAwemeBaseViewController *rootVC = (AWEAwemeBaseViewController *)self.viewController;
        
        UIAction *hdAction = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Download HD Video", nil)
                                                 image:[UIImage systemImageNamed:@"video.fill"]
                                            identifier:nil
                                               handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadHDVideo:rootVC];
        }];
        
        UIAction *sdAction = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Download SD Video", nil)
                                                 image:[UIImage systemImageNamed:@"video.fill"]
                                            identifier:nil
                                               handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadVideo:rootVC];
        }];
        
        UIAction *musicAction = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Download Music", nil)
                                                    image:[UIImage systemImageNamed:@"music.note"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadMusic:rootVC];
        }];
        
        UIAction *copyMusicAction = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Music Link", nil)
                                                         image:[UIImage systemImageNamed:@"link"]
                                                    identifier:nil
                                                       handler:^(__kindof UIAction * _Nonnull action) {
            [self copyMusic:rootVC];
        }];
        
        UIAction *copyVideoAction = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Video Link", nil)
                                                         image:[UIImage systemImageNamed:@"link"]
                                                    identifier:nil
                                                       handler:^(__kindof UIAction * _Nonnull action) {
            [self copyVideo:rootVC];
        }];
        
        UIAction *copyDescAction = [UIAction actionWithTitle:BHTikTokLocalizedString(@"Copy Description", nil)
                                                        image:[UIImage systemImageNamed:@"note.text"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
            [self copyDecription:rootVC];
        }];
        
        UIMenu *downloadMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Downloads Menu", nil)
                                            children:@[hdAction, sdAction, musicAction]];
        UIMenu *copyMenu = [UIMenu menuWithTitle:BHTikTokLocalizedString(@"Copy Menu", nil)
                                        children:@[copyMusicAction, copyVideoAction, copyDescAction]];
        UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[downloadMenu, copyMenu]];
        
        [sender setMenu:mainMenu];
        sender.showsMenuAsPrimaryAction = YES;
    }
}
%new - (void)addHideElementButton {
    UIButton *hideElementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [hideElementButton setTag:999];
    [hideElementButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [hideElementButton addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    if (self.elementsHidden) {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
    } else {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
    }

    if (![self viewWithTag:999]) {
        [hideElementButton setTintColor:[UIColor whiteColor]];
        [self addSubview:hideElementButton];

        [NSLayoutConstraint activateConstraints:@[
            [hideElementButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:50],
            [hideElementButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [hideElementButton.widthAnchor constraintEqualToConstant:30],
            [hideElementButton.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}
%new - (void)hideElementButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
        TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
        
        // 切换全局隐藏状态
        BOOL currentGlobalState = [BHIManager elementsHiddenGlobal];
        [BHIManager setElementsHiddenGlobal:!currentGlobalState];
        
        // 应用到当前视频
        if (!currentGlobalState) {
            // 当前未隐藏，设置为隐藏
            self.elementsHidden = true;
            [interactionController hideAllElements:true exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
        } else {
            // 当前已隐藏，设置为显示
            self.elementsHidden = false;
            [interactionController hideAllElements:false exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
        }
    }
}

%new - (void)downloaderProgress:(float)progress {
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
}
%new - (void)downloaderDidFinishDownloadingAllFiles:(NSMutableArray<NSURL *> *)downloadedFilePaths {
    [self.hud dismiss];
    if ([BHIManager shareSheet]) {
        [BHIManager showSaveVC:downloadedFilePaths];
    }
    else {
        for (NSURL *url in downloadedFilePaths) {
            [BHIManager saveMedia:url fileExtension:self.fileextension];
        }
    }
}
%new - (void)downloaderDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}

%new - (void)downloadProgress:(float)progress {
    self.progressView.progress = progress;
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
    self.hud.tapOutsideBlock = ^(JGProgressHUD * _Nonnull HUD) {
        self.hud.textLabel.text = @"Backgrounding ✌️";
        [self.hud dismissAfterDelay:0.4];
    };
}
%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *DocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *newFilePath = [[NSURL fileURLWithPath:DocPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, self.fileextension]];
    [manager moveItemAtURL:filePath toURL:newFilePath error:nil];
    [self.hud dismiss];
    NSArray *audioExtensions = @[@"mp3", @"aac", @"wav", @"m4a", @"ogg", @"flac", @"aiff", @"wma"];
    if ([BHIManager shareSheet] || [audioExtensions containsObject:self.fileextension]) {
        [BHIManager showSaveVC:@[newFilePath]];
    }
    else {
        [BHIManager saveMedia:newFilePath fileExtension:self.fileextension];
    }
}
%new - (void)downloadDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}
%end

%hook AWEAwemeDetailTableViewCell
%property (nonatomic, strong) JGProgressHUD *hud;
%property(nonatomic, assign) BOOL elementsHidden;
%property (nonatomic, retain) UIProgressView *progressView;
%property (nonatomic, retain) NSString *fileextension;
- (void)configWithModel:(id)model {
    %orig;
    self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
    }
}
- (void)configureWithModel:(id)model {
    %orig;
    self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
    }
}
%new - (void)addDownloadButton {
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down.circle.fill"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:100],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:100],
            [downloadButton.heightAnchor constraintEqualToConstant:100],
        ]];
    }
}
%new - (void)downloadHDVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", as]];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
        self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadMusic:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
        self.fileextension = @"mp3";
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)copyMusic:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [((AWEMusicModel *)rootVC.model.music).playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyVideo:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyDecription:(AWEAwemeBaseViewController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    if (video_description) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = video_description;
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void) downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
        // 创建下载菜单
        UIAction *hdVideoAction = [UIAction actionWithTitle:@"Download HD Video"
                                                       image:[UIImage systemImageNamed:@"video.fill"]
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadHDVideo:rootVC];
        }];
        
        UIAction *sdVideoAction = [UIAction actionWithTitle:@"Download SD Video"
                                                       image:[UIImage systemImageNamed:@"video.badge.plus"]
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadVideo:rootVC];
        }];
        
        UIAction *musicAction = [UIAction actionWithTitle:@"Download Music"
                                                    image:[UIImage systemImageNamed:@"music.note"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
            [self downloadMusic:rootVC];
        }];
        
        UIAction *copyVideoAction = [UIAction actionWithTitle:@"Copy Video Link"
                                                        image:[UIImage systemImageNamed:@"link"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
            [self copyVideo:rootVC];
        }];
        
        UIAction *copyMusicAction = [UIAction actionWithTitle:@"Copy Music Link"
                                                        image:[UIImage systemImageNamed:@"link"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
            [self copyMusic:rootVC];
        }];
        
        UIAction *copyDescAction = [UIAction actionWithTitle:@"Copy Description"
                                                        image:[UIImage systemImageNamed:@"note.text"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction * _Nonnull action) {
            [self copyDecription:rootVC];
        }];
        
        UIMenu *downloadMenu = [UIMenu menuWithTitle:@"Download Options"
                                             children:@[hdVideoAction, sdVideoAction, musicAction]];
        UIMenu *copyMenu = [UIMenu menuWithTitle:@"Copy Options"
                                        children:@[copyVideoAction, copyMusicAction, copyDescAction]];
        UIMenu *mainMenu = [UIMenu menuWithTitle:@"" 
                                         children:@[downloadMenu, copyMenu]];
        
        [sender setMenu:mainMenu];
        sender.showsMenuAsPrimaryAction = YES;
    }
}
%new - (void)addHideElementButton {
    UIButton *hideElementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [hideElementButton setTag:999];
    [hideElementButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [hideElementButton addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    if (self.elementsHidden) {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
    } else {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
    }

    if (![self viewWithTag:999]) {
        [hideElementButton setTintColor:[UIColor whiteColor]];
        [self addSubview:hideElementButton];

        [NSLayoutConstraint activateConstraints:@[
            [hideElementButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:50],
            [hideElementButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [hideElementButton.widthAnchor constraintEqualToConstant:30],
            [hideElementButton.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}
%new - (void)hideElementButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
        TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
        if (self.elementsHidden) {
            self.elementsHidden = false;
            [interactionController hideAllElements:false exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
        } else {
            self.elementsHidden = true;
            [interactionController hideAllElements:true exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
        }
    }
}

%new - (void)downloadProgress:(float)progress {
        self.hud.tapOutsideBlock = ^(JGProgressHUD * _Nonnull HUD) {
        self.hud.textLabel.text = @"Backgrounding ✌️";
        [self.hud dismissAfterDelay:0.4];
    };
    self.progressView.progress = progress;
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
}
%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *DocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *newFilePath = [[NSURL fileURLWithPath:DocPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, self.fileextension]];
    [manager moveItemAtURL:filePath toURL:newFilePath error:nil];
    [self.hud dismiss];
    NSArray *audioExtensions = @[@"mp3", @"aac", @"wav", @"m4a", @"ogg", @"flac", @"aiff", @"wma"];
    if ([BHIManager shareSheet] || [audioExtensions containsObject:self.fileextension]) {
        [BHIManager showSaveVC:@[newFilePath]];
    }
    else {
        [BHIManager saveMedia:newFilePath fileExtension:self.fileextension];
    }
}
%new - (void)downloadDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}
%end

%hook TTKStoryDetailTableViewCell
    // TODO...
%end

%hook AWEURLModel
%new - (NSString *)bestURLtoDownloadFormat {
    NSString *bestURLFormat = nil;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"]) {
            bestURLFormat = @"mp4";
            break;
        } else if ([url containsString:@".jpeg"]) {
            bestURLFormat = @"jpeg";
            break;
        } else if ([url containsString:@".png"]) {
            bestURLFormat = @"png";
            break;
        } else if ([url containsString:@".mp3"]) {
            bestURLFormat = @"mp3";
            break;
        } else if ([url containsString:@".m4a"]) {
            bestURLFormat = @"m4a";
            break;
        }
    }
    if (bestURLFormat == nil) {
        bestURLFormat = @"mp4"; // 默认使用mp4格式而不是m4a，因为大部分下载是视频
    }

    return bestURLFormat;
}
%new - (NSURL *)bestURLtoDownload {
    NSURL *bestURL;
    // 优先选择高清视频URL
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"]) {
            bestURL = [NSURL URLWithString:url];
            break; // 找到第一个视频URL就返回，通常是高清的
        }
    }
    
    // 如果没有找到视频URL，再查找图片或音频URL
    if (bestURL == nil) {
        for (NSString *url in self.originURLList) {
            if ([url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
                bestURL = [NSURL URLWithString:url];
                break;
            }
        }
    }

    // 如果还是没有找到，使用第一个URL
    if (bestURL == nil && self.originURLList.count > 0) {
        bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
    }

    return bestURL;
}
%end

%hook NSFileManager
-(BOOL)fileExistsAtPath:(id)arg1 {
	for (NSString *file in jailbreakPaths) {
		if ([arg1 isEqualToString:file]) {
			return NO;
		}
	}
	return %orig;
}
-(BOOL)fileExistsAtPath:(id)arg1 isDirectory:(BOOL*)arg2 {
	for (NSString *file in jailbreakPaths) {
		if ([arg1 isEqualToString:file]) {
			return NO;
		}
	}
	return %orig;
}
%end
%hook BDADeviceHelper
+(bool)isJailBroken {
	return NO;
}
%end

%hook UIDevice
+(bool)btd_isJailBroken {
	return NO;
}
%end

%hook TTInstallUtil
+(bool)isJailBroken {
	return NO;
}
%end

%hook AppsFlyerUtils
+(bool)isJailbrokenWithSkipAdvancedJailbreakValidation:(bool)arg2 {
	return NO;
}
%end

%hook PIPOIAPStoreManager
-(bool)_pipo_isJailBrokenDeviceWithProductID:(id)arg2 orderID:(id)arg3 {
	return NO;
}
%end

%hook IESLiveDeviceInfo
+(bool)isJailBroken {
	return NO;
}
%end

%hook PIPOStoreKitHelper
-(bool)isJailBroken {
	return NO;
}
%end

%hook BDInstallNetworkUtility
+(bool)isJailBroken {
	return NO;
}
%end

%hook TTAdSplashDeviceHelper
+(bool)isJailBroken {
	return NO;
}
%end

%hook GULAppEnvironmentUtil
+(bool)isFromAppStore {
	return YES;
}
+(bool)isAppStoreReceiptSandbox {
	return NO;
}
+(bool)isAppExtension {
	return YES;
}
%end

%hook FBSDKAppEventsUtility
+(bool)isDebugBuild {
	return NO;
}
%end

%hook AWEAPMManager
+(id)signInfo {
	return @"AppStore";
}
%end

%hook NSBundle
-(id)pathForResource:(id)arg1 ofType:(id)arg2 {
	if ([arg2 isEqualToString:@"mobileprovision"]) {
		return nil;
	}
	return %orig;
}
%end
%hook AWESecurity
- (void)resetCollectMode {
	return;
}
%end
%hook MSManagerOV
- (id)setMode {
	return (id (^)(id)) ^{
	};
}
%end
%hook MSConfigOV
- (id)setMode {
	return (id (^)(id)) ^{
	};
}
%end


%ctor {
    jailbreakPaths = @[
        @"/Applications/Cydia.app", @"/Applications/blackra1n.app",
        @"/Applications/FakeCarrier.app", @"/Applications/Icy.app",
        @"/Applications/IntelliScreen.app", @"/Applications/MxTube.app",
        @"/Applications/RockApp.app", @"/Applications/SBSettings.app", @"/Applications/WinterBoard.app",
        @"/.cydia_no_stash", @"/.installed_unc0ver", @"/.bootstrapped_electra",
        @"/usr/libexec/cydia/firmware.sh", @"/usr/libexec/ssh-keysign", @"/usr/libexec/sftp-server",
        @"/usr/bin/ssh", @"/usr/bin/sshd", @"/usr/sbin/sshd",
        @"/var/lib/cydia", @"/var/lib/dpkg/info/mobilesubstrate.md5sums",
        @"/var/log/apt", @"/usr/share/jailbreak/injectme.plist", @"/usr/sbin/frida-server",
        @"/Library/MobileSubstrate/CydiaSubstrate.dylib", @"/Library/TweakInject",
        @"/Library/MobileSubstrate/MobileSubstrate.dylib", @"Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist", @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        @"/System/Library/LaunchDaemons/com.ikey.bbot.plist", @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist", @"/System/Library/CoreServices/SystemVersion.plist",
        @"/private/var/mobile/Library/SBSettings/Themes", @"/private/var/lib/cydia",
        @"/private/var/tmp/cydia.log", @"/private/var/log/syslog",
        @"/private/var/cache/apt/", @"/private/var/lib/apt",
        @"/private/var/Users/", @"/private/var/stash",
        @"/usr/lib/libjailbreak.dylib", @"/usr/lib/libz.dylib",
        @"/usr/lib/system/introspectionNSZombieEnabled",
        @"/usr/lib/dyld",
        @"/jb/amfid_payload.dylib", @"/jb/libjailbreak.dylib",
        @"/jb/jailbreakd.plist", @"/jb/offsets.plist",
        @"/jb/lzma",
        @"/hmd_tmp_file",
        @"/etc/ssh/sshd_config", @"/etc/apt/undecimus/undecimus.list",
        @"/etc/apt/sources.list.d/sileo.sources", @"/etc/apt/sources.list.d/electra.list",
        @"/etc/apt", @"/etc/ssl/certs", @"/etc/ssl/cert.pem",
        @"/bin/sh", @"/bin/bash",
    ];
    %init;
}