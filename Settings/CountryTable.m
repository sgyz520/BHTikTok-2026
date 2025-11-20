#import "CountryTable.h"
#import "BHIManager.h"

@interface CountryTable () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *regionTitles; // Holds the country names
@property (nonatomic, strong) NSArray *regionCodes;  // Holds the dictionaries of country details
@property (nonatomic, strong) UITableView *tableView; // The table view to show the list

@end
@interface AWEStoreRegionChangeManager: NSObject 
- (void)p_showStoreRegionChangedDialog;
+ (id)sharedInstance;
@end
@implementation CountryTable

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [BHIManager L:@"Regions"];
    self.regionTitles = @[@"沙特阿拉伯", @"中国台湾", @"中国香港", @"中国澳门", @"日本", @"韩国", @"英国", @"美国", @"澳大利亚", @"加拿大", @"阿根廷", @"菲律宾", @"老挝", @"马来西亚", @"泰国", @"新加坡", @"印度尼西亚", @"越南", @"安圭拉", @"巴拿马", @"德国", @"俄罗斯", @"法国", @"芬兰", @"意大利", @"巴基斯坦", @"丹麦", @"挪威", @"苏丹", @"罗马尼亚", @"阿拉伯联合酋长国", @"埃及", @"黎巴嫩", @"墨西哥", @"巴西", @"土耳其", @"科威特", @"阿尔及利亚"];
    
    self.regionCodes = @[
    @{@"area": @"沙特阿拉伯", @"name": @"沙特阿拉伯", @"code": @"SA", @"mcc": @"420", @"mnc": @"01"},
    @{@"area": @"中国台湾", @"name": @"中国台湾", @"code": @"TW", @"mcc": @"466", @"mnc": @"01"},
    @{@"area": @"中国香港", @"name": @"中国香港", @"code": @"HK", @"mcc": @"454", @"mnc": @"00"},
    @{@"area": @"中国澳门", @"name": @"中国澳门", @"code": @"MO", @"mcc": @"455", @"mnc": @"00"},
    @{@"area": @"日本", @"name": @"日本", @"code": @"JP", @"mcc": @"440", @"mnc": @"00"},
    @{@"area": @"韩国", @"name": @"韩国", @"code": @"KR", @"mcc": @"450", @"mnc": @"05"},
    @{@"area": @"英国", @"name": @"英国", @"code": @"GB", @"mcc": @"234", @"mnc": @"30"},
    @{@"area": @"美国", @"name": @"美国", @"code": @"US", @"mcc": @"310", @"mnc": @"00"},
    @{@"area": @"澳大利亚", @"name": @"澳大利亚", @"code": @"AU", @"mcc": @"505", @"mnc": @"02"},
    @{@"area": @"加拿大", @"name": @"加拿大", @"code": @"CA", @"mcc": @"302", @"mnc": @"720"},
    @{@"area": @"阿根廷", @"name": @"阿根廷", @"code": @"AR", @"mcc": @"722", @"mnc": @"07"},
    @{@"area": @"菲律宾", @"name": @"菲律宾", @"code": @"PH", @"mcc": @"515", @"mnc": @"02"},
    @{@"area": @"老挝", @"name": @"老挝", @"code": @"LA", @"mcc": @"457", @"mnc": @"01"},
    @{@"area": @"马来西亚", @"name": @"马来西亚", @"code": @"MY", @"mcc": @"502", @"mnc": @"13"},
    @{@"area": @"泰国", @"name": @"泰国", @"code": @"TH", @"mcc": @"520", @"mnc": @"18"},
    @{@"area": @"新加坡", @"name": @"新加坡", @"code": @"SG", @"mcc": @"525", @"mnc": @"01"},
    @{@"area": @"印度尼西亚", @"name": @"印度尼西亚", @"code": @"ID", @"mcc": @"510", @"mnc": @"01"},
    @{@"area": @"越南", @"name": @"越南", @"code": @"VN", @"mcc": @"452", @"mnc": @"01"},
    @{@"area": @"安圭拉", @"name": @"安圭拉", @"code": @"AI", @"mcc": @"365", @"mnc": @"840"},
    @{@"area": @"巴拿马", @"name": @"巴拿马", @"code": @"PA", @"mcc": @"714", @"mnc": @"04"},
    @{@"area": @"德国", @"name": @"德国", @"code": @"DE", @"mcc": @"262", @"mnc": @"01"},
    @{@"area": @"俄罗斯", @"name": @"俄罗斯", @"code": @"RU", @"mcc": @"250", @"mnc": @"01"},
    @{@"area": @"法国", @"name": @"法国", @"code": @"FR", @"mcc": @"208", @"mnc": @"10"},
    @{@"area": @"芬兰", @"name": @"芬兰", @"code": @"FI", @"mcc": @"244", @"mnc": @"91"},
    @{@"area": @"意大利", @"name": @"意大利", @"code": @"IT", @"mcc": @"222", @"mnc": @"10"},
    @{@"area": @"巴基斯坦", @"name": @"巴基斯坦", @"code": @"PK", @"mcc": @"410", @"mnc": @"01"},
    @{@"area": @"丹麦", @"name": @"丹麦", @"code": @"DK", @"mcc": @"238", @"mnc": @"01"},
    @{@"area": @"挪威", @"name": @"挪威", @"code": @"NO", @"mcc": @"242", @"mnc": @"01"},
    @{@"area": @"苏丹", @"name": @"苏丹", @"code": @"SD", @"mcc": @"634", @"mnc": @"01"},
    @{@"area": @"罗马尼亚", @"name": @"罗马尼亚", @"code": @"RO", @"mcc": @"226", @"mnc": @"01"},
    @{@"area": @"阿拉伯联合酋长国", @"name": @"阿拉伯联合酋长国", @"code": @"AE", @"mcc": @"424", @"mnc": @"02"},
    @{@"area": @"埃及", @"name": @"埃及", @"code": @"EG", @"mcc": @"602", @"mnc": @"01"},
    @{@"area": @"黎巴嫩", @"name": @"黎巴嫩", @"code": @"LB", @"mcc": @"415", @"mnc": @"01"},
    @{@"area": @"墨西哥", @"name": @"墨西哥", @"code": @"MX", @"mcc": @"334", @"mnc": @"030"},
    @{@"area": @"巴西", @"name": @"巴西", @"code": @"BR", @"mcc": @"724", @"mnc": @"06"},
    @{@"area": @"土耳其", @"name": @"土耳其", @"code": @"TR", @"mcc": @"286", @"mnc": @"01"},
    @{@"area": @"科威特", @"name": @"科威特", @"code": @"KW", @"mcc": @"419", @"mnc": @"02"},
    @{@"area": @"阿尔及利亚", @"name": @"阿尔及利亚", @"code": @"DZ", @"mcc": @"603", @"mnc": @"01"}
];

    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.regionTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = self.regionTitles[indexPath.row];
    
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *selectedRegion = self.regionCodes[indexPath.row];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:selectedRegion forKey:@"region"];
    [defaults synchronize];
    
    NSLog(@"Selected region: %@", selectedRegion);
    [[NSClassFromString(@"AWEStoreRegionChangeManager") sharedInstance] p_showStoreRegionChangedDialog];

}

@end
