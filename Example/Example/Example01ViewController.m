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
            if ([XZLocalization.preferredLanguage isEqualToString:XZLocalization.effectiveLanguage]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                cell.detailTextLabel.text = nil;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.detailTextLabel.text = @"需重启";
            }
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = nil;
        }
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XZAppLanguage newValue = self.languages[indexPath.row];
    if ([newValue isEqualToString:XZLocalization.preferredLanguage]) {
        return;
    }
    
    if (XZLocalization.isInAppLanguagePreferencesEnabled) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"切换语言，重建应用？" preferredStyle:(UIAlertControllerStyleAlert)];
        [alert addAction:[UIAlertAction actionWithTitle:@"继续" style:(UIAlertActionStyleDestructive) handler:^(UIAlertAction * _Nonnull action) {
            XZLocalization.preferredLanguage = newValue;
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"切换语言需重启应用才能生效" preferredStyle:(UIAlertControllerStyleAlert)];
        [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            XZLocalization.preferredLanguage = newValue;
            [self.tableView reloadData];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Events

- (IBAction)InAppPreferenceSwitchValueChanged:(UISwitch *)sender {
    XZLocalization.isInAppLanguagePreferencesEnabled = sender.isOn;
}

@end
