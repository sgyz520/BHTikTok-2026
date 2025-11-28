#import "TikTokHeaders.h"

NSArray *jailbreakPaths;

// 全局变量来跟踪隐藏状态，确保在视频切换时保持状态
static BOOL globalElementsHidden = NO;

// 添加方法声明以解决编译错误
@interface UIViewController (BHTikTokAdditions)
- (AWEAwemeModel *)model;
- (AWEAwemeModel *)currentAwemeModel;
@end

@interface NSObject (BHTikTokAdditions)
- (void)findAndUpdateInteractionViews:(UIView *)view;
- (void)updateVideoModels;
@end

// 前向声明类以解决编译错误
@class AWEVideoPlayViewController;
@class AWEVideoPlayerController;
@class AWEAwemePlayInteractionView;

static void showAlert(NSString *title, NSString *message, NSString *okTitle, NSString *cancelTitle, void (^okHandler)(void)) {
  Class alertViewClass = NSClassFromString(@"AWEUIAlertView");
  if (alertViewClass && [alertViewClass respondsToSelector:@selector(showAlertWithTitle:description:image:actionButtonTitle:cancelButtonTitle:actionBlock:cancelBlock:)]) {
    [alertViewClass showAlertWithTitle:title description:message image:nil actionButtonTitle:okTitle cancelButtonTitle:cancelTitle actionBlock:^{ okHandler(); } cancelBlock:nil];
  } else {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ okHandler(); }]];
    [topMostController() presentViewController:ac animated:YES completion:nil];
  }
}

static void showConfirmation(void (^okHandler)(void)) {
  showAlert([BHIManager L:@"BHTikTok, Hi"], [BHIManager L:@"Are you sure?"], [BHIManager L:@"Yes"], [BHIManager L:@"No"], okHandler);
}

static NSString *flagEmojiForCountryCode(NSString *code) {
  if (!code || code.length < 2) return @"🌍";
  NSString *upper = [code.uppercaseString substringToIndex:2];
  unichar a = [upper characterAtIndex:0];
  unichar b = [upper characterAtIndex:1];
  
  // 验证字符是否在A-Z范围内
  if (a < 'A' || a > 'Z' || b < 'A' || b > 'Z') {
    return @"🌍";
  }
  
  int base = 127397;
  int ua = (int)(a + base);
  int ub = (int)(b + base);
  
  // 验证生成的Unicode字符是否在国旗emoji范围内
  if (ua < 0x1F1E6 || ua > 0x1F1FF || ub < 0x1F1E6 || ub > 0x1F1FF) {
    return @"🌍";
  }
  
  // 转换回unichar
  unichar flagChars[2];
  flagChars[0] = (unichar)ua;
  flagChars[1] = (unichar)ub;
  
  NSString *flagEmoji = [[NSString alloc] initWithCharacters:flagChars length:2];
  
  // 检查生成的emoji是否有效
  if (!flagEmoji || flagEmoji.length == 0) {
    return @"🌍";
  }
  
  return flagEmoji;
}

%hook AppDelegate
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    // Initialize language setting before calling orig
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedLanguage = [defaults objectForKey:@"BHTikTok_Language"];
    
    // If no saved language, use system language as default
    if (!savedLanguage) {
        NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
        NSString *systemLanguage = languages.firstObject;
        
        // Check if system language is Chinese
        if ([systemLanguage hasPrefix:@"zh"]) {
            savedLanguage = @"zh-Hans";
        } else {
            savedLanguage = @"en";
        }
        
        // Save the default language
        [defaults setObject:savedLanguage forKey:@"BHTikTok_Language"];
        [defaults synchronize];
    }
    
    // Apply saved language preference
    [self applyLanguageSetting:savedLanguage];
    
    %orig;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"flex_enebaled"]) {
        [[%c(FLEXManager) performSelector:@selector(sharedManager)] performSelector:@selector(showExplorer)];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"BHTikTokFirstRun"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"BHTikTokFirstRun" forKey:@"BHTikTokFirstRun"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"hide_ads"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"download_button"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"remove_elements_button"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"show_porgress_bar"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"save_profile"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"copy_profile_information"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"extended_bio"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"extendedComment"];
    }
    [BHIManager cleanCache];
    return true;
}

%new - (void)applyLanguageSetting:(NSString *)language {
    // Apply language setting immediately
    [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"BHTikTok_Language"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Force localization update by reloading the bundle
    NSBundle *bundle = [NSBundle mainBundle];
    [bundle localizedStringForKey:@"" value:@"" table:nil];
    
    // Post notification to inform views to update their text
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LanguageChanged" object:language];
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
    
    // 检查是否需要显示视频上传时间
    if (![BHIManager videoUploadDate]) {
        return;
    }
    
    // 清理旧的标签
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
    if (!model) {
        return;
    }
    
    AWEAwemeStatisticsModel *statistics = [model statistics];
    NSNumber *createTime = [model createTime];
    
    // 如果没有创建时间，尝试从其他属性获取
    if (!createTime) {
        createTime = [model valueForKey:@"createTimeFromServer"];
    }
    
    if (!createTime) {
        return;
    }
    
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
    
    // 显示点赞数（如果启用）
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
    
    // 显示上传时间
    [self.contentView addSubview:clockImage];
    [NSLayoutConstraint activateConstraints:@[
            [clockImage.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:([BHIManager videoLikeCount] ? 128 : 110)],
            [clockImage.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:4],
            [clockImage.widthAnchor constraintEqualToConstant:16],
            [clockImage.heightAnchor constraintEqualToConstant:16],
        ]];
    [self.contentView addSubview:uploadDateLabel];
    [NSLayoutConstraint activateConstraints:@[
            [uploadDateLabel.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:([BHIManager videoLikeCount] ? 127 : 109)],
            [uploadDateLabel.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor constant:23],
            [uploadDateLabel.widthAnchor constraintEqualToConstant:200],
            [uploadDateLabel.heightAnchor constraintEqualToConstant:16],
        ]];
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
            userVideoCountLabel.text = [NSString stringWithFormat:@"Video Count: %@", userVideoCount];
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
        showAlert([BHIManager L:@"Save profile image"], [BHIManager L:@"Do you want to save this image"], [BHIManager L:@"Yes"], [BHIManager L:@"No"], ^{
            UIImageWriteToSavedPhotosAlbum([self bd_baseImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        });
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
        showAlert([BHIManager L:@"Copy bio"], [BHIManager L:@"Do you want to copy this text to clipboard"], [BHIManager L:@"Yes"], [BHIManager L:@"No"], ^{
             if (profileDescription) {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = profileDescription;
             }
        });
    }
}
%end

%hook AWEPlayInteractionAuthorView
- (NSString *)emojiForCountryCode:(NSString *)countryCode {
    // 禁用emoji显示，避免出现方框
    return nil;
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
        Class CellClass = %c(TTKSettingsBaseCellPlugin);
        Class ItemClass = %c(AWESettingItemModel);
        if (!CellClass || !ItemClass) { return; }
        TTKSettingsBaseCellPlugin *BHTikTokSettingsPluginCell = [[CellClass alloc] initWithPluginContext:self.context];

        AWESettingItemModel *BHTikTokSettingsItemModel = [[ItemClass alloc] initWithIdentifier:@"bhtiktok_settings"];
        [BHTikTokSettingsItemModel setTitle:[BHIManager L:@"BHTikTok++ settings"]];
    [BHTikTokSettingsItemModel setDetail:[BHIManager L:@"BHTikTok++ settings"]];
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
    return [BHIManager progressBar] || %orig;
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
            NSString *textOut = username;
            // 不再添加国旗emoji，避免显示方框
            %orig(textOut);
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

// 添加新的方法来处理视频播放结束时的自动播放
- (void)playerDidPlayToEnd:(id)arg1 {
    if ([BHIManager autoPlay]) {
        // 尝试多种方式获取父控制器
        UIViewController *parentVC = nil;
        
        // 方式1: 通过container.parentViewController
        if (self.container && self.container.parentViewController) {
            parentVC = self.container.parentViewController;
            if ([parentVC isKindOfClass:%c(AWENewFeedTableViewController)]) {
                [(AWENewFeedTableViewController *)parentVC scrollToNextVideo];
                return;
            }
        }
        
        // 方式2: 通过container的下一个响应者
        if (!parentVC && self.container) {
            UIResponder *nextResponder = self.container.nextResponder;
            while (nextResponder) {
                if ([nextResponder isKindOfClass:[UIViewController class]]) {
                    UIViewController *vc = (UIViewController *)nextResponder;
                    if ([vc isKindOfClass:%c(AWENewFeedTableViewController)]) {
                        [(AWENewFeedTableViewController *)vc scrollToNextVideo];
                        return;
                    }
                }
                nextResponder = nextResponder.nextResponder;
            }
        }
        
        // 方式3: 通过当前窗口的根控制器
        if (!parentVC) {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow && keyWindow.rootViewController) {
                UIViewController *rootVC = keyWindow.rootViewController;
                
                // 查找导航控制器中的视图控制器
                if ([rootVC isKindOfClass:[UINavigationController class]]) {
                    UINavigationController *navController = (UINavigationController *)rootVC;
                    if (navController.viewControllers.count > 0) {
                        parentVC = navController.viewControllers.lastObject;
                    }
                } else {
                    parentVC = rootVC;
                }
                
                // 检查当前控制器
                if (parentVC && [parentVC isKindOfClass:%c(AWENewFeedTableViewController)]) {
                    [(AWENewFeedTableViewController *)parentVC scrollToNextVideo];
                    return;
                }
                
                // 查找子视图控制器
                if (parentVC && parentVC.childViewControllers.count > 0) {
                    for (UIViewController *childVC in parentVC.childViewControllers) {
                        if ([childVC isKindOfClass:%c(AWENewFeedTableViewController)]) {
                            [(AWENewFeedTableViewController *)childVC scrollToNextVideo];
                            return;
                        }
                    }
                }
                
                // 查找呈现的视图控制器
                if (parentVC && parentVC.presentedViewController) {
                    UIViewController *presentedVC = parentVC.presentedViewController;
                    if ([presentedVC isKindOfClass:%c(AWENewFeedTableViewController)]) {
                        [(AWENewFeedTableViewController *)presentedVC scrollToNextVideo];
                        return;
                    }
                    
                    // 如果是导航控制器，检查其视图控制器
                    if ([presentedVC isKindOfClass:[UINavigationController class]]) {
                        UINavigationController *navController = (UINavigationController *)presentedVC;
                        for (UIViewController *vc in navController.viewControllers) {
                            if ([vc isKindOfClass:%c(AWENewFeedTableViewController)]) {
                                [(AWENewFeedTableViewController *)vc scrollToNextVideo];
                                return;
                            }
                        }
                    }
                }
            }
        }
        
        // 方式4: 通过全局查找所有窗口中的视图控制器
        NSArray *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *window in windows) {
            UIViewController *rootVC = window.rootViewController;
            if (rootVC) {
                // 递归查找所有视图控制器
                NSMutableArray *viewControllers = [NSMutableArray array];
                
                // 内联递归查找逻辑
                NSMutableArray *stack = [NSMutableArray arrayWithObject:rootVC];
                while (stack.count > 0) {
                    UIViewController *viewController = [stack lastObject];
                    [stack removeLastObject];
                    [viewControllers addObject:viewController];
                    
                    // 添加子视图控制器
                    for (UIViewController *childVC in viewController.childViewControllers) {
                        [stack addObject:childVC];
                    }
                    
                    // 添加呈现的视图控制器
                    if (viewController.presentedViewController) {
                        [stack addObject:viewController.presentedViewController];
                    }
                    
                    // 如果是导航控制器，添加其视图控制器
                    if ([viewController isKindOfClass:[UINavigationController class]]) {
                        UINavigationController *navController = (UINavigationController *)viewController;
                        for (UIViewController *vc in navController.viewControllers) {
                            [stack addObject:vc];
                        }
                    }
                    
                    // 如果是标签栏控制器，添加其视图控制器
                    if ([viewController isKindOfClass:[UITabBarController class]]) {
                        UITabBarController *tabController = (UITabBarController *)viewController;
                        for (UIViewController *vc in tabController.viewControllers) {
                            [stack addObject:vc];
                        }
                    }
                }
                
                for (UIViewController *vc in viewControllers) {
                    if ([vc isKindOfClass:%c(AWENewFeedTableViewController)]) {
                        [(AWENewFeedTableViewController *)vc scrollToNextVideo];
                        return;
                    }
                }
            }
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
    }else {
        %orig;
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
%hook AWEProfileEditTextViewController
- (NSInteger)maxTextLength {
    if ([BHIManager extendedBio]) {
        return 222;
    }

    return %orig;
}
%end

// 获取国家/地区名称，简化版本不再处理多级属地
static NSString *getCountryNameForCode(NSString *countryCode) {
    if (!countryCode || countryCode.length == 0) {
        return nil;
    }
    
    // 检查缓存
    NSString *cacheKey = [NSString stringWithFormat:@"country_%@", countryCode];
    NSDictionary *cachedInfo = [BHIManager getCachedLocationInfo:cacheKey];
    
    if (cachedInfo) {
        NSNumber *timestamp = cachedInfo[@"timestamp"];
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        
        // 缓存24小时有效
        if (currentTime - [timestamp doubleValue] < 24 * 60 * 60) {
            return cachedInfo[@"locationInfo"];
        }
    }
    
    // 设置语言环境为中文，确保获取中文名称
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSLocale *chineseLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    
    // 获取国家/地区中文名称
    NSString *countryName = [chineseLocale displayNameForKey:NSLocaleCountryCode value:countryCode];
    
    // 如果没有找到，尝试使用当前语言环境
    if (!countryName) {
        countryName = [currentLocale displayNameForKey:NSLocaleCountryCode value:countryCode];
    }
    
    // 如果还是没有找到，返回原始代码
    if (!countryName) {
        countryName = countryCode;
    }
    
    // 保存到缓存
    NSDictionary *resultToCache = @{
        @"locationInfo": countryName,
        @"countryCode": countryCode ?: @"",
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    [BHIManager saveLocationInfoToCache:cacheKey locationInfo:resultToCache];
    
    return countryName;
}

%hook AWEPlayInteractionAuthorView

- (void)layoutSubviews {
    %orig;
    if ([BHIManager uploadRegion]){
        // 遍历所有子视图，找到UIStackView并将其x坐标设置为39.5，为地区标签腾出空间
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
        
        // 移除已存在的地区标签
        [[self viewWithTag:666] removeFromSuperview];
        
        AWEFeedCellViewController* rootVC = self.yy_viewController;
        AWEAwemeModel *model = rootVC.model;
        NSString *countryID = model.region;
        
        // 只有当countryID不为空且不是问号时才显示
        if (countryID && countryID.length > 0 && ![countryID isEqualToString:@"?"]) {
            // 根据设置决定使用多级属地显示还是只显示国家名称
            NSString *locationInfo;
            if ([BHIManager multiLevelLocation]) {
                // 由于没有城市代码，只使用国家代码获取国家名称
                locationInfo = getCountryNameForCode(countryID);
            } else {
                locationInfo = getCountryNameForCode(countryID);
            }
            
            // 获取上传时间（不再显示在作者名字后面）
            // 已移除上传时间显示，只保留IP属地
            
            // 检查位置信息是否有效
            if (!locationInfo || locationInfo.length == 0) {
                return;
            }
            
            // 创建IP属地标签（不包含上传时间）
            UILabel *uploadLabel = [[UILabel alloc] init];
            uploadLabel.text = [NSString stringWithFormat:@"%@·", locationInfo]; // 在IP属地后添加点作为分隔符
            uploadLabel.tag = 666;
            
            // 设置字体和样式
            UIFont *labelFont = [UIFont systemFontOfSize:14];
            uploadLabel.font = labelFont;
            uploadLabel.textAlignment = NSTextAlignmentLeft;
            
            // 应用颜色设置
            NSString *labelColorHex = [BHIManager uploadRegionLabelColor];
            if ([BHIManager uploadRegionRandomGradient]) {
                // 实现随机渐变色
                NSArray *gradientColors = @[
                    @"FF6B6B", @"4ECDC4", @"45B7D1", @"96CEB4", @"FFEAA7",
                    @"DDA0DD", @"98D8C8", @"FFD93D", @"6BCB77", @"FF6B9D"
                ];
                int randomIndex = arc4random_uniform((int)gradientColors.count);
                labelColorHex = gradientColors[randomIndex];
            }
            
            // 将十六进制颜色转换为UIColor
            unsigned int rgbValue;
            NSScanner *scanner = [NSScanner scannerWithString:labelColorHex];
            [scanner setScanLocation:0];
            [scanner scanHexInt:&rgbValue];
            UIColor *labelColor = [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 
                                                 green:((rgbValue & 0xFF00) >> 8)/255.0 
                                                  blue:(rgbValue & 0xFF)/255.0 
                                                 alpha:1.0];
            
            uploadLabel.textColor = labelColor;
            
            // 计算标签大小，考虑不同屏幕尺寸
            CGSize textSize = [uploadLabel.text sizeWithAttributes:@{NSFontAttributeName: labelFont}];
            CGFloat padding = 4.0; // 内边距
            CGFloat labelWidth = textSize.width + padding * 2;
            CGFloat labelHeight = 20.5; // 固定高度
            
            // 确保标签不会超出父视图边界
            CGFloat maxWidth = self.bounds.size.width * 0.3; // 最大宽度为父视图宽度的30%，因为只显示IP属地
            if (labelWidth > maxWidth) {
                labelWidth = maxWidth;
                uploadLabel.numberOfLines = 1;
                uploadLabel.adjustsFontSizeToFitWidth = YES;
                uploadLabel.minimumScaleFactor = 0.8;
            }
            
            // 设置标签位置
            CGFloat labelX = 0;
            CGFloat labelY = 2.0;
            
            uploadLabel.frame = CGRectMake(labelX, labelY, labelWidth, labelHeight);
            
            // 应用垂直偏移
            CGFloat offset = [BHIManager uploadRegionVerticalOffset];
            if (offset != 0) {
                CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(0, -offset);
                uploadLabel.transform = translationTransform;
            }
            
            // 添加阴影效果，提高可读性
            uploadLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            uploadLabel.layer.shadowOffset = CGSizeMake(0.5, 0.5);
            uploadLabel.layer.shadowOpacity = 0.3;
            uploadLabel.layer.shadowRadius = 0.5;
            
            [self addSubview:uploadLabel];
        }
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
- (void)configWithModel:(id)model {
    %orig;
    // 移除这行代码以保持隐藏状态在视频切换时不被重置
    // self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
        // 如果全局隐藏状态为true，则应用隐藏
        if (globalElementsHidden) {
            AWEAwemeBaseViewController *rootVC = self.viewController;
            if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
                [interactionController hideAllElements:true exceptArray:nil];
            }
        }
    }
}
- (void)configureWithModel:(id)model {
    %orig;
    // 移除这行代码以保持隐藏状态在视频切换时不被重置
    // self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
        // 如果全局隐藏状态为true，则应用隐藏
        if (globalElementsHidden) {
            AWEAwemeBaseViewController *rootVC = self.viewController;
            if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
                [interactionController hideAllElements:true exceptArray:nil];
            }
        }
    }
}
%new - (void)addDownloadButton {
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
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
        showAlert(@"BHTikTok, Hi", @"Could Not Copy Music.", @"OK", @"Cancel", ^{});
    }
}
%new - (void)copyVideo:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        showAlert(@"BHTikTok, Hi", @"The video dosen't have music to download.", @"OK", @"Cancel", ^{});
    }
}
%new - (void)copyDecription:(AWEAwemeBaseViewController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    if (video_description) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = video_description;
    } else {
        showAlert(@"BHTikTok, Hi", @"The video dosen't have music to download.", @"OK", @"Cancel", ^{});
    }
}
%new - (void) downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC isKindOfClass:%c(AWEFeedCellViewController)]) {

         UIAction *action1 = [UIAction actionWithTitle:@"Download Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadVideo:rootVC];
    }];
        UIAction *action0 = [UIAction actionWithTitle:@"Download HD Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadHDVideo:rootVC];
    }];
    UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                            image:[UIImage systemImageNamed:@"music.note"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadMusic:rootVC];
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[action1, action0, action2, action3, action4, action5]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    } else if ([self.viewController isKindOfClass:%c(TTKPhotoAlbumDetailCellController)]) {
        TTKPhotoAlbumDetailCellController *rootVC = self.viewController;
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
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:[photosActions arrayByAddingObjectsFromArray:@[action2, action3, action4, action5]]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    }else if ([self.viewController isKindOfClass:%c(TTKPhotoAlbumFeedCellController)]) {
        TTKPhotoAlbumFeedCellController *rootVC = self.viewController;
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
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:[photosActions arrayByAddingObjectsFromArray:@[action2, action3, action4, action5]]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    }
}
%new - (void)addHideElementButton {
    UIButton *hideElementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [hideElementButton setTag:999];
    [hideElementButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [hideElementButton addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    if (globalElementsHidden) {
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
        if (globalElementsHidden) {
            globalElementsHidden = NO;
            [interactionController hideAllElements:false exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
        } else {
            globalElementsHidden = YES;
            [interactionController hideAllElements:true exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
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
    // 移除这行代码以保持隐藏状态在视频切换时不被重置
    // self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
        // 根据全局隐藏状态应用相应的显示/隐藏状态，确保视图完全加载后再应用
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AWEAwemeBaseViewController *rootVC = self.viewController;
            if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
                [interactionController hideAllElements:globalElementsHidden exceptArray:nil];
            }
        });
    }
}
- (void)configureWithModel:(id)model {
    %orig;
    // 移除这行代码以保持隐藏状态在视频切换时不被重置
    // self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
    if ([BHIManager hideElementButton]) {
        [self addHideElementButton];
        // 根据全局隐藏状态应用相应的显示/隐藏状态，确保视图完全加载后再应用
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            AWEAwemeBaseViewController *rootVC = self.viewController;
            if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
                TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
                [interactionController hideAllElements:globalElementsHidden exceptArray:nil];
            }
        });
    }
}
%new - (void)addDownloadButton {
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
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
        showAlert(@"BHTikTok, Hi", @"The video dosen't have music to download.", @"OK", @"Cancel", ^{});
    }
}
%new - (void)copyDecription:(AWEAwemeBaseViewController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    if (video_description) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = video_description;
    } else {
        showAlert(@"BHTikTok, Hi", @"The video dosen't have music to download.", @"OK", @"Cancel", ^{});
    }
}
%new - (void) downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {

     UIAction *action1 = [UIAction actionWithTitle:@"Download Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadVideo:rootVC];
    }];
    UIAction *action0 = [UIAction actionWithTitle:@"Download HD Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadHDVideo:rootVC];
    }];
    UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                            image:[UIImage systemImageNamed:@"music.note"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadMusic:rootVC];
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[action1, action0, action2, action3, action4, action5]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    }
}
%new - (void)addHideElementButton {
    UIButton *hideElementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [hideElementButton setTag:999];
    [hideElementButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [hideElementButton addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    if (globalElementsHidden) {
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
        if (globalElementsHidden) {
            globalElementsHidden = NO;
            [interactionController hideAllElements:false exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
        } else {
            globalElementsHidden = YES;
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

%hook AWEAwemePlayInteractionView
 
 - (void)layoutSubviews { 
     %orig; 
     
     // 检查是否需要显示视频上传时间
     if (![BHIManager videoUploadDate]) {
         return;
     }
     
     // 获取当前视频模型 - 尝试多种方式
     AWEAwemeModel *model = nil;
     
     // 方法1: 尝试从父视图控制器获取
     UIViewController *vc = [self yy_viewController];
     if ([vc respondsToSelector:@selector(model)]) {
         model = [vc model];
     }
     
     // 方法2: 尝试从关联对象获取
     if (!model) {
         model = objc_getAssociatedObject(self, "currentVideoModel");
     }
     
     // 方法3: 尝试从全局变量获取（如果有）
     if (!model) {
         // 这里可以尝试获取当前播放的视频模型
         // 可能需要根据实际情况调整
     }
     
     if (!model) return;
 
     // 清理旧的 
     [[self viewWithTag:42006] removeFromSuperview]; 
 
     // ================ 
     // 1. 获取上传时间 
     // ================ 
     NSNumber *ts = model.createTime ?: [model valueForKey:@"createTimeFromServer"]; 
     if (!ts) return; 
 
     NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts.doubleValue]; 
     NSDateFormatter *fmt = [[NSDateFormatter alloc] init]; 
     fmt.dateFormat = @"yyyy-MM-dd HH:mm";   // ← 你要的格式 
     NSString *dateStr = [fmt stringFromDate:date]; 
 
     // ================ 
     // 2. 创建时间标签 
     // ================ 
     UILabel *label = [[UILabel alloc] init]; 
     label.tag = 42006; 
     label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]; 
     label.textColor = [UIColor colorWithWhite:1 alpha:0.92]; 
     label.translatesAutoresizingMaskIntoConstraints = NO; 
     label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // 添加半透明背景
     label.layer.cornerRadius = 4; // 添加圆角
     label.clipsToBounds = YES;
     label.textAlignment = NSTextAlignmentCenter; // 居中对齐
 
     // ★★ 只显示上传时间 ★★ 
     label.text = [NSString stringWithFormat:@"上传时间: %@", dateStr]; 
 
     [self addSubview:label]; 
 
     // ================ 
     // 3. 找进度条 
     // ================ 
     UIView *progressBar = nil; 
     for (UIView *sub in self.subviews) { 
         if ([sub isKindOfClass:NSClassFromString(@"AWEProgressBar")]) { 
             progressBar = sub; 
             break; 
         } 
     }
     
     // ================ 
     // 4. 布局（进度条上方） 
     // ================ 
     // 使用延迟执行确保布局完成
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         if (progressBar) {
             // 在进度条上方显示
             [NSLayoutConstraint activateConstraints:@[ 
                 [label.bottomAnchor constraintEqualToAnchor:progressBar.topAnchor constant:-8], 
                 [label.leadingAnchor constraintEqualToAnchor:progressBar.leadingAnchor],
                 [label.heightAnchor constraintEqualToConstant:24],
                 [label.widthAnchor constraintEqualToConstant:200]
             ]]; 
         } else {
             // 如果没有进度条，显示在底部
             [NSLayoutConstraint activateConstraints:@[
                 [label.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-10],
                 [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
                 [label.heightAnchor constraintEqualToConstant:24],
                 [label.widthAnchor constraintEqualToConstant:200]
             ]];
         }
     });
 } 
 
 %end

%hook TTKStoryDetailTableViewCell
    // TODO...
%end

%hook AWEURLModel
%new - (NSString *)bestURLtoDownloadFormat {
    NSURL *bestURLFormat;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"]) {
            bestURLFormat = @"mp4";
        } else if ([url containsString:@".jpeg"]) {
            bestURLFormat = @"jpeg";
        } else if ([url containsString:@".png"]) {
            bestURLFormat = @"png";
        } else if ([url containsString:@".mp3"]) {
            bestURLFormat = @"mp3";
        } else if ([url containsString:@".m4a"]) {
            bestURLFormat = @"m4a";
        }
    }
    if (bestURLFormat == nil) {
        bestURLFormat = @"m4a";
    }

    return bestURLFormat;
}
%new - (NSURL *)bestURLtoDownload {
    NSURL *bestURL;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"] || [url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
            bestURL = [NSURL URLWithString:url];
        }
    }

    if (bestURL == nil) {
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

// 全局变量，用于跟踪当前播放的视频模型
static AWEAwemeModel *currentPlayingVideoModel = nil;

// 定时器，用于定期检查和更新视频模型
static NSTimer *modelUpdateTimer = nil;

// 辅助函数：获取当前视频模型
static AWEAwemeModel *getCurrentVideoModel(UIView *view) {
    // 方法1: 从关联对象获取
    AWEAwemeModel *model = objc_getAssociatedObject(view, "currentVideoModel");
    if (model) return model;
    
    // 方法2: 从父视图控制器获取
    UIViewController *vc = [view yy_viewController];
    if (vc) {
        if ([vc respondsToSelector:@selector(currentAwemeModel)]) {
            model = [vc currentAwemeModel];
        } else if ([vc respondsToSelector:@selector(model)]) {
            model = [vc model];
        } else {
            // 尝试从视图控制器的关联对象获取
            model = objc_getAssociatedObject(vc, "currentVideoModel");
        }
    }
    
    // 方法3: 从全局变量获取
    if (!model) {
        model = currentPlayingVideoModel;
    }
    
    return model;
}

// 辅助函数：设置当前视频模型
static void setCurrentVideoModel(AWEAwemeModel *model) {
    if (model != currentPlayingVideoModel) {
        currentPlayingVideoModel = model;
        
        // 如果定时器未运行，启动定时器
        if (!modelUpdateTimer && [BHIManager videoUploadDate]) {
            modelUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                               target:[[NSObject alloc] init]
                                                             selector:@selector(updateVideoModels)
                                                             userInfo:nil
                                                              repeats:YES];
        }
    }
}

// 定时器回调函数，用于定期检查和更新视频模型
%hook NSObject
- (void)updateVideoModels {
    // 查找所有可见的AWEAwemePlayInteractionView
    NSArray *windows = [UIApplication sharedApplication].windows;
    for (UIWindow *window in windows) {
        [self findAndUpdateInteractionViews:window];
    }
}

- (void)findAndUpdateInteractionViews:(UIView *)view {
    // 检查当前视图是否是AWEAwemePlayInteractionView
    if ([view isKindOfClass:%c(AWEAwemePlayInteractionView)]) {
        AWEAwemePlayInteractionView *interactionView = (AWEAwemePlayInteractionView *)view;
        
        // 尝试获取视频模型
        AWEAwemeModel *model = getCurrentVideoModel(interactionView);
        
        if (model) {
            // 将模型保存为关联对象
            objc_setAssociatedObject(interactionView, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // 触发重新布局
            [interactionView setNeedsLayout];
        }
    }
    
    // 递归检查子视图
    for (UIView *subview in view.subviews) {
        [self findAndUpdateInteractionViews:subview];
    }
}
%end

%ctor {
    // 初始化代码
}

// 新增：尝试捕获视频播放视图控制器的视频模型
%hook AWEVideoPlayViewController
- (void)setCurrentAwemeModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        // 设置全局变量
        setCurrentVideoModel(model);
        
        // 将模型保存为关联对象到播放交互视图
        AWEAwemePlayInteractionView *interactionView = [self valueForKey:@"_interactionView"];
        if (interactionView) {
            objc_setAssociatedObject(interactionView, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // 如果需要显示上传时间，触发重新布局
            if ([BHIManager videoUploadDate]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [interactionView setNeedsLayout];
                });
            }
        }
        
        // 也保存到视图控制器本身
        objc_setAssociatedObject(self, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
%end

// 新增：尝试从其他可能的方法获取视频模型
%hook AWEAwemePlayInteractionView
- (void)didMoveToWindow {
    %orig;
    
    // 检查是否需要显示视频上传时间
    if (![BHIManager videoUploadDate]) {
        return;
    }
    
    // 使用辅助函数获取视频模型
    AWEAwemeModel *model = getCurrentVideoModel(self);
    
    if (model) {
        // 将模型保存为关联对象
        objc_setAssociatedObject(self, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 触发重新布局
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsLayout];
        });
    }
}

// 尝试从视频播放器获取视频模型
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    
    // 检查是否需要显示视频上传时间
    if (![BHIManager videoUploadDate]) {
        return;
    }
    
    // 使用辅助函数获取视频模型
    AWEAwemeModel *model = getCurrentVideoModel(self);
    
    if (model) {
        // 将模型保存为关联对象
        objc_setAssociatedObject(self, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 触发重新布局
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsLayout];
        });
    }
}
%end

// 新增：尝试从视频播放器获取视频模型
%hook AWEVideoPlayerController
- (void)setModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        // 设置全局变量
        setCurrentVideoModel(model);
        
        // 尝试获取播放交互视图并设置模型
        AWEAwemePlayInteractionView *interactionView = [self valueForKey:@"_interactionView"];
        if (interactionView) {
            objc_setAssociatedObject(interactionView, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // 如果需要显示上传时间，触发重新布局
            if ([BHIManager videoUploadDate]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [interactionView setNeedsLayout];
                });
            }
        }
    }
}
%end

// 新增：尝试从视频播放视图获取视频模型
%hook AWEVideoPlayerView
- (void)setModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        // 设置全局变量
        setCurrentVideoModel(model);
        
        // 尝试获取父视图中的播放交互视图
        UIView *parentView = self.superview;
        while (parentView) {
            if ([parentView isKindOfClass:%c(AWEAwemePlayInteractionView)]) {
                AWEAwemePlayInteractionView *interactionView = (AWEAwemePlayInteractionView *)parentView;
                objc_setAssociatedObject(interactionView, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                // 如果需要显示上传时间，触发重新布局
                if ([BHIManager videoUploadDate]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [interactionView setNeedsLayout];
                    });
                }
                break;
            }
            parentView = parentView.superview;
        }
    }
}
%end

// 新增：尝试从视频详情页面获取视频模型
%hook AWEVideoDetailViewController
- (void)setCurrentAwemeModel:(AWEAwemeModel *)model {
    %orig;
    if (model) {
        // 设置全局变量
        setCurrentVideoModel(model);
        
        // 保存到视图控制器
        objc_setAssociatedObject(self, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 尝试获取播放交互视图并设置模型
        AWEAwemePlayInteractionView *interactionView = [self valueForKey:@"_interactionView"];
        if (interactionView) {
            objc_setAssociatedObject(interactionView, "currentVideoModel", model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // 如果需要显示上传时间，触发重新布局
            if ([BHIManager videoUploadDate]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [interactionView setNeedsLayout];
                });
            }
        }
    }
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
