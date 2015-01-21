// The MIT License (MIT)
//
// Copyright (c) 2014 SynAppsDev.
// support@synappsdev.co.uk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <objc/runtime.h>
#import "SACameraPickerViewController.h"
#import "SACameraPickerReviewViewController.h"

@interface SACameraPickerReviewViewController ()

@property (nonatomic, assign) BOOL wasStatusBarHidden;

@property (readwrite, nonatomic, strong) SACameraPickerViewController *cameraPicker;
@property (readwrite, nonatomic, strong) NSMutableDictionary *userInfo;
@property (readwrite, nonatomic, strong) UIImageView *imageView;
@property (readwrite, nonatomic, strong) UIButton *retakeButton;
@property (readwrite, nonatomic, strong) UIButton *useButton;

@end

@implementation SACameraPickerReviewViewController

#pragma mark - Initialization
- (id)initWithCameraPicker:(SACameraPickerViewController *)cameraPicker
{
    self = [super init];
    if (self) {
        self.cameraPicker = cameraPicker;
        
        NSDictionary *metadata = objc_getAssociatedObject(cameraPicker, SACameraPickerViewControllerMetadata);
        
        CGSize imageSize = CGSizeFromString([metadata objectForKey:@"imageSize"]);
        CGRect imageViewFrame = self.imageView.frame;
        imageViewFrame.origin.x = (self.cameraPicker.view.frame.size.width / 2) - (imageSize.width / 2);
        imageViewFrame.origin.y = (self.cameraPicker.view.frame.size.height / 2) - (imageSize.height / 2);
        imageViewFrame.size = imageSize;
        self.imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.image = [metadata objectForKey:SACameraPickerViewControllerImageKey];
        self.imageView.clipsToBounds = YES;
        self.imageView.layer.cornerRadius = [[metadata objectForKey:@"cornerRadius"] intValue];
        
        self.retakeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, self.cameraPicker.view.frame.size.height - 70, 60, 60)];
        [self.retakeButton setTitle:@"Retake" forState:UIControlStateNormal];
        [self.retakeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.retakeButton addTarget:self action:@selector(retakePhoto) forControlEvents:UIControlEventTouchUpInside];
        
        self.useButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraPicker.view.frame.size.width - 70, self.cameraPicker.view.frame.size.height - 70, 60, 60)];
        [self.useButton setTitle:@"Use" forState:UIControlStateNormal];
        [self.useButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.useButton addTarget:self action:@selector(usePhoto) forControlEvents:UIControlEventTouchUpInside];
        
        self.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[metadata objectForKey:SACameraPickerViewControllerImageKey], SACameraPickerViewControllerImageKey, nil];
    }
    return self;
}

#pragma mark - Setup
- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor blackColor];
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size = self.cameraPicker.view.frame.size;
    self.view.frame = viewFrame;
    
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.retakeButton];
    [self.view addSubview:self.useButton];
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.wasStatusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:self.wasStatusBarHidden withAnimation:UIStatusBarAnimationSlide];
    
    [super viewDidDisappear:animated];
}

#pragma mark - Review Features
- (void)retakePhoto
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)usePhoto
{
    if ([self.parentViewController isKindOfClass:[SACameraPickerViewController class]]) {
        SACameraPickerViewController *cameraPickerViewController = (SACameraPickerViewController *)self.parentViewController;
        if ([cameraPickerViewController.delegate respondsToSelector:@selector(cameraPickerViewController:didTakeImageWithInfo:)]) {
            [cameraPickerViewController dismissViewControllerAnimated:YES completion:^{
                [self.view removeFromSuperview];
                [self removeFromParentViewController];
            }];
            [cameraPickerViewController.delegate cameraPickerViewController:cameraPickerViewController didTakeImageWithInfo:self.userInfo];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Interface Orientation
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
