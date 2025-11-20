//
//  ViewController.m
//  StaticTableView
//
//  Created by raul on 08/10/2024.
//

#import "ViewController.h"
#import "CountryTable.h"
#import "LiveActions.h"
#import "PlaybackSpeed.h"

@interface ViewController ()
@property (nonatomic, strong) UITableView *staticTable;
@property (nonatomic, assign) BOOL isAdditionalCellVisible;
@property (nonatomic, assign) UIImage *devImage;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.title = NSLocalizedString(@"BHTikTok++ Settings", nil);
    self.staticTable = [[UITableView alloc] initWithFrame:CGRectZero ];
    self.staticTable.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.staticTable];
    [NSLayoutConstraint activateConstraints:@[
        [self.staticTable.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.staticTable.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.staticTable.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.staticTable.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    self.staticTable.dataSource = self;
    self.staticTable.delegate = self;
    self.staticTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(regionSelected:)
                                                 name:@"RegionSelectedNotification"
                                               object:nil];
}
- (void)regionSelected:(NSNotification *)notification {
    [self.staticTable reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 8;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"Feed", nil);
        case 1:
            return NSLocalizedString(@"Profile", nil);
        case 2:
            return NSLocalizedString(@"Confirm Settings", nil);
        case 3:
            return NSLocalizedString(@"Other", nil);
        case 4:
            return NSLocalizedString(@"Region", nil);
            break;
        case 5:
            return NSLocalizedString(@"Live Button Function", nil);
        case 6:
            return NSLocalizedString(@"Playback Speed", nil);
        case 7:
            return NSLocalizedString(@"Developer", nil);
        default:
            break;
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: // Feed section
            return 15;
        case 1: // Profile section
            return 4;
        case 2: // Confirm section
            return 4;
        case 3: // Other section
            return 10;
        case 4:
            return 2; // region section
        case 5:
            return 2; // live action section
        case 6:
            return 2;
        case 7:
            return 3; // developer section
        default:
            return 0; // Fallback for unexpected section
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Hide Ads"
                                                Detail:@"FEATURE_HIDE_ADS"
                                                   Key:@"hide_ads"];
            case 1:
                return [self createSwitchCellWithTitle:@"Download Button"
                                                Detail:@"FEATURE_DOWNLOAD_BUTTON"
                                                   Key:@"download_button"];
            case 2:
                return [self createSwitchCellWithTitle:@"Share Sheet"
                                                Detail:@"FEATURE_SHARE_SHEET"
                                                   Key:@"share_sheet"];
            case 3:
                return [self createSwitchCellWithTitle:@"Remove Watermark"
                                                Detail:@"FEATURE_REMOVE_WATERMARK"
                                                   Key:@"remove_watermark"];
            case 4:
                return [self createSwitchCellWithTitle:@"Show/Hide UI Button"
                                                Detail:@"FEATURE_UI_BUTTON"
                                                   Key:@"remove_elements_button"];
            case 5:
                return [self createSwitchCellWithTitle:@"Stop Playback"
                                                Detail:@"FEATURE_STOP_PLAYBACK"
                                                   Key:@"stop_play"];
            case 6:
                return [self createSwitchCellWithTitle:@"Auto Play Next Video"
                                                Detail:@"FEATURE_AUTO_PLAY"
                                                   Key:@"auto_play"];
            case 7:
                return [self createSwitchCellWithTitle:@"Show Progress Bar"
                                                Detail:@"FEATURE_PROGRESS_BAR"
                                                   Key:@"show_porgress_bar"];
            case 8:
                return [self createSwitchCellWithTitle:@"Transparent Comments"
                                                Detail:@"FEATURE_TRANSPARENT_COMMENTS"
                                                   Key:@"transparent_commnet"];
            case 9:
                return [self createSwitchCellWithTitle:@"Show Usernames"
                                                Detail:@"FEATURE_SHOW_USERNAMES"
                                                   Key:@"show_username"];
            case 10:
                return [self createSwitchCellWithTitle:@"Disable Sensitive Content"
                                                Detail:@"FEATURE_DISABLE_SENSITIVE"
                                                   Key:@"disable_unsensitive"];
            case 11:
                return [self createSwitchCellWithTitle:@"Disable Warnings"
                                                Detail:@"FEATURE_DISABLE_WARNINGS"
                                                   Key:@"disable_warnings"];
            case 12:
                return [self createSwitchCellWithTitle:@"Disable Live Streaming"
                                                Detail:@"FEATURE_DISABLE_LIVE"
                                                   Key:@"disable_live"];
            case 13:
                return [self createSwitchCellWithTitle:@"Skip Recommendations"
                                                Detail:@"FEATURE_SKIP_RECOMMENDED"
                                                   Key:@"skip_recommnedations"];
            case 14:
                return [self createSwitchCellWithTitle:@"Upload Region"
                                                Detail:@"FEATURE_UPLOAD_REGION"
                                                   Key:@"upload_region"];
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Profile Save"
                                                Detail:@"FEATURE_PROFILE_SAVE"
                                                   Key:@"save_profile"];
            case 1:
                return [self createSwitchCellWithTitle:@"Profile Copy"
                                                Detail:@"FEATURE_PROFILE_COPY"
                                                   Key:@"copy_profile_information"];
            case 2:
                return [self createSwitchCellWithTitle:@"Video Like Count"
                                                Detail:@"FEATURE_LIKE_COUNT"
                                                   Key:@"video_like_count"];
            case 3:
                return [self createSwitchCellWithTitle:@"Video Upload Date"
                                                Detail:@"FEATURE_UPLOAD_DATE"
                                                   Key:@"video_upload_date"];
            default:
                break;
        }
    } else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Like Confirmation"
                                                Detail:@"FEATURE_CONFIRM_LIKE"
                                                   Key:@"like_confirm"];
            case 1:
                return [self createSwitchCellWithTitle:@"Like Comment Confirmation"
                                                Detail:@"FEATURE_CONFIRM_COMMENT_LIKE"
                                                   Key:@"like_comment_confirm"];
            case 2:
                return [self createSwitchCellWithTitle:@"Dislike Comment Confirmation"
                                                Detail:@"FEATURE_CONFIRM_COMMENT_DISLIKE"
                                                   Key:@"dislike_comment_confirm"];
            case 3:
                return [self createSwitchCellWithTitle:@"Follow Confirmation"
                                                Detail:@"FEATURE_CONFIRM_FOLLOW"
                                                   Key:@"follow_confirm"];
            default:
                break;
        }
    } else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Always Open Safari"
                                                Detail:@"Enable Embedded Links"
                                                   Key:@"openInBrowser"];
            case 1:
                return [self createSwitchCellWithTitle:@"Enable Fake Changes"
                                                Detail:@"FEATURE_FAKE_CHANGES"
                                                   Key:@"en_fake"];
            case 2: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                
                UILabel *followerLabel = [[UILabel alloc] init];
                followerLabel.text = @"Follower:";
                followerLabel.font = [UIFont systemFontOfSize:16];
                followerLabel.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:followerLabel];
                
                UITextField *textField = [[UITextField alloc] init];
                textField.placeholder = @"Enter follower count";
                textField.borderStyle = UITextBorderStyleRoundedRect;
                textField.delegate = self;
                textField.tag = 2;
                textField.returnKeyType = UIReturnKeyDone;
                textField.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:textField];
                
                [NSLayoutConstraint activateConstraints:@[
                    [followerLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:15],
                    [followerLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                    [followerLabel.widthAnchor constraintEqualToConstant:100],
                    
                    [textField.leadingAnchor constraintEqualToAnchor:followerLabel.trailingAnchor constant:10],
                    [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-15],
                    [textField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                    [textField.heightAnchor constraintEqualToConstant:30]
                ]];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *savedText = [defaults stringForKey:@"following_count"];
                if (savedText) {
                    textField.text = savedText;
                }
                
                return cell;
            }
            case 3: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                
                UILabel *followingLabel = [[UILabel alloc] init];
                followingLabel.text = @"Following:";
                followingLabel.font = [UIFont systemFontOfSize:16];
                followingLabel.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:followingLabel];
                
                UITextField *textField = [[UITextField alloc] init];
                textField.placeholder = @"Enter following count";
                textField.borderStyle = UITextBorderStyleRoundedRect;
                textField.delegate = self;
                textField.tag = 1;
                textField.returnKeyType = UIReturnKeyDone;
                textField.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:textField];
                
                [NSLayoutConstraint activateConstraints:@[
                    [followingLabel.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:15],
                    [followingLabel.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                    [followingLabel.widthAnchor constraintEqualToConstant:100],
                    
                    [textField.leadingAnchor constraintEqualToAnchor:followingLabel.trailingAnchor constant:10],
                    [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-15],
                    [textField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                    [textField.heightAnchor constraintEqualToConstant:30]
                ]];
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *savedText = [defaults stringForKey:@"following_count"];
                if (savedText) {
                    textField.text = savedText;
                }
                
                return cell;
            }
            case 4:
                return [self createSwitchCellWithTitle:@"Fake Verified"
                                                Detail:@"FEATURE_FAKE_VERIFIED"
                                                   Key:@"fake_verify"];
            case 5:
                return [self createSwitchCellWithTitle:@"Extended Bio"
                                                Detail:@"FEATURE_PROFILE_COPY"
                                                   Key:@"extended_bio"];
            case 6:
                return [self createSwitchCellWithTitle:@"Extended Comments"
                                                Detail:@"FEATURE_EXTENDED_COMMENTS"
                                                   Key:@"extendedComment"];
            case 7:
                return [self createSwitchCellWithTitle:@"Upload HD"
                                                Detail:@"FEATURE_UPLOAD_HD"
                                                   Key:@"upload_hd"];
            case 8:
                return [self createSwitchCellWithTitle:@"App Lock"
                                                Detail:@"FEATURE_APP_LOCK"
                                                   Key:@"padlock"];
            case 9:
                return [self createSwitchCellWithTitle:@"Enable Flex"
                                                Detail:@"FEATURE_ENABLE_FLEX"
                                                   Key:@"flex_enebaled"];
            default:
                break;
        }
    } else if (indexPath.section == 4) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Enable Region Changing"
                                                Detail:@"Enable Region Changing Functionality"
                                                   Key:@"en_region"];
            case 1: {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                UITableViewCell *regions = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                regions.textLabel.text = NSLocalizedString(@"Regions", nil);
                NSDictionary *selectedRegion = [defaults dictionaryForKey:@"region"];
                regions.detailTextLabel.text = [NSString stringWithFormat:@"%@", selectedRegion[@"area"]];
                return regions;
            }
            default:
                break;
        }
    } else if (indexPath.section == 5) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:@"Live Button Action"
                                                Detail:@"Change The Default Live Button Action"
                                                   Key:@"en_livefunc"];
            case 1: {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                UITableViewCell *liveAction = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                liveAction.textLabel.text = NSLocalizedString(@"Actions", nil);
                NSString *selectedLiveAction = [defaults valueForKey:@"live_action"];
                NSArray *liveFuncTitles = @[NSLocalizedString(@"Default", nil), NSLocalizedString(@"BHTikTok++ Settings", nil), NSLocalizedString(@"Playback Speed", nil)];
                if (selectedLiveAction != nil) {
                    liveAction.detailTextLabel.text = [NSString stringWithFormat:@"%@", [liveFuncTitles objectAtIndex:[selectedLiveAction integerValue]]];
                }
                
                return liveAction;
            }
                break;
            default:
                break;
        }
    } else if (indexPath.section == 6) {
        switch (indexPath.row) {
            case 0: {
                return [self createSwitchCellWithTitle:@"Playback Speed"
                                                Detail:@"Enable Presistent Playback Speed."
                                                   Key:@"playback_en"];
            }
            case 1: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = NSLocalizedString(@"Speeds", nil);
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *selectedSpeed = [defaults valueForKey:@"playback_speed"];
                if (selectedSpeed != nil) {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ x", selectedSpeed];
                }
                return cell;
            }
        }
    }
    else if (indexPath.section == 7) {
        switch (indexPath.row) {
            case 0: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = @"Raul Saeed";
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.detailTextLabel.text = @"Github Page";
                cell.imageView.image = [UIImage systemImageNamed:@"link"];
                cell.detailTextLabel.textColor = [UIColor systemGrayColor];
                return cell;
            }
            case 1: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = @"Raul Saeed";
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.detailTextLabel.text = @"X Page";
                cell.imageView.image = [UIImage systemImageNamed:@"link"];
                cell.detailTextLabel.textColor = [UIColor systemGrayColor];
                return cell;
            }
            case 2: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = @"Buy Me A Coffe";
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.detailTextLabel.text = @"To keep me Motivated and the Tweak Updated.";
                cell.imageView.tintColor = [UIColor orangeColor];
                cell.detailTextLabel.textColor = [UIColor systemGrayColor];
                cell.imageView.image = [UIImage systemImageNamed:@"mug.fill"];
                return cell;
            }
                break;
            default:
                break;
        }
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Selected row at index: %ld", (long)indexPath.section);
    if (indexPath.section == 4 && indexPath.row == 1){
        CountryTable *countryTable = [[CountryTable alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:countryTable];
        [self presentViewController:navController animated:YES completion:nil];
        
    }
    else if (indexPath.section == 5 && indexPath.row == 1){
        LiveActions *liveActions = [[LiveActions alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:liveActions];
        [self presentViewController:navController animated:YES completion:nil];
    } else if (indexPath.section == 6 && indexPath.row == 1) {
        PlaybackSpeed *liveActions = [[PlaybackSpeed alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:liveActions];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else if (indexPath.section == 7 && indexPath.row == 0){
        NSURL *url = [NSURL URLWithString:@"https://github.com/raulsaeed"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }
    else if (indexPath.section == 7 && indexPath.row == 1){
        NSURL *url = [NSURL URLWithString:@"https://x.com/Ashad__Saeed"];;
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }
    else if (indexPath.section == 7 && indexPath.row == 2){
        NSURL *url = [NSURL URLWithString:@"https://buymeacoffee.com/raulsaeed79"];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    }
}

- (UITableViewCell *)createSwitchCellWithTitle:(NSString *)title Detail:(NSString*)detail Key:(NSString*)key {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    
    
    UISwitch *switchView = [[UISwitch alloc] init];
    [cell.contentView addSubview:switchView];
    cell.accessoryView = switchView;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switchView.on = [defaults boolForKey:key];
    switchView.accessibilityLabel = key;
    [switchView addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    
    
    
    cell.textLabel.text = NSLocalizedString(title, nil);
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = NSLocalizedString(detail, nil);
    cell.detailTextLabel.textColor = [UIColor grayColor];
    return cell;
    
}

- (void)switchToggled:(UISwitch *)sender {
    
    NSString *key = sender.accessibilityLabel;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:key];
    [defaults synchronize];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == 1){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:textField.text forKey:@"following_count"];
        [defaults synchronize];
    } else if (textField.tag == 2){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:textField.text forKey:@"follower_count"];
        [defaults synchronize];
    }
    
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
