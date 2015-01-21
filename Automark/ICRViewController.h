//
//  ICRViewController.h
//  Automark
//
//  Created by Anas Ahmad Faris on 2015-01-11.
//  Copyright (c) 2015 Anas Ahmad Faris. All rights reserved.
//

#import "ViewController.h"
#import "Result.h"
#import "SACameraPickerViewController.h"

@interface ICRViewController : ViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, SACameraPickerViewControllerDelegate>

@property Result *students;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) SACameraPickerViewController *cameraPicker;

@end
