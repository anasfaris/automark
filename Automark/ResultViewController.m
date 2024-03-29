//
//  ResultViewController.m
//  Automark
//
//  Created by Anas Ahmad Faris on 2015-01-11.
//  Copyright (c) 2015 Anas Ahmad Faris. All rights reserved.
//

#import "ResultViewController.h"
#import "ICRViewController.h"
#import "NSUserDefaults+RMSaveCustomObject.h"
#import "CHCSVParser.h"
#import "RKDropdownAlert.h"

@interface ResultViewController ()

@end

@implementation ResultViewController
NSUserDefaults* defaults;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = self.getID;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName: [UIColor blackColor],
                                                            NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:22.0f],
                                                            }];
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    defaults = [NSUserDefaults standardUserDefaults];
    self.students = [defaults rm_customObjectForKey:@"result_data"];
    
    if (!self.students) {
        self.students = [[NSMutableArray alloc] init];
        
        [self loadInitialData];
        [defaults rm_setCustomObject:self.students forKey:@"result_data"];
        [defaults synchronize];
    }
    
    if (self.recognizedResult) {
        [self.students addObject:self.recognizedResult];
        [defaults rm_setCustomObject:self.students forKey:@"result_data"];
        [defaults synchronize];
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table View Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.students.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Retrieve cell
    NSString *cellIdentifier = @"StudentCell";
    UITableViewCell *studentCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Get program item that it's asking for
    Result *result = self.students[indexPath.row];
    
    UILabel *studentIDLabel = (UILabel*)[studentCell viewWithTag:1];
    UILabel *marksLabel = (UILabel*)[studentCell viewWithTag:2];
    
    studentIDLabel.text = result.studentID;
    marksLabel.text = result.marks;
    
    return studentCell;
}

- (void)loadInitialData {
    Result *result1 = [[Result alloc] init];
    result1.studentID = @"0997557264";
    result1.marks = @"13.0";
    [self.students addObject:result1];
    
    Result *result2 = [[Result alloc] init];
    result2.studentID = @"0997557263";
    result2.marks = @"15.0";
    [self.students addObject:result2];
    
    Result *result3 = [[Result alloc] init];
    result3.studentID = @"0997557261";
    result3.marks = @"9.0";
    [self.students addObject:result3];
}

- (IBAction)submitButton:(id)sender {
    //creating a csv CHCSVWriter
    NSOutputStream *output = [NSOutputStream outputStreamToMemory];
    CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:output encoding:NSUTF8StringEncoding delimiter:','];
    
    //wrting header name for csv file
    [writer writeField:@"Student ID"];
    [writer writeField:@"Marks"];
    [writer finishLine];
    
    for (int i = 0; i < self.students.count; i++) {
        Result *result = self.students[i];
        
        [writer writeField:result.studentID];
        [writer writeField:result.marks];
        [writer finishLine];
    }
    
    [writer closeStream];
    
    NSData *buffer = [output propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    NSString *stringSend = [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
//    NSLog(@"string = %@",stringSend);
    
    if ( [MFMailComposeViewController canSendMail] ) {
        
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        
        NSData *myData = [stringSend dataUsingEncoding:NSUTF8StringEncoding];
//        NSLog(@"myData csv:%@",myData);
//        NSLog(@"string csv:%@",stringSend);
        
        // Fill out the email body text
        NSString *emailBody = @"Result";
        [mailComposer setMessageBody:emailBody isHTML:NO];
        [mailComposer setSubject:@"Result Submission"];
        [mailComposer setToRecipients:@[@"sifooparadox@gmail.com",@"anas.ahmadfaris@mail.utoronto.ca"]];
        
        //attaching the data and naming it to
        [mailComposer addAttachmentData:myData  mimeType:@"text/cvs" fileName:@"Result.csv"];
        
        [self presentViewController:mailComposer animated:YES completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // Dismiss the compose controller
    [self dismissViewControllerAnimated:YES completion:nil];

    [RKDropdownAlert title:@"Marks submitted!" backgroundColor:[UIColor colorWithRed:24.0/255 green:125.0/255 blue:198.0/255 alpha:1.0] textColor:[UIColor whiteColor] time:2];
}

- (IBAction)clearClicked:(id)sender {
    self.students = [[NSMutableArray alloc] init];
    [defaults rm_setCustomObject:self.students forKey:@"result_data"];
    [defaults synchronize];
    [self.tableView reloadData];
    
    [RKDropdownAlert title:@"List cleared" backgroundColor:[UIColor colorWithRed:24.0/255 green:125.0/255 blue:198.0/255 alpha:1.0] textColor:[UIColor whiteColor] time:2];
    
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue {
    ICRViewController *source = [segue sourceViewController];
    Result *result = source.students;
    if (result != nil) {
        [self.students addObject:result];
        [self.tableView reloadData];
    }
    
}

@end
