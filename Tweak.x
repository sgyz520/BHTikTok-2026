#import "TikTokHeaders.h"

NSArray *jailbreakPaths;

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
    if ([BHIManager videoLikeCount] || [BHIManager videoUploadDate]) {
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
        

        for (int i = 0; i < [[self.contentView subviews] count]; i ++) {
            UIView *j = [[self.contentView subviews] objectAtIndex:i];
            if (j.tag == 1001) {
                [j removeFromSuperview];
            } 
            else if (j.tag == 1002) {
                [j removeFromSuperview];
            }
        }
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
- (void)playerDidPlayToEnd:(id)arg1 {
    if ([BHIManager autoPlay]) {
        if ([self.container.parentViewController isKindOfClass:%c(AWENewFeedTableViewController)]) {
            [((AWENewFeedTableViewController *)self.container.parentViewController) scrollToNextVideo];
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
// 全局函数：根据国家代码获取国家名称
static NSString *getCountryNameForCode(NSString *countryCode) {
    // 根据当前语言设置决定使用中文还是英文名称
    NSString *currentLanguage = [[NSUserDefaults standardUserDefaults] stringForKey:@"BHTikTok_Language"];
    BOOL useChinese = [currentLanguage isEqualToString:@"zh-Hans"];
    
    // 添加错误处理
    if (!countryCode || countryCode.length == 0) {
        return useChinese ? @"未知" : @"Unknown";
    }
    
    if (useChinese) {
        // 中文名称映射（扩展版）
        NSDictionary *countryNames = @{
            @"SA": @"沙特阿拉伯",
            @"TW": @"台湾",
            @"HK": @"香港",
            @"MO": @"澳门",
            @"JP": @"日本",
            @"KR": @"韩国",
            @"GB": @"英国",
            @"US": @"美国",
            @"AU": @"澳大利亚",
            @"CA": @"加拿大",
            @"AR": @"阿根廷",
            @"PH": @"菲律宾",
            @"LA": @"老挝",
            @"MY": @"马来西亚",
            @"TH": @"泰国",
            @"SG": @"新加坡",
            @"ID": @"印度尼西亚",
            @"VN": @"越南",
            @"AI": @"安圭拉",
            @"PA": @"巴拿马",
            @"DE": @"德国",
            @"RU": @"俄罗斯",
            @"FR": @"法国",
            @"FI": @"芬兰",
            @"IT": @"意大利",
            @"PK": @"巴基斯坦",
            @"DK": @"丹麦",
            @"NO": @"挪威",
            @"SD": @"苏丹",
            @"RO": @"罗马尼亚",
            @"AE": @"阿联酋",
            @"EG": @"埃及",
            @"LB": @"黎巴嫩",
            @"MX": @"墨西哥",
            @"BR": @"巴西",
            @"TR": @"土耳其",
            @"KW": @"科威特",
            @"DZ": @"阿尔及利亚",
            @"CN": @"中国",
            // 新增国家代码映射
            @"IN": @"印度",
            @"ES": @"西班牙",
            @"NL": @"荷兰",
            @"BE": @"比利时",
            @"CH": @"瑞士",
            @"AT": @"奥地利",
            @"SE": @"瑞典",
            @"PL": @"波兰",
            @"GR": @"希腊",
            @"PT": @"葡萄牙",
            @"IE": @"爱尔兰",
            @"CZ": @"捷克",
            @"HU": @"匈牙利",
            @"IL": @"以色列",
            @"NZ": @"新西兰",
            @"ZA": @"南非",
            @"NG": @"尼日利亚",
            @"KE": @"肯尼亚",
            @"MA": @"摩洛哥",
            @"GH": @"加纳",
            @"CL": @"智利",
            @"CO": @"哥伦比亚",
            @"PE": @"秘鲁",
            @"VE": @"委内瑞拉",
            @"UY": @"乌拉圭",
            @"EC": @"厄瓜多尔",
            @"BO": @"玻利维亚",
            @"PY": @"巴拉圭",
            @"GY": @"圭亚那",
            @"SR": @"苏里南",
            @"GF": @"法属圭亚那",
            @"AF": @"阿富汗",
            @"BD": @"孟加拉国",
            @"BT": @"不丹",
            @"NP": @"尼泊尔",
            @"LK": @"斯里兰卡",
            @"MM": @"缅甸",
            @"KH": @"柬埔寨",
            @"BN": @"文莱",
            @"TL": @"东帝汶",
            @"MN": @"蒙古",
            @"KZ": @"哈萨克斯坦",
            @"KG": @"吉尔吉斯斯坦",
            @"TJ": @"塔吉克斯坦",
            @"TM": @"土库曼斯坦",
            @"UZ": @"乌兹别克斯坦",
            @"IR": @"伊朗",
            @"IQ": @"伊拉克",
            @"JO": @"约旦",
            @"SY": @"叙利亚",
            @"YE": @"也门",
            @"OM": @"阿曼",
            @"QA": @"卡塔尔",
            @"BH": @"巴林",
            @"CY": @"塞浦路斯",
            @"IS": @"冰岛",
            @"AL": @"阿尔巴尼亚",
            @"AD": @"安道尔",
            @"BY": @"白俄罗斯",
            @"BA": @"波黑",
            @"BG": @"保加利亚",
            @"HR": @"克罗地亚",
            @"EE": @"爱沙尼亚",
            @"FO": @"法罗群岛",
            @"GI": @"直布罗陀",
            @"GG": @"根西岛",
            @"VA": @"梵蒂冈",
            @"JE": @"泽西岛",
            @"LV": @"拉脱维亚",
            @"LI": @"列支敦士登",
            @"LT": @"立陶宛",
            @"LU": @"卢森堡",
            @"MK": @"北马其顿",
            @"MD": @"摩尔多瓦",
            @"MC": @"摩纳哥",
            @"ME": @"黑山",
            @"NO": @"挪威",
            @"RS": @"塞尔维亚",
            @"SK": @"斯洛伐克",
            @"SI": @"斯洛文尼亚",
            @"UA": @"乌克兰",
            @"AG": @"安提瓜和巴布达",
            @"AW": @"阿鲁巴",
            @"BS": @"巴哈马",
            @"BB": @"巴巴多斯",
            @"BZ": @"伯利兹",
            @"BM": @"百慕大",
            @"VG": @"英属维尔京群岛",
            @"KY": @"开曼群岛",
            @"CR": @"哥斯达黎加",
            @"CU": @"古巴",
            @"DM": @"多米尼克",
            @"DO": @"多米尼加共和国",
            @"SV": @"萨尔瓦多",
            @"GD": @"格林纳达",
            @"GT": @"危地马拉",
            @"HT": @"海地",
            @"HN": @"洪都拉斯",
            @"JM": @"牙买加",
            @"MQ": @"马提尼克",
            @"MS": @"蒙特塞拉特",
            @"NI": @"尼加拉瓜",
            @"PA": @"巴拿马",
            @"PR": @"波多黎各",
            @"BL": @"圣巴泰勒米",
            @"KN": @"圣基茨和尼维斯",
            @"LC": @"圣卢西亚",
            @"MF": @"法属圣马丁",
            @"PM": @"圣皮埃尔和密克隆",
            @"VC": @"圣文森特和格林纳丁斯",
            @"SXM": @"荷属圣马丁",
            @"TT": @"特立尼达和多巴哥",
            @"TC": "特克斯和凯科斯群岛",
            @"VI": @"美属维尔京群岛",
            @"AR": @"阿根廷",
            @"BO": @"玻利维亚",
            @"BR": @"巴西",
            @"CL": @"智利",
            @"CO": @"哥伦比亚",
            @"EC": @"厄瓜多尔",
            @"FK": @"福克兰群岛",
            @"GF": @"法属圭亚那",
            @"GY": @"圭亚那",
            @"PY": @"巴拉圭",
            @"PE": @"秘鲁",
            @"SR": @"苏里南",
            @"UY": @"乌拉圭",
            @"VE": @"委内瑞拉",
            @"AI": @"安圭拉",
            @"AG": @"安提瓜和巴布达",
            @"AW": @"阿鲁巴",
            @"BB": @"巴巴多斯",
            @"BM": @"百慕大",
            @"BQ": @"博奈尔",
            @"BS": @"巴哈马",
            @"BZ": @"伯利兹",
            @"CA": @"加拿大",
            @"CR": @"哥斯达黎加",
            @"CU": @"古巴",
            @"CW": @"库拉索",
            @"DM": @"多米尼克",
            @"DO": @"多米尼加共和国",
            @"GD": @"格林纳达",
            @"GL": @"格陵兰",
            @"GP": @"瓜德罗普",
            @"GT": @"危地马拉",
            @"HN": @"洪都拉斯",
            @"HT": @"海地",
            @"JM": @"牙买加",
            @"MQ": @"马提尼克",
            @"MX": @"墨西哥",
            @"NI": @"尼加拉瓜",
            @"PA": @"巴拿马",
            @"PR": @"波多黎各",
            @"BL": @"圣巴泰勒米",
            @"KN": @"圣基茨和尼维斯",
            @"LC": @"圣卢西亚",
            @"MF": @"法属圣马丁",
            @"PM": @"圣皮埃尔和密克隆",
            @"VC": @"圣文森特和格林纳丁斯",
            @"SX": @"荷属圣马丁",
            @"TT": @"特立尼达和多巴哥",
            @"TC": @"特克斯和凯科斯群岛",
            @"US": @"美国",
            @"VG": @"英属维尔京群岛",
            @"VI": @"美属维尔京群岛",
            @"AS": @"美属萨摩亚",
            @"AU": @"澳大利亚",
            @"CK": @"库克群岛",
            @"FJ": @"斐济",
            @"PF": @"法属波利尼西亚",
            @"GU": @"关岛",
            @"KI": @"基里巴斯",
            @"MH": @"马绍尔群岛",
            @"FM": @"密克罗尼西亚",
            @"NR": @"瑙鲁",
            @"NC": @"新喀里多尼亚",
            @"NZ": @"新西兰",
            @"NU": @"纽埃",
            @"NF": @"诺福克岛",
            @"MP": @"北马里亚纳群岛",
            @"PW": @"帕劳",
            @"PG": @"巴布亚新几内亚",
            @"PN": @"皮特凯恩群岛",
            @"WS": @"萨摩亚",
            @"SB": @"所罗门群岛",
            @"TK": @"托克劳",
            @"TO": @"汤加",
            @"TV": @"图瓦卢",
            @"VU": @"瓦努阿图",
            @"WF": @"瓦利斯和富图纳"
        };
        
        return countryNames[countryCode] ?: countryCode;
    } else {
        // 英文名称映射（扩展版）
        NSDictionary *countryNames = @{
            @"SA": @"Saudi Arabia",
            @"TW": @"Taiwan",
            @"HK": @"Hong Kong",
            @"MO": @"Macau",
            @"JP": @"Japan",
            @"KR": @"South Korea",
            @"GB": @"United Kingdom",
            @"US": @"United States",
            @"AU": @"Australia",
            @"CA": @"Canada",
            @"AR": @"Argentina",
            @"PH": @"Philippines",
            @"LA": @"Laos",
            @"MY": @"Malaysia",
            @"TH": @"Thailand",
            @"SG": @"Singapore",
            @"ID": @"Indonesia",
            @"VN": @"Vietnam",
            @"AI": @"Anguilla",
            @"PA": @"Panama",
            @"DE": @"Germany",
            @"RU": @"Russia",
            @"FR": @"France",
            @"FI": @"Finland",
            @"IT": @"Italy",
            @"PK": @"Pakistan",
            @"DK": @"Denmark",
            @"NO": @"Norway",
            @"SD": @"Sudan",
            @"RO": @"Romania",
            @"AE": @"UAE",
            @"EG": @"Egypt",
            @"LB": @"Lebanon",
            @"MX": @"Mexico",
            @"BR": @"Brazil",
            @"TR": @"Turkey",
            @"KW": @"Kuwait",
            @"DZ": @"Algeria",
            @"CN": @"China",
            // 新增国家代码映射
            @"IN": @"India",
            @"ES": @"Spain",
            @"NL": @"Netherlands",
            @"BE": @"Belgium",
            @"CH": @"Switzerland",
            @"AT": @"Austria",
            @"SE": @"Sweden",
            @"PL": @"Poland",
            @"GR": @"Greece",
            @"PT": @"Portugal",
            @"IE": @"Ireland",
            @"CZ": @"Czech Republic",
            @"HU": @"Hungary",
            @"IL": @"Israel",
            @"NZ": @"New Zealand",
            @"ZA": @"South Africa",
            @"NG": @"Nigeria",
            @"KE": @"Kenya",
            @"MA": @"Morocco",
            @"GH": @"Ghana",
            @"CL": @"Chile",
            @"CO": @"Colombia",
            @"PE": @"Peru",
            @"VE": @"Venezuela",
            @"UY": @"Uruguay",
            @"EC": @"Ecuador",
            @"BO": @"Bolivia",
            @"PY": @"Paraguay",
            @"GY": @"Guyana",
            @"SR": @"Suriname",
            @"GF": @"French Guiana",
            @"AF": @"Afghanistan",
            @"BD": @"Bangladesh",
            @"BT": @"Bhutan",
            @"NP": @"Nepal",
            @"LK": @"Sri Lanka",
            @"MM": @"Myanmar",
            @"KH": @"Cambodia",
            @"BN": @"Brunei",
            @"TL": @"East Timor",
            @"MN": @"Mongolia",
            @"KZ": @"Kazakhstan",
            @"KG": @"Kyrgyzstan",
            @"TJ": @"Tajikistan",
            @"TM": @"Turkmenistan",
            @"UZ": @"Uzbekistan",
            @"IR": @"Iran",
            @"IQ": @"Iraq",
            @"JO": @"Jordan",
            @"SY": @"Syria",
            @"YE": @"Yemen",
            @"OM": @"Oman",
            @"QA": @"Qatar",
            @"BH": @"Bahrain",
            @"CY": @"Cyprus",
            @"IS": @"Iceland",
            @"AL": @"Albania",
            @"AD": @"Andorra",
            @"BY": @"Belarus",
            @"BA": @"Bosnia and Herzegovina",
            @"BG": @"Bulgaria",
            @"HR": @"Croatia",
            @"EE": @"Estonia",
            @"FO": @"Faroe Islands",
            @"GI": @"Gibraltar",
            @"GG": @"Guernsey",
            @"VA": @"Vatican City",
            @"JE": @"Jersey",
            @"LV": @"Latvia",
            @"LI": @"Liechtenstein",
            @"LT": @"Lithuania",
            @"LU": @"Luxembourg",
            @"MK": @"North Macedonia",
            @"MD": @"Moldova",
            @"MC": @"Monaco",
            @"ME": @"Montenegro",
            @"RS": @"Serbia",
            @"SK": @"Slovakia",
            @"SI": @"Slovenia",
            @"UA": @"Ukraine",
            @"AG": @"Antigua and Barbuda",
            @"AW": @"Aruba",
            @"BS": @"Bahamas",
            @"BB": @"Barbados",
            @"BZ": @"Belize",
            @"BM": @"Bermuda",
            @"VG": @"British Virgin Islands",
            @"KY": @"Cayman Islands",
            @"CR": @"Costa Rica",
            @"CU": @"Cuba",
            @"DM": @"Dominica",
            @"DO": @"Dominican Republic",
            @"SV": @"El Salvador",
            @"GD": @"Grenada",
            @"GT": @"Guatemala",
            @"HT": @"Haiti",
            @"HN": @"Honduras",
            @"JM": @"Jamaica",
            @"MQ": @"Martinique",
            @"MS": @"Montserrat",
            @"NI": @"Nicaragua",
            @"PA": @"Panama",
            @"PR": @"Puerto Rico",
            @"BL": @"Saint Barthélemy",
            @"KN": @"Saint Kitts and Nevis",
            @"LC": @"Saint Lucia",
            @"MF": @"Saint Martin",
            @"PM": @"Saint Pierre and Miquelon",
            @"VC": @"Saint Vincent and the Grenadines",
            @"SXM": @"Sint Maarten",
            @"TT": @"Trinidad and Tobago",
            @"TC": "Turks and Caicos Islands",
            @"VI": @"United States Virgin Islands",
            @"AR": @"Argentina",
            @"BO": @"Bolivia",
            @"BR": @"Brazil",
            @"CL": @"Chile",
            @"CO": @"Colombia",
            @"EC": @"Ecuador",
            @"FK": @"Falkland Islands",
            @"GF": @"French Guiana",
            @"GY": @"Guyana",
            @"PY": @"Paraguay",
            @"PE": @"Peru",
            @"SR": @"Suriname",
            @"UY": @"Uruguay",
            @"VE": @"Venezuela",
            @"AI": @"Anguilla",
            @"AG": @"Antigua and Barbuda",
            @"AW": @"Aruba",
            @"BB": @"Barbados",
            @"BM": @"Bermuda",
            @"BQ": @"Bonaire",
            @"BS": @"Bahamas",
            @"BZ": @"Belize",
            @"CA": @"Canada",
            @"CR": @"Costa Rica",
            @"CU": @"Cuba",
            @"CW": @"Curaçao",
            @"DM": @"Dominica",
            @"DO": @"Dominican Republic",
            @"GD": @"Grenada",
            @"GL": @"Greenland",
            @"GP": @"Guadeloupe",
            @"GT": @"Guatemala",
            @"HN": @"Honduras",
            @"HT": @"Haiti",
            @"JM": @"Jamaica",
            @"MQ": @"Martinique",
            @"MX": @"Mexico",
            @"NI": @"Nicaragua",
            @"PA": @"Panama",
            @"PR": @"Puerto Rico",
            @"BL": @"Saint Barthélemy",
            @"KN": @"Saint Kitts and Nevis",
            @"LC": @"Saint Lucia",
            @"MF": @"Saint Martin",
            @"PM": @"Saint Pierre and Miquelon",
            @"VC": @"Saint Vincent and the Grenadines",
            @"SX": @"Sint Maarten",
            @"TT": @"Trinidad and Tobago",
            @"TC": @"Turks and Caicos Islands",
            @"US": @"United States",
            @"VG": @"British Virgin Islands",
            @"VI": @"United States Virgin Islands",
            @"AS": @"American Samoa",
            @"AU": @"Australia",
            @"CK": @"Cook Islands",
            @"FJ": @"Fiji",
            @"PF": @"French Polynesia",
            @"GU": @"Guam",
            @"KI": @"Kiribati",
            @"MH": @"Marshall Islands",
            @"FM": @"Micronesia",
            @"NR": @"Nauru",
            @"NC": @"New Caledonia",
            @"NZ": @"New Zealand",
            @"NU": @"Niue",
            @"NF": @"Norfolk Island",
            @"MP": @"Northern Mariana Islands",
            @"PW": @"Palau",
            @"PG": @"Papua New Guinea",
            @"PN": @"Pitcairn Islands",
            @"WS": @"Samoa",
            @"SB": @"Solomon Islands",
            @"TK": @"Tokelau",
            @"TO": @"Tonga",
            @"TV": @"Tuvalu",
            @"VU": @"Vanuatu",
            @"WF": @"Wallis and Futuna"
        };
        
        return countryNames[countryCode] ?: countryCode;
    }
}

// 全局函数：根据地区代码获取多级属地信息
static NSString *getMultiLevelLocationInfo(NSString *regionCode, NSString *cityCode) {
    // 错误处理：检查输入参数
    if (!regionCode || regionCode.length == 0) {
        return @"";
    }
    
    NSString *currentLanguage = [[NSUserDefaults standardUserDefaults] stringForKey:@"BHTikTok_Language"];
    BOOL useChinese = [currentLanguage isEqualToString:@"zh-Hans"];
    
    // 创建缓存键
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", regionCode ?: @"", cityCode ?: @""];
    
    // 尝试从缓存获取结果
    NSDictionary *cachedResult = [BHIManager getCachedLocationInfo:cacheKey];
    if (cachedResult && cachedResult[@"locationInfo"]) {
        // 检查缓存是否过期（24小时）
        NSTimeInterval cacheTime = [cachedResult[@"timestamp"] doubleValue];
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (currentTime - cacheTime < 86400) { // 24小时 = 86400秒
            return cachedResult[@"locationInfo"];
        }
    }
    
    // 获取国家名称
    NSString *countryName = getCountryNameForCode(regionCode);
    NSString *resultLocationInfo = countryName; // 默认值
    
    // 如果是中国，尝试获取省份和城市信息
    if ([regionCode isEqualToString:@"CN"] && cityCode && cityCode.length >= 6) {
        // 中国行政区划代码映射（简化版，包含主要省市）
        NSDictionary *provinceCodeMap = @{
            @"11": @"北京",
            @"12": @"天津",
            @"13": @"河北",
            @"14": @"山西",
            @"15": @"内蒙古",
            @"21": @"辽宁",
            @"22": @"吉林",
            @"23": @"黑龙江",
            @"31": @"上海",
            @"32": @"江苏",
            @"33": @"浙江",
            @"34": @"安徽",
            @"35": @"福建",
            @"36": @"江西",
            @"37": @"山东",
            @"41": @"河南",
            @"42": @"湖北",
            @"43": @"湖南",
            @"44": @"广东",
            @"45": @"广西",
            @"46": @"海南",
            @"50": @"重庆",
            @"51": @"四川",
            @"52": @"贵州",
            @"53": @"云南",
            @"54": @"西藏",
            @"61": @"陕西",
            @"62": @"甘肃",
            @"63": @"青海",
            @"64": @"宁夏",
            @"65": @"新疆",
            @"71": @"台湾",
            @"81": @"香港",
            @"82": @"澳门"
        };
        
        // 获取省份代码（前两位）
        NSString *provinceCode = [cityCode substringToIndex:2];
        NSString *provinceName = provinceCodeMap[provinceCode];
        
        // 获取城市代码（前四位）
        NSString *cityCodePrefix = [cityCode substringToIndex:4];
        
        // 主要城市映射（扩展版）
        NSDictionary *cityCodeMap = @{
            // 直辖市
            @"1101": @"北京",
            @"1201": @"天津",
            @"3101": @"上海",
            @"5001": @"重庆",
            
            // 广东省
            @"4401": @"广州",
            @"4403": @"深圳",
            @"4404": @"珠海",
            @"4405": @"汕头",
            @"4406": @"佛山",
            @"4407": @"江门",
            @"4408": @"湛江",
            @"4409": @"茂名",
            @"4412": @"肇庆",
            @"4413": @"惠州",
            @"4414": @"梅州",
            @"4415": @"汕尾",
            @"4416": @"河源",
            @"4417": @"阳江",
            @"4418": @"清远",
            @"4419": @"东莞",
            @"4420": @"中山",
            @"4451": @"潮州",
            @"4452": @"揭阳",
            @"4453": @"云浮",
            
            // 江苏省
            @"3201": @"南京",
            @"3202": @"无锡",
            @"3203": @"徐州",
            @"3204": @"常州",
            @"3205": @"苏州",
            @"3206": @"南通",
            @"3207": @"连云港",
            @"3208": @"淮安",
            @"3209": @"盐城",
            @"3210": @"扬州",
            @"3211": @"镇江",
            @"3212": @"泰州",
            @"3213": @"宿迁",
            
            // 浙江省
            @"3301": @"杭州",
            @"3302": @"宁波",
            @"3303": @"温州",
            @"3304": @"嘉兴",
            @"3305": @"湖州",
            @"3306": @"绍兴",
            @"3307": @"金华",
            @"3308": @"衢州",
            @"3309": @"舟山",
            @"3310": @"台州",
            @"3311": @"丽水",
            
            // 山东省
            @"3701": @"济南",
            @"3702": @"青岛",
            @"3703": @"淄博",
            @"3704": @"枣庄",
            @"3705": @"东营",
            @"3706": @"烟台",
            @"3707": @"潍坊",
            @"3708": @"济宁",
            @"3709": @"泰安",
            @"3710": @"威海",
            @"3711": @"日照",
            @"3713": @"临沂",
            @"3714": @"德州",
            @"3715": @"聊城",
            @"3716": @"滨州",
            @"3717": @"菏泽",
            
            // 河南省
            @"4101": @"郑州",
            @"4102": @"开封",
            @"4103": @"洛阳",
            @"4104": @"平顶山",
            @"4105": @"安阳",
            @"4106": @"鹤壁",
            @"4107": @"新乡",
            @"4108": @"焦作",
            @"4109": @"濮阳",
            @"4110": @"许昌",
            @"4111": @"漯河",
            @"4112": @"三门峡",
            @"4113": @"南阳",
            @"4114": @"商丘",
            @"4115": @"信阳",
            @"4116": @"周口",
            @"4117": @"驻马店",
            @"4118": @"济源",
            
            // 湖北省
            @"4201": @"武汉",
            @"4202": @"黄石",
            @"4203": @"十堰",
            @"4205": @"宜昌",
            @"4206": @"襄阳",
            @"4207": @"鄂州",
            @"4208": @"荆门",
            @"4209": @"孝感",
            @"4210": @"荆州",
            @"4211": @"黄冈",
            @"4212": @"咸宁",
            @"4213": @"随州",
            @"4281": @"天门",
            @"4282": @"仙桃",
            @"4283": @"潜江",
            @"4284": @"神农架",
            
            // 湖南省
            @"4301": @"长沙",
            @"4302": @"株洲",
            @"4303": @"湘潭",
            @"4304": @"衡阳",
            @"4305": @"邵阳",
            @"4306": @"岳阳",
            @"4307": @"常德",
            @"4308": @"张家界",
            @"4309": @"益阳",
            @"4310": @"郴州",
            @"4311": @"永州",
            @"4312": @"怀化",
            @"4313": @"娄底",
            @"4331": @"湘西",
            
            // 四川省
            @"5101": @"成都",
            @"5103": @"自贡",
            @"5104": @"攀枝花",
            @"5105": @"泸州",
            @"5106": @"德阳",
            @"5107": @"绵阳",
            @"5108": @"广元",
            @"5109": @"遂宁",
            @"5110": @"内江",
            @"5111": @"乐山",
            @"5113": @"南充",
            @"5114": @"眉山",
            @"5115": @"宜宾",
            @"5116": @"广安",
            @"5117": @"达州",
            @"5118": @"雅安",
            @"5119": @"巴中",
            @"5120": @"资阳",
            @"5132": @"阿坝",
            @"5133": @"甘孜",
            @"5134": @"凉山",
            
            // 云南省
            @"5301": @"昆明",
            @"5303": @"曲靖",
            @"5304": @"玉溪",
            @"5305": @"保山",
            @"5306": @"昭通",
            @"5307": @"丽江",
            @"5308": @"普洱",
            @"5309": @"临沧",
            @"5323": @"楚雄",
            @"5325": @"红河",
            @"5326": @"文山",
            @"5328": @"西双版纳",
            @"5329": @"大理",
            @"5331": @"德宏",
            @"5333": @"怒江",
            @"5334": @"迪庆",
            
            // 陕西省
            @"6101": @"西安",
            @"6102": @"铜川",
            @"6103": @"宝鸡",
            @"6104": @"咸阳",
            @"6105": @"渭南",
            @"6106": @"延安",
            @"6107": @"汉中",
            @"6108": @"榆林",
            @"6109": @"安康",
            @"6110": @"商洛",
            
            // 福建省
            @"3501": @"福州",
            @"3502": @"厦门",
            @"3503": @"莆田",
            @"3504": @"三明",
            @"3505": @"泉州",
            @"3506": @"漳州",
            @"3507": @"南平",
            @"3508": @"龙岩",
            @"3509": @"宁德",
            
            // 安徽省
            @"3401": @"合肥",
            @"3402": @"芜湖",
            @"3403": @"蚌埠",
            @"3404": @"淮南",
            @"3405": @"马鞍山",
            @"3406": @"淮北",
            @"3407": @"铜陵",
            @"3408": @"安庆",
            @"3410": @"黄山",
            @"3411": @"滁州",
            @"3412": @"阜阳",
            @"3413": @"宿州",
            @"3415": @"六安",
            @"3416": @"亳州",
            @"3417": @"池州",
            @"3418": @"宣城",
            
            // 江西省
            @"3601": @"南昌",
            @"3602": @"景德镇",
            @"3603": @"萍乡",
            @"3604": @"九江",
            @"3605": @"新余",
            @"3606": @"鹰潭",
            @"3607": @"赣州",
            @"3608": @"吉安",
            @"3609": @"宜春",
            @"3610": @"抚州",
            @"3611": @"上饶",
            
            // 辽宁省
            @"2101": @"沈阳",
            @"2102": @"大连",
            @"2103": @"鞍山",
            @"2104": @"抚顺",
            @"2105": @"本溪",
            @"2106": @"丹东",
            @"2107": @"锦州",
            @"2108": @"营口",
            @"2109": @"阜新",
            @"2110": @"辽阳",
            @"2111": @"盘锦",
            @"2112": @"铁岭",
            @"2113": @"朝阳",
            @"2114": @"葫芦岛",
            
            // 吉林省
            @"2201": @"长春",
            @"2202": @"吉林",
            @"2203": @"四平",
            @"2204": @"辽源",
            @"2205": @"通化",
            @"2206": @"白山",
            @"2207": @"松原",
            @"2208": @"白城",
            @"2224": @"延边",
            
            // 黑龙江省
            @"2301": @"哈尔滨",
            @"2302": @"齐齐哈尔",
            @"2303": @"鸡西",
            @"2304": @"鹤岗",
            @"2305": @"双鸭山",
            @"2306": @"大庆",
            @"2307": @"伊春",
            @"2308": @"佳木斯",
            @"2309": @"七台河",
            @"2310": @"牡丹江",
            @"2311": @"黑河",
            @"2312": @"绥化",
            @"2327": @"大兴安岭",
            
            // 山西省
            @"1401": @"太原",
            @"1402": @"大同",
            @"1403": @"阳泉",
            @"1404": @"长治",
            @"1405": @"晋城",
            @"1406": @"朔州",
            @"1407": @"晋中",
            @"1408": @"运城",
            @"1409": @"忻州",
            @"1410": @"临汾",
            @"1411": @"吕梁",
            
            // 河北省
            @"1301": @"石家庄",
            @"1302": @"唐山",
            @"1303": @"秦皇岛",
            @"1304": @"邯郸",
            @"1305": @"邢台",
            @"1306": @"保定",
            @"1307": @"张家口",
            @"1308": @"承德",
            @"1309": @"沧州",
            @"1310": @"廊坊",
            @"1311": @"衡水",
            
            // 内蒙古自治区
            @"1501": @"呼和浩特",
            @"1502": @"包头",
            @"1503": @"乌海",
            @"1504": @"赤峰",
            @"1505": @"通辽",
            @"1506": @"鄂尔多斯",
            @"1507": @"呼伦贝尔",
            @"1508": @"巴彦淖尔",
            @"1509": @"乌兰察布",
            @"1522": @"兴安",
            @"1525": @"锡林郭勒",
            @"1529": @"阿拉善",
            
            // 广西壮族自治区
            @"4501": @"南宁",
            @"4502": @"柳州",
            @"4503": @"桂林",
            @"4504": @"梧州",
            @"4505": @"北海",
            @"4506": @"防城港",
            @"4507": @"钦州",
            @"4508": @"贵港",
            @"4509": @"玉林",
            @"4510": @"百色",
            @"4511": @"贺州",
            @"4512": @"河池",
            @"4513": @"来宾",
            @"4514": @"崇左",
            
            // 海南省
            @"4601": @"海口",
            @"4602": @"三亚",
            @"4603": @"三沙",
            @"4604": @"儋州",
            @"4690": @"省直辖县级行政区",
            
            // 贵州省
            @"5201": @"贵阳",
            @"5202": @"六盘水",
            @"5203": @"遵义",
            @"5204": @"安顺",
            @"5205": @"毕节",
            @"5206": @"铜仁",
            @"5223": @"黔西南",
            @"5226": @"黔东南",
            @"5227": @"黔南",
            
            // 甘肃省
            @"6201": @"兰州",
            @"6202": @"嘉峪关",
            @"6203": @"金昌",
            @"6204": @"白银",
            @"6205": @"天水",
            @"6206": @"武威",
            @"6207": @"张掖",
            @"6208": @"平凉",
            @"6209": @"酒泉",
            @"6210": @"庆阳",
            @"6211": @"定西",
            @"6212": @"陇南",
            @"6229": @"临夏",
            @"6230": @"甘南",
            
            // 青海省
            @"6301": @"西宁",
            @"6302": @"海东",
            @"6322": @"海北",
            @"6323": @"黄南",
            @"6325": @"海南",
            @"6326": @"果洛",
            @"6327": @"玉树",
            @"6328": @"海西",
            
            // 宁夏回族自治区
            @"6401": @"银川",
            @"6402": @"石嘴山",
            @"6403": @"吴忠",
            @"6404": @"固原",
            @"6405": @"中卫",
            
            // 新疆维吾尔自治区
            @"6501": @"乌鲁木齐",
            @"6502": @"克拉玛依",
            @"6504": @"吐鲁番",
            @"6505": @"哈密",
            @"6523": @"昌吉",
            @"6527": @"博尔塔拉",
            @"6528": @"巴音郭楞",
            @"6529": @"阿克苏",
            @"6530": @"克孜勒苏",
            @"6531": @"喀什",
            @"6532": @"和田",
            @"6540": @"伊犁",
            @"6542": @"塔城",
            @"6543": @"阿勒泰",
            @"6590": @"自治区直辖县级行政区",
            
            // 西藏自治区
            @"5401": @"拉萨",
            @"5402": @"日喀则",
            @"5403": @"昌都",
            @"5404": @"林芝",
            @"5405": @"山南",
            @"5406": @"那曲",
            @"5425": @"阿里",
            
            // 台湾省
            @"7101": @"台北市",
            @"7102": @"高雄市",
            @"7103": @"台中市",
            @"7104": @"台南市",
            @"7105": @"新北市",
            @"7106": @"桃园市",
            
            // 香港特别行政区
            @"8101": @"中西区",
            @"8102": @"湾仔区",
            @"8103": @"东区",
            @"8104": @"南区",
            @"8105": @"油尖旺区",
            @"8106": @"深水埗区",
            @"8107": @"九龙城区",
            @"8108": @"黄大仙区",
            @"8109": @"观塘区",
            @"8110": @"荃湾区",
            @"8111": @"屯门区",
            @"8112": @"元朗区",
            @"8113": @"北区",
            @"8114": @"大埔区",
            @"8115": @"西贡区",
            @"8116": @"沙田区",
            @"8117": @"葵青区",
            @"8118": @"离岛区",
            
            // 澳门特别行政区
            @"8201": @"花地玛堂区",
            @"8202": @"圣安多尼堂区",
            @"8203": @"大堂区",
            @"8204": @"望德堂区",
            @"8205": @"风顺堂区",
            @"8206": @"嘉模堂区",
            @"8207": @"圣方济各堂区",
            @"8208": @"路氹填海区"
        };
        
        NSString *cityName = cityCodeMap[cityCodePrefix];
        
        // 构建多级属地显示文本
        if (provinceName && cityName) {
            // 直辖市处理
            if ([provinceCode isEqualToString:@"11"] || [provinceCode isEqualToString:@"12"] || 
                [provinceCode isEqualToString:@"31"] || [provinceCode isEqualToString:@"50"]) {
                resultLocationInfo = [NSString stringWithFormat:@"%@", cityName];
            } else {
                resultLocationInfo = [NSString stringWithFormat:@"%@ %@", provinceName, cityName];
            }
        } else if (provinceName) {
            resultLocationInfo = [NSString stringWithFormat:@"%@", provinceName];
        }
    }
    
    // 保存结果到缓存
    NSDictionary *resultToCache = @{
        @"locationInfo": resultLocationInfo,
        @"regionCode": regionCode ?: @"",
        @"cityCode": cityCode ?: @"",
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
    [BHIManager saveLocationInfoToCache:cacheKey locationInfo:resultToCache];
    
    return resultLocationInfo;
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
        NSString *regionCode = model.region;
        
        // 只有当countryID不为空且不是问号时才显示
        if (countryID && countryID.length > 0 && ![countryID isEqualToString:@"?"]) {
            // 根据设置决定使用多级属地显示还是只显示国家名称
            NSString *locationInfo;
            if ([BHIManager multiLevelLocation]) {
                locationInfo = getMultiLevelLocationInfo(countryID, regionCode);
            } else {
                locationInfo = getCountryNameForCode(countryID);
            }
            
            // 检查位置信息是否有效
            if (!locationInfo || locationInfo.length == 0) {
                return;
            }
            
            // 创建IP属地标签，考虑不同屏幕尺寸
            UILabel *uploadLabel = [[UILabel alloc] init];
            uploadLabel.text = [NSString stringWithFormat:@"%@ •",locationInfo];
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
            CGFloat maxWidth = self.bounds.size.width * 0.3; // 最大宽度为父视图宽度的30%
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
    if ([BHIManager videoUploadDate] || [BHIManager uploadRegion]) {
        [self addVideoInfoLabels];
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
    if ([BHIManager videoUploadDate] || [BHIManager uploadRegion]) {
        [self addVideoInfoLabels];
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

// 添加视频信息标签（上传日期和国家）
%new - (void)addVideoInfoLabels {
    // 移除已存在的标签，避免重复添加
    UIView *existingDateLabel = [self viewWithTag:1001];
    UIView *existingCountryLabel = [self viewWithTag:1002];
    if (existingDateLabel) [existingDateLabel removeFromSuperview];
    if (existingCountryLabel) [existingCountryLabel removeFromSuperview];
    
    // 获取视频模型
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if (!rootVC || !rootVC.model) return;
    
    AWEAwemeModel *model = rootVC.model;
    NSNumber *createTime = model.createTime;
    NSString *region = model.region;
    
    // 查找用户名标签作为参考位置
    UIView *usernameButton = nil;
    for (UIView *subview in self.subviews) {
        // 查找AWEPlayInteractionAuthorUserNameButton
        if ([subview isKindOfClass:%c(AWEPlayInteractionAuthorUserNameButton)]) {
            usernameButton = subview;
            break;
        }
    }
    
    // 如果没找到用户名按钮，尝试查找其他可能的用户名相关视图
    if (!usernameButton) {
        for (UIView *subview in self.subviews) {
            // 查找包含用户名标签的视图
            for (UIView *subSubview in subview.subviews) {
                if ([subSubview isKindOfClass:%c(AWEUserNameLabel)]) {
                    usernameButton = subview;
                    break;
                }
            }
            if (usernameButton) break;
        }
    }
    
    // 添加上传日期标签
    if ([BHIManager videoUploadDate] && createTime) {
        UILabel *uploadDateLabel = [[UILabel alloc] init];
        uploadDateLabel.tag = 1001;
        uploadDateLabel.text = [self formattedDateStringFromTimestamp:[createTime doubleValue]];
        uploadDateLabel.font = [UIFont systemFontOfSize:12];
        uploadDateLabel.textColor = [UIColor whiteColor];
        uploadDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 添加时钟图标
        NSTextAttachment *clockAttachment = [[NSTextAttachment alloc] init];
        clockAttachment.image = [UIImage systemImageNamed:@"clock"];
        NSAttributedString *clockIcon = [NSAttributedString attributedStringWithAttachment:clockAttachment];
        NSMutableAttributedString *dateText = [[NSMutableAttributedString alloc] initWithAttributedString:clockIcon];
        [dateText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [dateText appendAttributedString:[[NSAttributedString alloc] initWithString:uploadDateLabel.text]];
        uploadDateLabel.attributedText = dateText;
        
        [self addSubview:uploadDateLabel];
        
        // 设置约束 - 基于用户名按钮位置
        if (usernameButton) {
            [NSLayoutConstraint activateConstraints:@[
                [uploadDateLabel.topAnchor constraintEqualToAnchor:usernameButton.bottomAnchor constant:10], // 用户名下方空一行
                [uploadDateLabel.leadingAnchor constraintEqualToAnchor:usernameButton.leadingAnchor],
                [uploadDateLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20]
            ]];
        } else {
            // 如果找不到用户名按钮，使用默认位置
            [NSLayoutConstraint activateConstraints:@[
                [uploadDateLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:120],
                [uploadDateLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
                [uploadDateLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20]
            ]];
        }
    }
    
    // 添加国家标签
    if ([BHIManager uploadRegion] && region) {
        UILabel *countryLabel = [[UILabel alloc] init];
        countryLabel.tag = 1002;
        countryLabel.font = [UIFont systemFontOfSize:12];
        countryLabel.textColor = [UIColor whiteColor];
        countryLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 使用文字显示地区而不是国旗emoji
        NSString *countryText = [NSString stringWithFormat:@"%@", region];
        
        // 添加地球图标
        NSTextAttachment *globeAttachment = [[NSTextAttachment alloc] init];
        globeAttachment.image = [UIImage systemImageNamed:@"globe"];
        NSAttributedString *globeIcon = [NSAttributedString attributedStringWithAttachment:globeAttachment];
        NSMutableAttributedString *regionText = [[NSMutableAttributedString alloc] initWithAttributedString:globeIcon];
        [regionText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [regionText appendAttributedString:[[NSAttributedString alloc] initWithString:countryText]];
        countryLabel.attributedText = regionText;
        
        [self addSubview:countryLabel];
        
        // 设置约束 - 基于日期标签位置
        UIView *dateLabel = [self viewWithTag:1001];
        if (dateLabel) {
            [NSLayoutConstraint activateConstraints:@[
                [countryLabel.topAnchor constraintEqualToAnchor:dateLabel.bottomAnchor constant:10], // 日期下方空一行
                [countryLabel.leadingAnchor constraintEqualToAnchor:dateLabel.leadingAnchor],
                [countryLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20]
            ]];
        } else if (usernameButton) {
            // 如果没有日期标签但有用户名按钮，直接放在用户名下方
            [NSLayoutConstraint activateConstraints:@[
                [countryLabel.topAnchor constraintEqualToAnchor:usernameButton.bottomAnchor constant:10], // 用户名下方空一行
                [countryLabel.leadingAnchor constraintEqualToAnchor:usernameButton.leadingAnchor],
                [countryLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20]
            ]];
        } else {
            // 如果都找不到，使用默认位置
            [NSLayoutConstraint activateConstraints:@[
                [countryLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:150],
                [countryLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
                [countryLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20]
            ]];
        }
    }
}

// 格式化日期时间戳为字符串
%new - (NSString *)formattedDateStringFromTimestamp:(NSTimeInterval)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    return [formatter stringFromDate:date];
}

// 根据地区名称获取国家代码
%new - (NSString *)getCountryCodeFromRegion:(NSString *)region {
    // 常见地区名称到国家代码的映射
    NSDictionary *regionToCountryCode = @{
        @"United States": @"US",
        @"United Kingdom": @"GB",
        @"China": @"CN",
        @"Japan": @"JP",
        @"South Korea": @"KR",
        @"Canada": @"CA",
        @"Australia": @"AU",
        @"France": @"FR",
        @"Germany": @"DE",
        @"Italy": @"IT",
        @"Spain": @"ES",
        @"Russia": @"RU",
        @"India": @"IN",
        @"Brazil": @"BR",
        @"Mexico": @"MX",
        @"Argentina": @"AR",
        @"Chile": @"CL",
        @"Colombia": @"CO",
        @"Peru": @"PE",
        @"Venezuela": @"VE",
        @"Egypt": @"EG",
        @"South Africa": @"ZA",
        @"Nigeria": @"NG",
        @"Kenya": @"KE",
        @"Morocco": @"MA",
        @"Ghana": @"GH",
        @"Thailand": @"TH",
        @"Vietnam": @"VN",
        @"Philippines": @"PH",
        @"Indonesia": @"ID",
        @"Malaysia": @"MY",
        @"Singapore": @"SG",
        @"Pakistan": @"PK",
        @"Bangladesh": @"BD",
        @"Sri Lanka": @"LK",
        @"Myanmar": @"MM",
        @"Cambodia": @"KH",
        @"Laos": @"LA",
        @"New Zealand": @"NZ",
        @"Turkey": @"TR",
        @"Saudi Arabia": @"SA",
        @"Israel": @"IL",
        @"UAE": @"AE",
        @"Iran": @"IR",
        @"Iraq": @"IQ",
        @"Poland": @"PL",
        @"Netherlands": @"NL",
        @"Belgium": @"BE",
        @"Switzerland": @"CH",
        @"Austria": @"AT",
        @"Sweden": @"SE",
        @"Norway": @"NO",
        @"Denmark": @"DK",
        @"Finland": @"FI",
        @"Greece": @"GR",
        @"Portugal": @"PT",
        @"Ireland": @"IE",
        @"Czech Republic": @"CZ",
        @"Hungary": @"HU",
        @"Romania": @"RO",
        @"Bulgaria": @"BG",
        @"Croatia": @"HR",
        @"Slovakia": @"SK",
        @"Slovenia": @"SI",
        @"Estonia": @"EE",
        @"Latvia": @"LV",
        @"Lithuania": @"LT",
        @"Ukraine": @"UA",
        @"Belarus": @"BY",
        @"Moldova": @"MD",
        @"Cyprus": @"CY",
        @"Luxembourg": @"LU",
        @"Malta": @"MT",
        @"Iceland": @"IS",
        @"Albania": @"AL",
        @"Macedonia": @"MK",
        @"Serbia": @"RS",
        @"Montenegro": @"ME",
        @"Bosnia": @"BA",
        @"Senegal": @"SN",
        @"Ivory Coast": @"CI",
        @"Mali": @"ML",
        @"Burkina Faso": @"BF",
        @"Niger": @"NE",
        @"Benin": @"BJ",
        @"Togo": @"TG",
        @"Guinea": @"GN",
        @"Sierra Leone": @"SL",
        @"Liberia": @"LR",
        @"Gambia": @"GM",
        @"Guinea-Bissau": @"GW",
        @"Cape Verde": @"CV",
        @"Mauritania": @"MR",
        @"Somalia": @"SO",
        @"Djibouti": @"DJ",
        @"Eritrea": @"ER",
        @"Sudan": @"SD",
        @"Libya": @"LY",
        @"Tunisia": @"TN",
        @"Algeria": @"DZ"
    };
    
    // 尝试从映射中获取国家代码
    NSString *countryCode = regionToCountryCode[region];
    if (countryCode) {
        return countryCode;
    }
    
    // 如果没有找到，尝试从地区名称中提取可能的代码
    if (region.length >= 2) {
        // 尝试取最后两个字符作为国家代码
        NSString *possibleCode = [[region substringFromIndex:region.length - 2] uppercaseString];
        return possibleCode;
    }
    
    // 默认返回US
    return @"US";
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
