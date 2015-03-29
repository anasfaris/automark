//
//  ViewController.m
//  Automark
//
//  Created by Anas Ahmad Faris on 2015-01-11.
//  Copyright (c) 2015 Anas Ahmad Faris. All rights reserved.
//

#import "ViewController.h"
#import "ResultViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //Add tap to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.examTextField.delegate = self;
    
    // Bring button on top of table view
    [self.view bringSubviewToFront:self.examTextField];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
}

-(void)dismissKeyboard {
    [self.examTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Next button was pressed
    //Push some viewcontroller here
    [self.examTextField resignFirstResponder];
    [self performSegueWithIdentifier:@"GoToResultSegue" sender:self];
    
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    ResultViewController *resultViewController = segue.destinationViewController;
    resultViewController.getID = self.examTextField.text;
    
}

@end
