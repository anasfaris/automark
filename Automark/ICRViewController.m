//
//  ICRViewController.m
//  Automark
//
//  Created by Anas Ahmad Faris on 2015-01-11.
//  Copyright (c) 2015 Anas Ahmad Faris. All rights reserved.
//

#import "ICRViewController.h"
#import "AppDelegate.h"
#import "UIImage+Filtering.h"
#import "UIImage+Resizing.h"
#import "RecognitionViewController.h"

@interface ICRViewController ()

@end

@implementation ICRViewController
//UIButton *btn_Overlay;
//UIView *overlayView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    self.imageView.image = [(AppDelegate*)[[UIApplication sharedApplication] delegate] imageToProcess];
    
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(takePhoto:) withObject:self afterDelay:0.0];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)takePhoto:(id)sender
{

    self.cameraPicker = [[SACameraPickerViewController alloc] initWithCameraPickerViewControllerMode:SACameraPickerViewControllerModeNormal];
    
    // Set the SACameraPickerViewController's Delegate
    self.cameraPicker.delegate = self;
    
    // Optionally Set the Image Size
    self.cameraPicker.previewSize = CGSizeMake(320, 30);
    
    // Present the SACameraPickerViewController's View.
     [self presentViewController:self.cameraPicker animated:YES completion:nil];
    
}

// Optional - Called when the SACameraPickerViewController is Cancelled.
- (void)cameraPickerViewControllerDidCancel:(SACameraPickerViewController *)cameraPicker
{
    [self performSelector:@selector(goToMain:) withObject:self afterDelay:0.5];
}

- (void)goToMain:(id)sender
{
    UIViewController *prevVC = [self.navigationController.viewControllers objectAtIndex:1];
    [self.navigationController popToViewController:prevVC animated:YES];
}

// Required - The return info from the SACameraPickerViewController.
- (void)cameraPickerViewController:(SACameraPickerViewController *)cameraPicker didTakeImageWithInfo:(NSDictionary *)info
{
    // Fetch the UIImage from the info dictionary
    UIImage *image = [info objectForKey:SACameraPickerViewControllerImageKey];
    
    UIImage *contrastedImage = [image contrastAdjustmentWithValue:200.0];
    
    // Set the example UIImageView's image to the output UIImage.
    self.imageView.image = contrastedImage;
    
    NSData *data = UIImageJPEGRepresentation(contrastedImage, 1.0);
    NSLog(@"size = %lu", (unsigned long) data.length);
    
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] setImageToProcess:contrastedImage];

    
    [self performSegueWithIdentifier:@"rSegue" sender:self];
}

//- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
//    UIImage *contrastedImage = [image contrastAdjustmentWithValue:200.0];
//    
//    NSLog(@"h: %f",image.size.height);
//    NSLog(@"w: %f",image.size.width);
//    
//    UIImage *cropped = [self squareImageWithImage:contrastedImage scaledToSize:(CGSize){320,30}];
//    
//    NSLog(@"h: %f",cropped.size.height);
//    NSLog(@"w: %f",cropped.size.width);
//    
//    [picker dismissModalViewControllerAnimated:YES];
//    
//    self.imageView.image = cropped;
//    [(AppDelegate*)[[UIApplication sharedApplication] delegate] setImageToProcess:cropped];
//}

- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.height);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.height / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    NSLog(@"%f", ratio);
    NSLog(@"%f", delta);
    
    //make the final clipping rect based on the calculated values
//    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
//                                 (ratio * image.size.width) + delta,
//                                 (ratio * image.size.height) + delta);
        CGRect clipRect = CGRectMake(0, 0,
                                     (ratio * image.size.width) + 0,
                                     (ratio * image.size.height) + delta);

    
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)randomizeImage:(id)sender {
    // Randomize an image
    int randomNum = arc4random() % 4 + 1;
    
    NSString *randomImgName = [NSString stringWithFormat:@"test%d", randomNum];
    
    UIImage *randomImage = [UIImage imageNamed:randomImgName];
    self.imageView.image = randomImage;
    
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] setImageToProcess:randomImage];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (sender != self.saveButton){
        NSLog(@"Other pressed");
        return;
    }
    self.students = [[Result alloc] init];
    self.students.studentID = @"0990001111";
    self.students.marks = @"7.0";
    
    NSLog(@"Save pressed");
}


@end
