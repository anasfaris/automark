//
//  ResultViewController.h
//  Automark
//
//  Created by Anas Ahmad Faris on 2015-01-11.
//  Copyright (c) 2015 Anas Ahmad Faris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Result.h"
#import <MessageUI/MessageUI.h>

@interface ResultViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,MFMailComposeViewControllerDelegate>

- (IBAction)unwindToList:(UIStoryboardSegue *)segue;
@property (strong, nonatomic) NSString *getID;
@property (strong, nonatomic) NSMutableArray *students;
@property Result *recognizedResult;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *headerView;

@end
