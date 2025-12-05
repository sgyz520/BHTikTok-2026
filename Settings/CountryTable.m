#import "CountryTable.h"
#import "BHTikTokLocalization.h"

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
    self.title = BHTikTokLocalizedString(@"Regions", nil);
    self.regionTitles = @[@"Saudi Arabia 🇸🇦", @"Taiwan 🇹🇼", @"Hong Kong 🇭🇰", @"Macao 🇲🇴", @"Japan 🇯🇵", @"South Korea 🇰🇷", @"United Kingdom 🇬🇧", @"United States 🇺🇸", @"Australia 🇦🇺", @"Canada 🇨🇦", @"Argentina 🇦🇷", @"Philippines 🇵🇭", @"Laos 🇱🇦", @"Malaysia 🇲🇾", @"Thailand 🇹🇭", @"Singapore 🇸🇬", @"Indonesia 🇮🇩", @"Vietnam 🇻🇳", @"Anguilla 🇦🇮", @"Panama 🇵🇦", @"Germany 🇩🇪", @"Russia 🇷🇺", @"France 🇫🇷", @"Finland 🇫🇮", @"Italy 🇮🇹", @"Pakistan 🇵🇰", @"Denmark 🇩🇰", @"Norway 🇳🇴", @"Sudan 🇸🇩", @"Romania 🇷🇴", @"United Arab Emirates 🇦🇪", @"Egypt 🇪🇬", @"Lebanon 🇱🇧", @"Mexico 🇲🇽", @"Brazil 🇧🇷", @"Turkey 🇹🇷", @"Kuwait 🇰🇼", @"Algeria 🇩🇿", @"China 🇨🇳", @"North Korea 🇰🇵", @"Bangladesh 🇧🇩", @"Myanmar 🇲🇲", @"Cambodia 🇰🇭", @"Nepal 🇳🇵", @"Sri Lanka 🇱🇰", @"Maldives 🇲🇻", @"Bhutan 🇧🇹", @"Mongolia 🇲🇳", @"Kazakhstan 🇰🇿", @"Uzbekistan 🇺🇿", @"Kyrgyzstan 🇰🇬", @"Tajikistan 🇹🇯", @"Turkmenistan 🇹🇲", @"Afghanistan 🇦🇫", @"Iran 🇮🇷", @"Iraq 🇮🇶", @"Yemen 🇾🇪", @"Oman 🇴🇲", @"Jordan 🇯🇴", @"Syria 🇸🇾", @"Israel 🇮🇱", @"Palestine 🇵🇸", @"Bahrain 🇧🇭", @"Czech Republic 🇨🇿", @"Slovakia 🇸🇰", @"Hungary 🇭🇺", @"Poland 🇵🇱", @"Bulgaria 🇧🇬", @"Croatia 🇭🇷", @"Slovenia 🇸🇮", @"Estonia 🇪🇪", @"Latvia 🇱🇻", @"Lithuania 🇱🇹", @"Ukraine 🇺🇦", @"Belarus 🇧🇾", @"Moldova 🇲🇩", @"Albania 🇦🇱", @"Montenegro 🇲🇪", @"Serbia 🇷🇸", @"Bosnia and Herzegovina 🇧🇦", @"North Macedonia 🇲🇰", @"Andorra 🇦🇩", @"Monaco 🇲🇨", @"San Marino 🇸🇲", @"Vatican City 🇻🇦", @"Malta 🇲🇹", @"Liechtenstein 🇱🇮", @"Chile 🇨🇱", @"Peru 🇵🇪", @"Colombia 🇨🇴", @"Venezuela 🇻🇪", @"Ecuador 🇪🇨", @"Bolivia 🇧🇴", @"Paraguay 🇵🇾", @"Uruguay 🇺🇾", @"Guyana 🇬🇾", @"Suriname 🇸🇷", @"French Guiana 🇬🇫", @"Cuba 🇨🇺", @"Jamaica 🇯🇲", @"Haiti 🇭🇹", @"Dominican Republic 🇩🇴", @"Puerto Rico 🇵🇷", @"Costa Rica 🇨🇷", @"Guatemala 🇬🇹", @"Honduras 🇭🇳", @"El Salvador 🇸🇻", @"Nicaragua 🇳🇮", @"Belize 🇧🇿", @"Barbados 🇧🇧", @"Trinidad and Tobago 🇹🇹", @"Bahamas 🇧🇸", @"Nigeria 🇳🇬", @"Kenya 🇰🇪", @"Tanzania 🇹🇿", @"Uganda 🇺🇬", @"Ghana 🇬🇭", @"Côte d'Ivoire 🇨🇮", @"Senegal 🇸🇳", @"Morocco 🇲🇦", @"Tunisia 🇹🇳", @"Libya 🇱🇾", @"Ethiopia 🇪🇹", @"Malawi 🇲🇼", @"Zambia 🇿🇲", @"Zimbabwe 🇿🇼", @"Botswana 🇧🇼", @"Namibia 🇳🇦", @"Mozambique 🇲🇿", @"Angola 🇦🇴", @"Cameroon 🇨🇲", @"Democratic Republic of the Congo 🇨🇩", @"Republic of the Congo 🇨🇬", @"Gabon 🇬🇦", @"Equatorial Guinea 🇬🇶", @"Central African Republic 🇨🇫", @"Chad 🇹🇩", @"Niger 🇳🇪", @"Burkina Faso 🇧🇫", @"Mali 🇲🇱", @"Mauritania 🇲🇷", @"Sierra Leone 🇸🇱", @"Liberia 🇱🇷", @"Guinea 🇬🇳", @"Guinea-Bissau 🇬🇼", @"Gambia 🇬🇲", @"São Tomé and Príncipe 🇸🇹", @"Cape Verde 🇨🇻", @"Seychelles 🇸🇨", @"Mauritius 🇲🇺", @"Madagascar 🇲🇬", @"Comoros 🇰🇲", @"Reunion 🇷🇪", @"Mayotte 🇾🇹", @"Saint Helena 🇸🇭", @"Burundi 🇧🇮", @"Rwanda 🇷🇼", @"Somalia 🇸🇴", @"Djibouti 🇩🇯", @"Eritrea 🇪🇷", @"New Zealand 🇳🇿", @"Papua New Guinea 🇵🇬", @"Fiji 🇫🇯", @"Solomon Islands 🇸🇧", @"Vanuatu 🇻🇺", @"New Caledonia 🇳🇨", @"French Polynesia 🇵🇫", @"Samoa 🇼🇸", @"Kiribati 🇰🇮", @"Tonga 🇹🇴", @"Tuvalu 🇹🇻", @"Nauru 🇳🇷", @"Palau 🇵🇼", @"Micronesia 🇫🇲", @"Marshall Islands 🇲🇭", @"Guam 🇬🇺", @"Northern Mariana Islands 🇲🇵", @"American Samoa 🇦🇸", @"Cook Islands 🇨🇰", @"Niue 🇳🇺", @"Tokelau 🇹🇰", @"Norfolk Island 🇳🇫"];
    
    self.regionCodes = @[
    @{@"area": @"Saudi Arabia 🇸🇦", @"name": @"Saudi Arabia", @"code": @"SA", @"mcc": @"420", @"mnc": @"01"},
    @{@"area": @"Taiwan 🇹🇼", @"name": @"Taiwan", @"code": @"TW", @"mcc": @"466", @"mnc": @"01"},
    @{@"area": @"Hong Kong 🇭🇰", @"name": @"Hong Kong", @"code": @"HK", @"mcc": @"454", @"mnc": @"00"},
    @{@"area": @"Macao 🇲🇴", @"name": @"Macao", @"code": @"MO", @"mcc": @"455", @"mnc": @"00"},
    @{@"area": @"Japan 🇯🇵", @"name": @"Japan", @"code": @"JP", @"mcc": @"440", @"mnc": @"00"},
    @{@"area": @"South Korea 🇰🇷", @"name": @"South Korea", @"code": @"KR", @"mcc": @"450", @"mnc": @"05"},
    @{@"area": @"United Kingdom 🇬🇧", @"name": @"United Kingdom", @"code": @"GB", @"mcc": @"234", @"mnc": @"30"},
    @{@"area": @"United States 🇺🇸", @"name": @"United States", @"code": @"US", @"mcc": @"310", @"mnc": @"00"},
    @{@"area": @"Australia 🇦🇺", @"name": @"Australia", @"code": @"AU", @"mcc": @"505", @"mnc": @"02"},
    @{@"area": @"Canada 🇨🇦", @"name": @"Canada", @"code": @"CA", @"mcc": @"302", @"mnc": @"720"},
    @{@"area": @"Argentina 🇦🇷", @"name": @"Argentina", @"code": @"AR", @"mcc": @"722", @"mnc": @"07"},
    @{@"area": @"Philippines 🇵🇭", @"name": @"Philippines", @"code": @"PH", @"mcc": @"515", @"mnc": @"02"},
    @{@"area": @"Laos 🇱🇦", @"name": @"Laos", @"code": @"LA", @"mcc": @"457", @"mnc": @"01"},
    @{@"area": @"Malaysia 🇲🇾", @"name": @"Malaysia", @"code": @"MY", @"mcc": @"502", @"mnc": @"13"},
    @{@"area": @"Thailand 🇹🇭", @"name": @"Thailand", @"code": @"TH", @"mcc": @"520", @"mnc": @"18"},
    @{@"area": @"Singapore 🇸🇬", @"name": @"Singapore", @"code": @"SG", @"mcc": @"525", @"mnc": @"01"},
    @{@"area": @"Indonesia 🇮🇩", @"name": @"Indonesia", @"code": @"ID", @"mcc": @"510", @"mnc": @"01"},
    @{@"area": @"Vietnam 🇻🇳", @"name": @"Vietnam", @"code": @"VN", @"mcc": @"452", @"mnc": @"01"},
    @{@"area": @"Anguilla 🇦🇮", @"name": @"Anguilla", @"code": @"AI", @"mcc": @"365", @"mnc": @"840"},
    @{@"area": @"Panama 🇵🇦", @"name": @"Panama", @"code": @"PA", @"mcc": @"714", @"mnc": @"04"},
    @{@"area": @"Germany 🇩🇪", @"name": @"Germany", @"code": @"DE", @"mcc": @"262", @"mnc": @"01"},
    @{@"area": @"Russia 🇷🇺", @"name": @"Russia", @"code": @"RU", @"mcc": @"250", @"mnc": @"01"},
    @{@"area": @"France 🇫🇷", @"name": @"France", @"code": @"FR", @"mcc": @"208", @"mnc": @"10"},
    @{@"area": @"Finland 🇫🇮", @"name": @"Finland", @"code": @"FI", @"mcc": @"244", @"mnc": @"91"},
    @{@"area": @"Italy 🇮🇹", @"name": @"Italy", @"code": @"IT", @"mcc": @"222", @"mnc": @"10"},
    @{@"area": @"Pakistan 🇵🇰", @"name": @"Pakistan", @"code": @"PK", @"mcc": @"410", @"mnc": @"01"},
    @{@"area": @"Denmark 🇩🇰", @"name": @"Denmark", @"code": @"DK", @"mcc": @"238", @"mnc": @"01"},
    @{@"area": @"Norway 🇳🇴", @"name": @"Norway", @"code": @"NO", @"mcc": @"242", @"mnc": @"01"},
    @{@"area": @"Sudan 🇸🇩", @"name": @"Sudan", @"code": @"SD", @"mcc": @"634", @"mnc": @"01"},
    @{@"area": @"Romania 🇷🇴", @"name": @"Romania", @"code": @"RO", @"mcc": @"226", @"mnc": @"01"},
    @{@"area": @"United Arab Emirates 🇦🇪", @"name": @"United Arab Emirates", @"code": @"AE", @"mcc": @"424", @"mnc": @"02"},
    @{@"area": @"Egypt 🇪🇬", @"name": @"Egypt", @"code": @"EG", @"mcc": @"602", @"mnc": @"01"},
    @{@"area": @"Lebanon 🇱🇧", @"name": @"Lebanon", @"code": @"LB", @"mcc": @"415", @"mnc": @"01"},
    @{@"area": @"Mexico 🇲🇽", @"name": @"Mexico", @"code": @"MX", @"mcc": @"334", @"mnc": @"030"},
    @{@"area": @"Brazil 🇧🇷", @"name": @"Brazil", @"code": @"BR", @"mcc": @"724", @"mnc": @"06"},
    @{@"area": @"Turkey 🇹🇷", @"name": @"Turkey", @"code": @"TR", @"mcc": @"286", @"mnc": @"01"},
    @{@"area": @"Kuwait 🇰🇼", @"name": @"Kuwait", @"code": @"KW", @"mcc": @"419", @"mnc": @"02"},
    @{@"area": @"Algeria 🇩🇿", @"name": @"Algeria", @"code": @"DZ", @"mcc": @"603", @"mnc": @"01"},
    @{@"area": @"China 🇨🇳", @"name": @"China", @"code": @"CN", @"mcc": @"460", @"mnc": @"00"},
    @{@"area": @"North Korea 🇰🇵", @"name": @"North Korea", @"code": @"KP", @"mcc": @"467", @"mnc": @"01"},
    @{@"area": @"Bangladesh 🇧🇩", @"name": @"Bangladesh", @"code": @"BD", @"mcc": @"470", @"mnc": @"01"},
    @{@"area": @"Myanmar 🇲🇲", @"name": @"Myanmar", @"code": @"MM", @"mcc": @"414", @"mnc": @"01"},
    @{@"area": @"Cambodia 🇰🇭", @"name": @"Cambodia", @"code": @"KH", @"mcc": @"456", @"mnc": @"01"},
    @{@"area": @"Nepal 🇳🇵", @"name": @"Nepal", @"code": @"NP", @"mcc": @"429", @"mnc": @"01"},
    @{@"area": @"Sri Lanka 🇱🇰", @"name": @"Sri Lanka", @"code": @"LK", @"mcc": @"413", @"mnc": @"01"},
    @{@"area": @"Maldives 🇲🇻", @"name": @"Maldives", @"code": @"MV", @"mcc": @"472", @"mnc": @"01"},
    @{@"area": @"Bhutan 🇧🇹", @"name": @"Bhutan", @"code": @"BT", @"mcc": @"402", @"mnc": @"01"},
    @{@"area": @"Mongolia 🇲🇳", @"name": @"Mongolia", @"code": @"MN", @"mcc": @"482", @"mnc": @"01"},
    @{@"area": @"Kazakhstan 🇰🇿", @"name": @"Kazakhstan", @"code": @"KZ", @"mcc": @"401", @"mnc": @"01"},
    @{@"area": @"Uzbekistan 🇺🇿", @"name": @"Uzbekistan", @"code": @"UZ", @"mcc": @"434", @"mnc": @"01"},
    @{@"area": @"Kyrgyzstan 🇰🇬", @"name": @"Kyrgyzstan", @"code": @"KG", @"mcc": @"437", @"mnc": @"01"},
    @{@"area": @"Tajikistan 🇹🇯", @"name": @"Tajikistan", @"code": @"TJ", @"mcc": @"436", @"mnc": @"01"},
    @{@"area": @"Turkmenistan 🇹🇲", @"name": @"Turkmenistan", @"code": @"TM", @"mcc": @"438", @"mnc": @"01"},
    @{@"area": @"Afghanistan 🇦🇫", @"name": @"Afghanistan", @"code": @"AF", @"mcc": @"412", @"mnc": @"01"},
    @{@"area": @"Iran 🇮🇷", @"name": @"Iran", @"code": @"IR", @"mcc": @"432", @"mnc": @"01"},
    @{@"area": @"Iraq 🇮🇶", @"name": @"Iraq", @"code": @"IQ", @"mcc": @"418", @"mnc": @"01"},
    @{@"area": @"Yemen 🇾🇪", @"name": @"Yemen", @"code": @"YE", @"mcc": @"421", @"mnc": @"01"},
    @{@"area": @"Oman 🇴🇲", @"name": @"Oman", @"code": @"OM", @"mcc": @"422", @"mnc": @"01"},
    @{@"area": @"Jordan 🇯🇴", @"name": @"Jordan", @"code": @"JO", @"mcc": @"416", @"mnc": @"01"},
    @{@"area": @"Syria 🇸🇾", @"name": @"Syria", @"code": @"SY", @"mcc": @"417", @"mnc": @"01"},
    @{@"area": @"Israel 🇮🇱", @"name": @"Israel", @"code": @"IL", @"mcc": @"425", @"mnc": @"01"},
    @{@"area": @"Palestine 🇵🇸", @"name": @"Palestine", @"code": @"PS", @"mcc": @"426", @"mnc": @"01"},
    @{@"area": @"Bahrain 🇧🇭", @"name": @"Bahrain", @"code": @"BH", @"mcc": @"427", @"mnc": @"01"},
    @{@"area": @"Czech Republic 🇨🇿", @"name": @"Czech Republic", @"code": @"CZ", @"mcc": @"230", @"mnc": @"01"},
    @{@"area": @"Slovakia 🇸🇰", @"name": @"Slovakia", @"code": @"SK", @"mcc": @"231", @"mnc": @"01"},
    @{@"area": @"Hungary 🇭🇺", @"name": @"Hungary", @"code": @"HU", @"mcc": @"216", @"mnc": @"01"},
    @{@"area": @"Poland 🇵🇱", @"name": @"Poland", @"code": @"PL", @"mcc": @"260", @"mnc": @"01"},
    @{@"area": @"Bulgaria 🇧🇬", @"name": @"Bulgaria", @"code": @"BG", @"mcc": @"284", @"mnc": @"01"},
    @{@"area": @"Croatia 🇭🇷", @"name": @"Croatia", @"code": @"HR", @"mcc": @"219", @"mnc": @"01"},
    @{@"area": @"Slovenia 🇸🇮", @"name": @"Slovenia", @"code": @"SI", @"mcc": @"293", @"mnc": @"01"},
    @{@"area": @"Estonia 🇪🇪", @"name": @"Estonia", @"code": @"EE", @"mcc": @"248", @"mnc": @"01"},
    @{@"area": @"Latvia 🇱🇻", @"name": @"Latvia", @"code": @"LV", @"mcc": @"247", @"mnc": @"01"},
    @{@"area": @"Lithuania 🇱🇹", @"name": @"Lithuania", @"code": @"LT", @"mcc": @"246", @"mnc": @"01"},
    @{@"area": @"Ukraine 🇺🇦", @"name": @"Ukraine", @"code": @"UA", @"mcc": @"255", @"mnc": @"01"},
    @{@"area": @"Belarus 🇧🇾", @"name": @"Belarus", @"code": @"BY", @"mcc": @"257", @"mnc": @"01"},
    @{@"area": @"Moldova 🇲🇩", @"name": @"Moldova", @"code": @"MD", @"mcc": @"259", @"mnc": @"01"},
    @{@"area": @"Albania 🇦🇱", @"name": @"Albania", @"code": @"AL", @"mcc": @"276", @"mnc": @"01"},
    @{@"area": @"Montenegro 🇲🇪", @"name": @"Montenegro", @"code": @"ME", @"mcc": @"297", @"mnc": @"01"},
    @{@"area": @"Serbia 🇷🇸", @"name": @"Serbia", @"code": @"RS", @"mcc": @"220", @"mnc": @"01"},
    @{@"area": @"Bosnia and Herzegovina 🇧🇦", @"name": @"Bosnia and Herzegovina", @"code": @"BA", @"mcc": @"228", @"mnc": @"01"},
    @{@"area": @"North Macedonia 🇲🇰", @"name": @"North Macedonia", @"code": @"MK", @"mcc": @"294", @"mnc": @"01"},
    @{@"area": @"Andorra 🇦🇩", @"name": @"Andorra", @"code": @"AD", @"mcc": @"213", @"mnc": @"01"},
    @{@"area": @"Monaco 🇲🇨", @"name": @"Monaco", @"code": @"MC", @"mcc": @"208", @"mnc": @"05"},
    @{@"area": @"San Marino 🇸🇲", @"name": @"San Marino", @"code": @"SM", @"mcc": @"222", @"mnc": @"99"},
    @{@"area": @"Vatican City 🇻🇦", @"name": @"Vatican City", @"code": @"VA", @"mcc": @"222", @"mnc": @"98"},
    @{@"area": @"Malta 🇲🇹", @"name": @"Malta", @"code": @"MT", @"mcc": @"278", @"mnc": @"01"},
    @{@"area": @"Liechtenstein 🇱🇮", @"name": @"Liechtenstein", @"code": @"LI", @"mcc": @"228", @"mnc": @"02"},
    @{@"area": @"Chile 🇨🇱", @"name": @"Chile", @"code": @"CL", @"mcc": @"730", @"mnc": @"01"},
    @{@"area": @"Peru 🇵🇪", @"name": @"Peru", @"code": @"PE", @"mcc": @"716", @"mnc": @"01"},
    @{@"area": @"Colombia 🇨🇴", @"name": @"Colombia", @"code": @"CO", @"mcc": @"732", @"mnc": @"01"},
    @{@"area": @"Venezuela 🇻🇪", @"name": @"Venezuela", @"code": @"VE", @"mcc": @"734", @"mnc": @"01"},
    @{@"area": @"Ecuador 🇪🇨", @"name": @"Ecuador", @"code": @"EC", @"mcc": @"740", @"mnc": @"01"},
    @{@"area": @"Bolivia 🇧🇴", @"name": @"Bolivia", @"code": @"BO", @"mcc": @"736", @"mnc": @"01"},
    @{@"area": @"Paraguay 🇵🇾", @"name": @"Paraguay", @"code": @"PY", @"mcc": @"744", @"mnc": @"01"},
    @{@"area": @"Uruguay 🇺🇾", @"name": @"Uruguay", @"code": @"UY", @"mcc": @"748", @"mnc": @"01"},
    @{@"area": @"Guyana 🇬🇾", @"name": @"Guyana", @"code": @"GY", @"mcc": @"728", @"mnc": @"01"},
    @{@"area": @"Suriname 🇸🇷", @"name": @"Suriname", @"code": @"SR", @"mcc": @"742", @"mnc": @"01"},
    @{@"area": @"French Guiana 🇬🇫", @"name": @"French Guiana", @"code": @"GF", @"mcc": @"208", @"mnc": @"34"},
    @{@"area": @"Cuba 🇨🇺", @"name": @"Cuba", @"code": @"CU", @"mcc": @"368", @"mnc": @"01"},
    @{@"area": @"Jamaica 🇯🇲", @"name": @"Jamaica", @"code": @"JM", @"mcc": @"376", @"mnc": @"01"},
    @{@"area": @"Haiti 🇭🇹", @"name": @"Haiti", @"code": @"HT", @"mcc": @"372", @"mnc": @"01"},
    @{@"area": @"Dominican Republic 🇩🇴", @"name": @"Dominican Republic", @"code": @"DO", @"mcc": @"370", @"mnc": @"01"},
    @{@"area": @"Puerto Rico 🇵🇷", @"name": @"Puerto Rico", @"code": @"PR", @"mcc": @"310", @"mnc": @"330"},
    @{@"area": @"Costa Rica 🇨🇷", @"name": @"Costa Rica", @"code": @"CR", @"mcc": @"712", @"mnc": @"01"},
    @{@"area": @"Guatemala 🇬🇹", @"name": @"Guatemala", @"code": @"GT", @"mcc": @"704", @"mnc": @"01"},
    @{@"area": @"Honduras 🇭🇳", @"name": @"Honduras", @"code": @"HN", @"mcc": @"708", @"mnc": @"01"},
    @{@"area": @"El Salvador 🇸🇻", @"name": @"El Salvador", @"code": @"SV", @"mcc": @"706", @"mnc": @"01"},
    @{@"area": @"Nicaragua 🇳🇮", @"name": @"Nicaragua", @"code": @"NI", @"mcc": @"710", @"mnc": @"01"},
    @{@"area": @"Belize 🇧🇿", @"name": @"Belize", @"code": @"BZ", @"mcc": @"720", @"mnc": @"01"},
    @{@"area": @"Barbados 🇧🇧", @"name": @"Barbados", @"code": @"BB", @"mcc": @"350", @"mnc": @"01"},
    @{@"area": @"Trinidad and Tobago 🇹🇹", @"name": @"Trinidad and Tobago", @"code": @"TT", @"mcc": @"374", @"mnc": @"01"},
    @{@"area": @"Bahamas 🇧🇸", @"name": @"Bahamas", @"code": @"BS", @"mcc": @"352", @"mnc": @"01"},
    @{@"area": @"Nigeria 🇳🇬", @"name": @"Nigeria", @"code": @"NG", @"mcc": @"621", @"mnc": @"01"},
    @{@"area": @"Kenya 🇰🇪", @"name": @"Kenya", @"code": @"KE", @"mcc": @"639", @"mnc": @"01"},
    @{@"area": @"Tanzania 🇹🇿", @"name": @"Tanzania", @"code": @"TZ", @"mcc": @"640", @"mnc": @"01"},
    @{@"area": @"Uganda 🇺🇬", @"name": @"Uganda", @"code": @"UG", @"mcc": @"641", @"mnc": @"01"},
    @{@"area": @"Ghana 🇬🇭", @"name": @"Ghana", @"code": @"GH", @"mcc": @"620", @"mnc": @"01"},
    @{@"area": @"Côte d'Ivoire 🇨🇮", @"name": @"Côte d'Ivoire", @"code": @"CI", @"mcc": @"612", @"mnc": @"01"},
    @{@"area": @"Senegal 🇸🇳", @"name": @"Senegal", @"code": @"SN", @"mcc": @"604", @"mnc": @"01"},
    @{@"area": @"Morocco 🇲🇦", @"name": @"Morocco", @"code": @"MA", @"mcc": @"604", @"mnc": @"01"},
    @{@"area": @"Tunisia 🇹🇳", @"name": @"Tunisia", @"code": @"TN", @"mcc": @"605", @"mnc": @"01"},
    @{@"area": @"Libya 🇱🇦", @"name": @"Libya", @"code": @"LY", @"mcc": @"606", @"mnc": @"01"},
    @{@"area": @"Ethiopia 🇪🇹", @"name": @"Ethiopia", @"code": @"ET", @"mcc": @"636", @"mnc": @"01"},
    @{@"area": @"Malawi 🇲🇼", @"name": @"Malawi", @"code": @"MW", @"mcc": @"643", @"mnc": @"01"},
    @{@"area": @"Zambia 🇿🇲", @"name": @"Zambia", @"code": @"ZM", @"mcc": @"645", @"mnc": @"01"},
    @{@"area": @"Zimbabwe 🇿🇼", @"name": @"Zimbabwe", @"code": @"ZW", @"mcc": @"644", @"mnc": @"01"},
    @{@"area": @"Botswana 🇧🇼", @"name": @"Botswana", @"code": @"BW", @"mcc": @"652", @"mnc": @"01"},
    @{@"area": @"Namibia 🇳🇦", @"name": @"Namibia", @"code": @"NA", @"mcc": @"648", @"mnc": @"01"},
    @{@"area": @"Mozambique 🇲🇿", @"name": @"Mozambique", @"code": @"MZ", @"mcc": @"646", @"mnc": @"01"},
    @{@"area": @"Angola 🇦🇴", @"name": @"Angola", @"code": @"AO", @"mcc": @"623", @"mnc": @"01"},
    @{@"area": @"Cameroon 🇨🇲", @"name": @"Cameroon", @"code": @"CM", @"mcc": @"624", @"mnc": @"01"},
    @{@"area": @"Democratic Republic of the Congo 🇨🇩", @"name": @"Democratic Republic of the Congo", @"code": @"CD", @"mcc": @"625", @"mnc": @"01"},
    @{@"area": @"Republic of the Congo 🇨🇬", @"name": @"Republic of the Congo", @"code": @"CG", @"mcc": @"626", @"mnc": @"01"},
    @{@"area": @"Gabon 🇬🇦", @"name": @"Gabon", @"code": @"GA", @"mcc": @"627", @"mnc": @"01"},
    @{@"area": @"Equatorial Guinea 🇬🇶", @"name": @"Equatorial Guinea", @"code": @"GQ", @"mcc": @"628", @"mnc": @"01"},
    @{@"area": @"Central African Republic 🇨🇫", @"name": @"Central African Republic", @"code": @"CF", @"mcc": @"629", @"mnc": @"01"},
    @{@"area": @"Chad 🇹🇩", @"name": @"Chad", @"code": @"TD", @"mcc": @"630", @"mnc": @"01"},
    @{@"area": @"Niger 🇳🇪", @"name": @"Niger", @"code": @"NE", @"mcc": @"614", @"mnc": @"01"},
    @{@"area": @"Burkina Faso 🇧🇫", @"name": @"Burkina Faso", @"code": @"BF", @"mcc": @"613", @"mnc": @"01"},
    @{@"area": @"Mali 🇲🇱", @"name": @"Mali", @"code": @"ML", @"mcc": @"615", @"mnc": @"01"},
    @{@"area": @"Mauritania 🇲🇷", @"name": @"Mauritania", @"code": @"MR", @"mcc": @"616", @"mnc": @"01"},
    @{@"area": @"Sierra Leone 🇸🇱", @"name": @"Sierra Leone", @"code": @"SL", @"mcc": @"618", @"mnc": @"01"},
    @{@"area": @"Liberia 🇱🇷", @"name": @"Liberia", @"code": @"LR", @"mcc": @"631", @"mnc": @"01"},
    @{@"area": @"Guinea 🇬🇳", @"name": @"Guinea", @"code": @"GN", @"mcc": @"611", @"mnc": @"01"},
    @{@"area": @"Guinea-Bissau 🇬🇼", @"name": @"Guinea-Bissau", @"code": @"GW", @"mcc": @"619", @"mnc": @"01"},
    @{@"area": @"Gambia 🇬🇲", @"name": @"Gambia", @"code": @"GM", @"mcc": @"607", @"mnc": @"01"},
    @{@"area": @"São Tomé and Príncipe 🇸🇹", @"name": @"São Tomé and Príncipe", @"code": @"ST", @"mcc": @"633", @"mnc": @"01"},
    @{@"area": @"Cape Verde 🇨🇻", @"name": @"Cape Verde", @"code": @"CV", @"mcc": @"608", @"mnc": @"01"},
    @{@"area": @"Seychelles 🇸🇨", @"name": @"Seychelles", @"code": @"SC", @"mcc": @"638", @"mnc": @"01"},
    @{@"area": @"Mauritius 🇲🇺", @"name": @"Mauritius", @"code": @"MU", @"mcc": @"647", @"mnc": @"01"},
    @{@"area": @"Madagascar 🇲🇬", @"name": @"Madagascar", @"code": @"MG", @"mcc": @"637", @"mnc": @"01"},
    @{@"area": @"Comoros 🇰🇲", @"name": @"Comoros", @"code": @"KM", @"mcc": @"635", @"mnc": @"01"},
    @{@"area": @"Reunion 🇷🇪", @"name": @"Reunion", @"code": @"RE", @"mcc": @"649", @"mnc": @"01"},
    @{@"area": @"Mayotte 🇾🇹", @"name": @"Mayotte", @"code": @"YT", @"mcc": @"650", @"mnc": @"01"},
    @{@"area": @"Saint Helena 🇸🇭", @"name": @"Saint Helena", @"code": @"SH", @"mcc": @"651", @"mnc": @"01"},
    @{@"area": @"Burundi 🇧🇮", @"name": @"Burundi", @"code": @"BI", @"mcc": @"653", @"mnc": @"01"},
    @{@"area": @"Rwanda 🇷🇼", @"name": @"Rwanda", @"code": @"RW", @"mcc": @"654", @"mnc": @"01"},
    @{@"area": @"Somalia 🇸🇴", @"name": @"Somalia", @"code": @"SO", @"mcc": @"632", @"mnc": @"01"},
    @{@"area": @"Djibouti 🇩🇯", @"name": @"Djibouti", @"code": @"DJ", @"mcc": @"655", @"mnc": @"01"},
    @{@"area": @"Eritrea 🇪🇷", @"name": @"Eritrea", @"code": @"ER", @"mcc": @"657", @"mnc": @"01"},
    @{@"area": @"New Zealand 🇳🇿", @"name": @"New Zealand", @"code": @"NZ", @"mcc": @"530", @"mnc": @"01"},
    @{@"area": @"Papua New Guinea 🇵🇬", @"name": @"Papua New Guinea", @"code": @"PG", @"mcc": @"547", @"mnc": @"01"},
    @{@"area": @"Fiji 🇫🇯", @"name": @"Fiji", @"code": @"FJ", @"mcc": @"542", @"mnc": @"01"},
    @{@"area": @"Solomon Islands 🇸🇧", @"name": @"Solomon Islands", @"code": @"SB", @"mcc": @"548", @"mnc": @"01"},
    @{@"area": @"Vanuatu 🇻🇺", @"name": @"Vanuatu", @"code": @"VU", @"mcc": @"549", @"mnc": @"01"},
    @{@"area": @"New Caledonia 🇳🇨", @"name": @"New Caledonia", @"code": @"NC", @"mcc": @"540", @"mnc": @"01"},
    @{@"area": @"French Polynesia 🇵🇫", @"name": @"French Polynesia", @"code": @"PF", @"mcc": @"544", @"mnc": @"01"},
    @{@"area": @"Samoa 🇼🇸", @"name": @"Samoa", @"code": @"WS", @"mcc": @"543", @"mnc": @"01"},
    @{@"area": @"Kiribati 🇰🇮", @"name": @"Kiribati", @"code": @"KI", @"mcc": @"553", @"mnc": @"01"},
    @{@"area": @"Tonga 🇹🇴", @"name": @"Tonga", @"code": @"TO", @"mcc": @"555", @"mnc": @"01"},
    @{@"area": @"Tuvalu 🇹🇻", @"name": @"Tuvalu", @"code": @"TV", @"mcc": @"557", @"mnc": @"01"},
    @{@"area": @"Nauru 🇳🇷", @"name": @"Nauru", @"code": @"NR", @"mcc": @"554", @"mnc": @"01"},
    @{@"area": @"Palau 🇵🇼", @"name": @"Palau", @"code": @"PW", @"mcc": @"550", @"mnc": @"01"},
    @{@"area": @"Micronesia 🇫🇲", @"name": @"Micronesia", @"code": @"FM", @"mcc": @"551", @"mnc": @"01"},
    @{@"area": @"Marshall Islands 🇲🇭", @"name": @"Marshall Islands", @"code": @"MH", @"mcc": @"552", @"mnc": @"01"},
    @{@"area": @"Guam 🇬🇺", @"name": @"Guam", @"code": @"GU", @"mcc": @"310", @"mnc": @"280"},
    @{@"area": @"Northern Mariana Islands 🇲🇵", @"name": @"Northern Mariana Islands", @"code": @"MP", @"mcc": @"310", @"mnc": @"310"},
    @{@"area": @"American Samoa 🇦🇸", @"name": @"American Samoa", @"code": @"AS", @"mcc": @"310", @"mnc": @"440"},
    @{@"area": @"Cook Islands 🇨🇰", @"name": @"Cook Islands", @"code": @"CK", @"mcc": @"546", @"mnc": @"01"},
    @{@"area": @"Niue 🇳🇺", @"name": @"Niue", @"code": @"NU", @"mcc": @"545", @"mnc": @"01"},
    @{@"area": @"Tokelau 🇹🇰", @"name": @"Tokelau", @"code": @"TK", @"mcc": @"556", @"mnc": @"01"},
    @{@"area": @"Norfolk Island 🇳🇫", @"name": @"Norfolk Island", @"code": @"NF", @"mcc": @"535", @"mnc": @"01"}
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

