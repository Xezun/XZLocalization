//
//  Example02ViewController.m
//  Example
//
//  Created by Xezun on 2023/7/27.
//

#import "Example02ViewController.h"
@import XZLocalization;

@interface Example02ViewController ()

@property (nonatomic, copy) NSArray<NSString *> *strings;

@end

@implementation Example02ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *server = @{
        @"en": @{
            @"name": @"Xiao Ming",
            @"date": @"October 1, 2024",
            @"place": @"Tian'anmen Square"
        },
        @"zh-Hans": @{
            @"name": @"小明",
            @"date": @"2024年10月1日",
            @"place": @"天安门"
        }
    };
    
    NSDictionary *data = server[XZLocalization.preferredLanguage];
    
    self.strings = @[
        XZLocalizedString(@"{0}在{1}去过{2}。"),
        XZLocalizedString(@"{0}在{1}去过{2}。", data[@"name"], data[@"date"], data[@"place"])
    ];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.strings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.strings[indexPath.row];
    return cell;
}


@end
