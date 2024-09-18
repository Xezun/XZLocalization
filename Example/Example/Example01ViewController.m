//
//  Example01ViewController.m
//  Example
//
//  Created by 徐臻 on 2024/9/16.
//

#import "Example01ViewController.h"
@import XZLocalization;

@interface Example01ViewController ()

@property (nonatomic, copy) NSArray<XZAppLanguage> *languages;
@property (weak, nonatomic) IBOutlet UISwitch *inAppPreferenceSwitch;

@end

@implementation Example01ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.languages = @[XZAppLanguageChinese, XZAppLanguageEnglish];
    self.inAppPreferenceSwitch.on = XZLocalization.isInAppLanguagePreferencesEnabled;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        if ([self.languages[indexPath.row] isEqual:XZLocalization.preferredLanguage]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XZAppLanguage newValue = self.languages[indexPath.row];
    XZLocalization.preferredLanguage = newValue;
}

#pragma mark - Events

- (IBAction)InAppPreferenceSwitchValueChanged:(UISwitch *)sender {
    XZLocalization.isInAppLanguagePreferencesEnabled = sender.isOn;
}

@end
