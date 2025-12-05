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
#import "BHTikTokLocalization.h"

@interface ViewController ()
@property (nonatomic, strong) UITableView *staticTable;
@property (nonatomic, assign) BOOL isAdditionalCellVisible;
@property (nonatomic, assign) UIImage *devImage;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.title = BHTikTokLocalizedString(@"BHTikTok++ Settings", nil);
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
            return BHTikTokLocalizedString(@"Feed", nil);
        case 1:
            return BHTikTokLocalizedString(@"Profile", nil);
        case 2:
            return BHTikTokLocalizedString(@"Confirm", nil);
        case 3:
            return BHTikTokLocalizedString(@"Other", nil);
        case 4:
            return BHTikTokLocalizedString(@"Region", nil);
            break;
        case 5:
            return BHTikTokLocalizedString(@"Live Button Function", nil);
        case 6:
            return BHTikTokLocalizedString(@"Playback Speed", nil);
        case 7:
            return BHTikTokLocalizedString(@"Developer", nil);
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
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Hide Ads", nil)
                                                Detail:BHTikTokLocalizedString(@"Hide all ads from the app", nil)
                                                   Key:@"hide_ads"];
            case 1:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Download Button", nil)
                                                Detail:BHTikTokLocalizedString(@"Enable download button for videos", nil)
                                                   Key:@"download_button"];
            case 2:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Share Sheet", nil)
                                                Detail:BHTikTokLocalizedString(@"Enable sharing options in share sheet", nil)
                                                   Key:@"share_sheet"];
            case 3:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Remove Watermark", nil)
                                                Detail:BHTikTokLocalizedString(@"Remove the TikTok watermark from videos", nil)
                                                   Key:@"remove_watermark"];
            case 4:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Show/Hide UI Button", nil)
                                                Detail:BHTikTokLocalizedString(@"Show or hide the UI button", nil)
                                                   Key:@"remove_elements_button"];
            case 5:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Stop Playback", nil)
                                                Detail:BHTikTokLocalizedString(@"Stop video playback automatically", nil)
                                                   Key:@"stop_play"];
            case 6:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Auto Play Next Video", nil)
                                                Detail:BHTikTokLocalizedString(@"Automatically play the next video", nil)
                                                   Key:@"auto_play"];
            case 7:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Show Progress Bar", nil)
                                                Detail:BHTikTokLocalizedString(@"Display progress bar on video playback", nil)
                                                   Key:@"show_porgress_bar"];
            case 8:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Transparent Comments", nil)
                                                Detail:BHTikTokLocalizedString(@"Make comments transparent", nil)
                                                   Key:@"transparent_commnet"];
            case 9:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Show Usernames", nil)
                                                Detail:BHTikTokLocalizedString(@"Display usernames on videos", nil)
                                                   Key:@"show_username"];
            case 10:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Disable Sensitive Content", nil)
                                                Detail:BHTikTokLocalizedString(@"Disable sensitive content filter", nil)
                                                   Key:@"disable_unsensitive"];
            case 11:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Disable Warnings", nil)
                                                Detail:BHTikTokLocalizedString(@"Disable TikTok warnings", nil)
                                                   Key:@"disable_warnings"];
            case 12:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Disable Live Streaming", nil)
                                                Detail:BHTikTokLocalizedString(@"Disable live video streaming", nil)
                                                   Key:@"disable_live"];
            case 13:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Skip Recommendations", nil)
                                                Detail:BHTikTokLocalizedString(@"Skip recommended videos", nil)
                                                   Key:@"skip_recommnedations"];
            case 14:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Upload Region", nil)
                                                Detail:BHTikTokLocalizedString(@"Show Upload Region Flag Next to Username", nil)
                                                   Key:@"upload_region"];
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Profile Save", nil)
                                                Detail:BHTikTokLocalizedString(@"Save profile details to clipboard", nil)
                                                   Key:@"save_profile"];
            case 1:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Profile Copy", nil)
                                                Detail:BHTikTokLocalizedString(@"Copy profile information", nil)
                                                   Key:@"copy_profile_information"];
            case 2:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Video Like Count", nil)
                                                Detail:BHTikTokLocalizedString(@"Show the number of likes on videos", nil)
                                                   Key:@"video_like_count"];
            case 3:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Video Upload Date", nil)
                                                Detail:BHTikTokLocalizedString(@"Show the date videos were uploaded", nil)
                                                   Key:@"video_upload_date"];
            default:
                break;
        }
    } else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Like Confirmation", nil)
                                                Detail:BHTikTokLocalizedString(@"Confirm before liking a video", nil)
                                                   Key:@"like_confirm"];
            case 1:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Like Comment Confirmation", nil)
                                                Detail:BHTikTokLocalizedString(@"Confirm before liking a comment", nil)
                                                   Key:@"like_comment_confirm"];
            case 2:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Dislike Comment Confirmation", nil)
                                                Detail:BHTikTokLocalizedString(@"Confirm before disliking a comment", nil)
                                                   Key:@"dislike_comment_confirm"];
            case 3:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Follow Confirmation", nil)
                                                Detail:BHTikTokLocalizedString(@"Confirm before following a user", nil)
                                                   Key:@"follow_confirm"];
            default:
                break;
        }
    } else if (indexPath.section == 3) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Always Open Safari", nil)
                                                Detail:BHTikTokLocalizedString(@"Always open links in Safari", nil)
                                                   Key:@"openInBrowser"];
            case 1:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Enable Fake Changes", nil)
                                                Detail:BHTikTokLocalizedString(@"Enable fake profile changes", nil)
                                                   Key:@"en_fake"];
            case 2: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                
                UILabel *followerLabel = [[UILabel alloc] init];
                followerLabel.text = BHTikTokLocalizedString(@"Follower:", nil);
                followerLabel.font = [UIFont systemFontOfSize:16];
                followerLabel.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:followerLabel];
                
                UITextField *textField = [[UITextField alloc] init];
                textField.placeholder = BHTikTokLocalizedString(@"Enter follower count", nil);
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
                followingLabel.text = BHTikTokLocalizedString(@"Following:", nil);
                followingLabel.font = [UIFont systemFontOfSize:16];
                followingLabel.translatesAutoresizingMaskIntoConstraints = NO;
                [cell.contentView addSubview:followingLabel];
                
                UITextField *textField = [[UITextField alloc] init];
                textField.placeholder = BHTikTokLocalizedString(@"Enter following count", nil);
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
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Fake Verified", nil)
                                                Detail:BHTikTokLocalizedString(@"Make your account appear verified", nil)
                                                   Key:@"fake_verify"];
            case 5:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Extended Bio", nil)
                                                Detail:BHTikTokLocalizedString(@"Extend bio section of your profile", nil)
                                                   Key:@"extended_bio"];
            case 6:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Extended Comments", nil)
                                                Detail:BHTikTokLocalizedString(@"Extend the length of your comments", nil)
                                                   Key:@"extendedComment"];
            case 7:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Upload HD", nil)
                                                Detail:BHTikTokLocalizedString(@"Upload videos in HD quality", nil)
                                                   Key:@"upload_hd"];
            case 8:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"App Lock", nil)
                                                Detail:BHTikTokLocalizedString(@"Lock the app with a passcode", nil)
                                                   Key:@"padlock"];
            case 9:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Enable Flex", nil)
                                                Detail:BHTikTokLocalizedString(@"Developers Only, DON'T touch it if you don't know what you are doing.", nil)
                                                   Key:@"flex_enebaled"];
            default:
                break;
        }
    } else if (indexPath.section == 4) {
        switch (indexPath.row) {
            case 0:
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Enable Region Changing", nil)
                                                Detail:BHTikTokLocalizedString(@"Enable region changing functionality", nil)
                                                   Key:@"en_region"];
            case 1: {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                UITableViewCell *regions = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                regions.textLabel.text = BHTikTokLocalizedString(@"Regions", nil);
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
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Live Button Action", nil)
                                                Detail:BHTikTokLocalizedString(@"Change The Default Live Button Action", nil)
                                                   Key:@"en_livefunc"];
            case 1: {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                UITableViewCell *liveAction = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                liveAction.textLabel.text = BHTikTokLocalizedString(@"Actions", nil);
                NSString *selectedLiveAction = [defaults valueForKey:@"live_action"];
                NSArray *liveFuncTitles = @[BHTikTokLocalizedString(@"Default", nil), BHTikTokLocalizedString(@"BHTikTok++ Settings", nil), BHTikTokLocalizedString(@"Playback Speed", nil)];
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
                return [self createSwitchCellWithTitle:BHTikTokLocalizedString(@"Playback Speed", nil)
                                                Detail:BHTikTokLocalizedString(@"Enable Presistent Playback Speed.", nil)
                                                   Key:@"playback_en"];
            }
            case 1: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = BHTikTokLocalizedString(@"Speeds", nil);
                
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
                cell.textLabel.text = BHTikTokLocalizedString(@"Raul Saeed", nil);
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.detailTextLabel.text = BHTikTokLocalizedString(@"Github Page", nil);
                cell.imageView.image = [UIImage systemImageNamed:@"link"];
                cell.detailTextLabel.textColor = [UIColor systemGrayColor];
                return cell;
            }
            case 1: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = BHTikTokLocalizedString(@"Raul Saeed", nil);
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.detailTextLabel.text = BHTikTokLocalizedString(@"X Page", nil);
                cell.imageView.image = [UIImage systemImageNamed:@"link"];
                cell.detailTextLabel.textColor = [UIColor systemGrayColor];
                return cell;
            }
            case 2: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                cell.textLabel.text = BHTikTokLocalizedString(@"Buy Me A Coffee", nil);
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.detailTextLabel.text = BHTikTokLocalizedString(@"To keep me Motivated and the Tweak Updated.", nil);
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
    
    
    
    cell.textLabel.text = title;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = detail;
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