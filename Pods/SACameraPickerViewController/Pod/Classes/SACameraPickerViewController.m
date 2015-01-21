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

#define kSACameraPickerViewControllerIconLayerTag @"SACameraPickerViewControllerIconLayer"

@interface SACameraPickerViewController ()

@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput *outputImage;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UISegmentedControl *flashSegmentedControl;

@property (readwrite, nonatomic, strong) UIButton *cancelButton;
@property (readwrite, nonatomic, strong) UIButton *toggleFlashModeButton;
@property (readwrite, nonatomic, strong) UIButton *takePhotoButton;
@property (readwrite, nonatomic, strong) UIButton *toggleCameraSourceButton;

@property (nonatomic, strong) CAShapeLayer *takePhotoButtonIconLayer;
@property (nonatomic, strong) CAShapeLayer *flashButtonIconLayer;
@property (nonatomic, strong) CAShapeLayer *toggleCameraSourceButtonIconLayer;

@property (nonatomic, assign) CGSize viewFrameSize;

@property (nonatomic, assign) SACameraPickerViewControllerMode cameraPickerMode;

@property (nonatomic, assign) BOOL wasStatusBarHidden;

@end

@implementation SACameraPickerViewController

#pragma mark - Class Methods
+ (BOOL)isCameraPickerViewControllerAvailable
{
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == AVCaptureDevicePositionBack) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Instance Initialization
- (id)init
{
    return [self initWithCameraPickerViewControllerMode:SACameraPickerViewControllerModeNormal];
}

- (id)initWithCameraPickerViewControllerMode:(SACameraPickerViewControllerMode)cameraPickerMode
{
    return [self initWithCameraPickerViewControllerMode:cameraPickerMode frameSize:CGSizeZero];
}

- (id)initWithCameraPickerViewControllerMode:(SACameraPickerViewControllerMode)cameraPickerMode frameSize:(CGSize)frameSize
{
    self = [super init];
    if (self) {
        NSAssert([SACameraPickerViewController isCameraPickerViewControllerAvailable], @"The SACameraPickerViewController controller is not available, please use +[SACameraPickerViewController isCameraSnapshotAvailable] to check.");
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        self.viewFrameSize = frameSize;
        self.cameraPickerMode = cameraPickerMode;
        self.cropCircularImages = YES;
        self.toggleCameraButtonEnabled = YES;
        self.cancelButtonEnabled = YES;
        self.flashButtonEnabled = YES;
        self.previewSize = CGSizeZero;
        self.takeButtonEnabled = YES;
    }
    return self;
}

#pragma mark - Setup
- (void)viewDidLoad
{
    if (!CGSizeEqualToSize(self.viewFrameSize, CGSizeZero)) {
        self.view.frame = CGRectMake(0, 0, self.viewFrameSize.width, self.viewFrameSize.height);
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *deviceConfigurationError = nil;
    if ([self.captureDevice lockForConfiguration:&deviceConfigurationError]) {
        self.captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
        
        //Manually added
        [self.captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        [self.captureDevice setFocusPointOfInterest:CGPointMake(0.521875, 0.750000)];
        
        if ([self.captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            self.captureDevice.flashMode = AVCaptureFlashModeAuto;
        }
        [self.captureDevice unlockForConfiguration];
    } else {
        NSLog(@"Failed to Lock AVCaptureDevice for Configuration: %@", deviceConfigurationError.description);
    }
    
    NSError *deviceInputError;
    self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&deviceInputError];
    _isFrontCameraActive = NO;
    
    if ([self.captureSession canAddInput:self.inputDevice]) {
        [self.captureSession addInput:self.inputDevice];
    } else {
        NSLog(@"Failed to add Input Device: %@", deviceInputError.description);
    }
    
    self.outputImage = [[AVCaptureStillImageOutput alloc] init];
    self.outputImage.outputSettings = @{ AVVideoCodecKey: AVVideoCodecJPEG };
    
    if ([self.captureSession canAddOutput:self.outputImage]) {
        [self.captureSession addOutput:self.outputImage];
    } else {
        NSLog(@"Failed to add Output Device");
    }
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.previewLayer.delegate = self;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.connection.videoOrientation = [self videoCaptureOrientationForInterfaceOrientation:self.interfaceOrientation];
    self.previewSize = self.previewSize;
    
    self.view.layer.masksToBounds = YES;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButtonEnabled = self.cancelButtonEnabled;
    
    self.toggleFlashModeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.toggleFlashModeButton addTarget:self action:@selector(toggleFlashModeSelection) forControlEvents:UIControlEventTouchUpInside];
    self.flashButtonEnabled = self.flashButtonEnabled;
    
    self.takePhotoButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.takePhotoButton addTarget:self action:@selector(takePictureButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.takeButtonEnabled = self.takeButtonEnabled;
    
    self.toggleCameraSourceButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.toggleCameraSourceButton addTarget:self action:@selector(toggleCaptureDeviceInput) forControlEvents:UIControlEventTouchUpInside];
    self.toggleCameraButtonEnabled = self.toggleCameraButtonEnabled;
    
    self.takePhotoButtonColor = [UIColor whiteColor];
    self.flashButtonColor = [UIColor whiteColor];
    self.toggleCameraSourceButtonColor = [UIColor whiteColor];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.view addSubview:self.cancelButton];
    [self.view addSubview:self.toggleFlashModeButton];
    [self.view addSubview:self.takePhotoButton];
    [self.view addSubview:self.toggleCameraSourceButton];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.view.superview.backgroundColor = [UIColor clearColor];
    
    if (![self.view.layer.sublayers containsObject:self.previewLayer]) {
        [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    }
    
    self.wasStatusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.captureSession startRunning];
    
    [self updateOrientation:nil];
    
    [super viewWillAppear:animated];
}

#pragma mark - Tear Down
- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:self.wasStatusBarHidden withAnimation:UIStatusBarAnimationSlide];
    [self.captureSession stopRunning];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if ([self.view.layer.sublayers containsObject:self.previewLayer]) {
        [self.previewLayer removeFromSuperlayer];
    }
    
    [super viewDidDisappear:animated];
}

#pragma mark - UIImage Helpers
- (CGSize)sizeToUse
{
    return (CGSizeEqualToSize(self.previewSize, CGSizeZero)) ? [self defaultPreviewLayerSize] : self.previewSize;
}

- (UIImage *)cropImage:(UIImage *)image toSize:(CGSize)size circular:(BOOL)circular
{
    CGFloat minimumSize = MIN(image.size.width, image.size.height);
    CGRect imageViewFrame = CGRectMake(0, 0, minimumSize, (image.size.width * (size.height / size.width)));
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.image = image;
    imageView.transform = CGAffineTransformMakeRotation(M_PI);
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = (circular) ? (minimumSize / 2) : 0;
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.opaque, [[UIScreen mainScreen] scale]);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return croppedImage;
}

#pragma mark - Camera Functionality
- (UIImage *)takePicture
{
    return [self takePictureUsingDelegate:NO];
}

- (void)takePictureButtonTapped
{
    [self takePictureUsingDelegate:YES];
}

- (UIImage *)takePictureUsingDelegate:(BOOL)useDelegate
{
    __block UIImage *returnImage = nil;
    AVCaptureConnection *captureConnection = [self captureConnectionForMediaType:AVMediaTypeVideo];
    if (captureConnection) {
        [self.outputImage captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer) {
                NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                if (data) {
                    returnImage = [self cropImage:[UIImage imageWithData:data] toSize:[self sizeToUse] circular:(self.cameraPickerMode == SACameraPickerViewControllerModeCircle && self.cropCircularImages) ? YES : NO];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (useDelegate) {
                            if ([self.delegate respondsToSelector:@selector(cameraPickerViewController:didTakeImageWithInfo:)]) {
                                if ([self.delegate respondsToSelector:@selector(cameraPickerViewControllerPrepareReviewViewController:)]) {
                                    objc_setAssociatedObject(self, SACameraPickerViewControllerMetadata, @{ SACameraPickerViewControllerImageKey: returnImage, @"imageSize": NSStringFromCGSize([self sizeToUse]), @"cornerRadius": [NSNumber numberWithInteger:self.previewLayer.cornerRadius] }, OBJC_ASSOCIATION_RETAIN);
                                    SACameraPickerReviewViewController *reviewViewController = [self.delegate cameraPickerViewControllerPrepareReviewViewController:self];
                                    [self addChildViewController:reviewViewController];
                                    [self.view addSubview:reviewViewController.view];
                                } else {
                                    [self.delegate cameraPickerViewController:self didTakeImageWithInfo:@{ SACameraPickerViewControllerImageKey: returnImage }];
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                }
                            } else {
                                [self dismissViewControllerAnimated:YES completion:nil];
                            }
                        }
                    }];
                } else {
                    NSLog(@"Failed to convert imageDataSampleBuffer to NSData (JPEG)");
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            } else {
                NSLog(@"Failed to Capture Still Image: %@", error.description);
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }
    return returnImage;
}

- (BOOL)toggleCaptureDeviceInput
{
    AVCaptureDevicePosition devicePosition = (self.isFrontCameraActive) ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    if ([self setCameraPosition:devicePosition forCaptureSession:self.captureSession]) {
        _isFrontCameraActive = !self.isFrontCameraActive;
        self.flashButtonEnabled = self.flashButtonEnabled;
        if (self.flashSegmentedControl) {
            [self toggleFlashModeSelection];
        }
        return YES;
    }
    return NO;
}

- (void)cancel
{
    if ([self.delegate respondsToSelector:@selector(cameraPickerViewControllerDidCancel:)]) {
        [self.delegate cameraPickerViewControllerDidCancel:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Flash Controls
- (void)toggleFlashModeSelection
{
    [self.toggleFlashModeButton setEnabled:NO];
    if (self.flashSegmentedControl) {
        [UIView animateWithDuration:0.125 animations:^{
            self.flashSegmentedControl.transform = CGAffineTransformMakeTranslation(0, -35);
        } completion:^(BOOL finished) {
            [self.flashSegmentedControl removeFromSuperview];
            self.flashSegmentedControl = nil;
            [self.toggleFlashModeButton setEnabled:self.flashButtonEnabled];
        }];
    } else if (self.flashButtonEnabled && [self.captureDevice isFlashAvailable]) {
        self.flashSegmentedControl = [[UISegmentedControl alloc] initWithFrame:CGRectMake(65, -29, 180, 29)];
        [self.view addSubview:self.flashSegmentedControl];
        [self.flashSegmentedControl addTarget:self action:@selector(flashModeUpdated:) forControlEvents:UIControlEventValueChanged];
        [self.flashSegmentedControl insertSegmentWithTitle:@"Auto" atIndex:0 animated:NO];
        [self.flashSegmentedControl insertSegmentWithTitle:@"On" atIndex:1 animated:NO];
        [self.flashSegmentedControl insertSegmentWithTitle:@"Off" atIndex:2 animated:NO];
        self.flashSegmentedControl.tintColor = self.flashButtonColor;
        if (self.captureDevice.flashMode == AVCaptureFlashModeAuto) {
            self.flashSegmentedControl.selectedSegmentIndex = 0;
        } else if (self.captureDevice.flashMode == AVCaptureFlashModeOn) {
            self.flashSegmentedControl.selectedSegmentIndex = 1;
        } else if (self.captureDevice.flashMode == AVCaptureFlashModeOff) {
            self.flashSegmentedControl.selectedSegmentIndex = 2;
        }
        [UIView animateWithDuration:0.125 animations:^{
            self.flashSegmentedControl.transform = CGAffineTransformMakeTranslation(0, 35);
        } completion:^(BOOL finished) {
            [self.toggleFlashModeButton setEnabled:self.flashButtonEnabled];
        }];
    }
}

- (void)flashModeUpdated:(UISegmentedControl *)flashControl
{
    NSError *deviceConfigurationError = nil;
    if ([self.captureDevice lockForConfiguration:&deviceConfigurationError]) {
        if (flashControl.selectedSegmentIndex == 0 && [self.captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            self.captureDevice.flashMode = AVCaptureFlashModeAuto;
        } else if (flashControl.selectedSegmentIndex == 1 && [self.captureDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
            self.captureDevice.flashMode = AVCaptureFlashModeOn;
        } else if (flashControl.selectedSegmentIndex == 2 && [self.captureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
            self.captureDevice.flashMode = AVCaptureFlashModeOff;
        }
        [self.captureDevice unlockForConfiguration];
    } else {
        NSLog(@"Failed to Lock AVCaptureDevice for Configuration: %@", deviceConfigurationError.description);
    }
    [self toggleFlashModeSelection];
}

#pragma mark - Focus Controls
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [[touches anyObject] locationInView:self.view];
    if (CGRectContainsPoint(self.previewLayer.frame, touchLocation)) {
        CGPoint adjustedTouchLocation = CGPointMake(touchLocation.x - self.previewLayer.frame.origin.x, touchLocation.y - self.previewLayer.frame.origin.y);
        CGPoint touchPercentage = CGPointMake(adjustedTouchLocation.x / self.previewLayer.frame.size.width, adjustedTouchLocation.y / self.previewLayer.frame.size.height);
        
//        NSLog(@"%f, %f", touchPercentage.x, touchPercentage.y);
        
        NSError *lockError = nil;
        if ([self.captureDevice lockForConfiguration:&lockError]) {
            if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [self.captureDevice isFocusPointOfInterestSupported]) {
                [self.captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                [self.captureDevice setFocusPointOfInterest:touchPercentage];
                
                UIView *focusBox = [[UIView alloc] initWithFrame:CGRectMake(touchLocation.x - 20, touchLocation.y - 20, 40, 40)];
                focusBox.layer.borderWidth = 3.0;
                focusBox.layer.borderColor = [UIColor whiteColor].CGColor;
                [self.view addSubview:focusBox];
                
                [UIView animateWithDuration:0.3 delay:0.5 options:0 animations:^{
                    focusBox.alpha = 0;
                } completion:^(BOOL finished) {
                    [focusBox removeFromSuperview];
                }];
            }
            if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [self.captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            [self.captureDevice unlockForConfiguration];
        } else {
            NSLog(@"SACameraPickerViewController Failed to lock captureDevice configuration: %@", lockError);
        }
    }
}

#pragma mark - Configuration
- (void)setPreviewSize:(CGSize)previewSize
{
    _previewSize = (CGSizeEqualToSize(previewSize, CGSizeZero)) ? [self defaultPreviewLayerSize] : previewSize;
    [self.view setNeedsLayout];
}

- (BOOL)setCameraPosition:(AVCaptureDevicePosition)captureDevicePosition forCaptureSession:(AVCaptureSession *)session
{
    AVCaptureDevice *newDevice = [self captureDeviceForCameraPosition:captureDevicePosition];
    
    NSError *deviceInputError;
    AVCaptureDeviceInput *newInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:&deviceInputError];
    
    if (newInputDevice) {
        for (AVCaptureInput *oldInput in session.inputs) {
            [session removeInput:oldInput];
        }
        
        [session addInput:newInputDevice];
        
        return [session.inputs containsObject:newInputDevice];
    } else {
        NSLog(@"'%@' Failed to Change Input Device: %@", NSStringFromSelector(_cmd), deviceInputError.description);
    }
    
    return NO;
}

#pragma mark - Object Positioning And Sizing
- (CGSize)defaultPreviewLayerSize
{
    if (self.cameraPickerMode == SACameraPickerViewControllerModeNormal) {
        return CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 176);
    } else {
        CGFloat size = MIN(self.view.frame.size.width, self.view.frame.size.height);
        return CGSizeMake(size, size);
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Preview Layer Sizing
    CGFloat previewLayerXPosition = (self.view.frame.size.width / 2) - (self.previewSize.width / 2);
    CGFloat previewLayerYPosition = (self.view.frame.size.height / 2) - (self.previewSize.height / 2);
    self.previewLayer.frame = CGRectMake(previewLayerXPosition, previewLayerYPosition, self.previewSize.width, self.previewSize.height);
    if (self.cameraPickerMode == SACameraPickerViewControllerModeCircle) {
        self.previewLayer.cornerRadius = (self.previewSize.width / 2);
    } else {
        self.previewLayer.cornerRadius = 0;
    }
    
    self.cancelButton.frame = CGRectMake(10, self.view.frame.size.height - 70, 60, 60);
    self.toggleFlashModeButton.frame = CGRectMake(0, 0, 40, 40);
    self.takePhotoButton.frame = CGRectMake((self.view.frame.size.width / 2) - 30, self.view.frame.size.height - 70, 60, 60);
    self.toggleCameraSourceButton.frame = CGRectMake(self.view.frame.size.width - 40, 0, 40, 40);
}

#pragma mark - AVCapture Helper Methods
- (AVCaptureConnection *)captureConnectionForMediaType:(NSString *)mediaType
{
    AVCaptureConnection *captureConnection = nil;
    for (AVCaptureConnection *connection in self.outputImage.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqualToString:mediaType]) {
                captureConnection = connection;
                break;
            }
        }
        if (captureConnection) {
            break;
        }
    }
    return captureConnection;
}

- (AVCaptureDevice *)captureDeviceForCameraPosition:(AVCaptureDevicePosition)captureDevicePosition
{
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == captureDevicePosition) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

#pragma mark - Interface Orientation
- (AVCaptureVideoOrientation)videoCaptureOrientationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return AVCaptureVideoOrientationPortraitUpsideDown;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return AVCaptureVideoOrientationLandscapeLeft;
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return AVCaptureVideoOrientationLandscapeRight;
    } else {
        return AVCaptureVideoOrientationPortrait;
    }
}

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

- (void)updateOrientation:(NSNotification *)notification
{
    CGFloat angle = 0;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        angle = M_PI;
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        angle = -M_PI_2;
    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
        angle = M_PI_2;
    }
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
    [UIView animateWithDuration:0.3 animations:^{
        self.toggleFlashModeButton.transform = rotation;
        self.cancelButton.transform = rotation;
        self.takePhotoButton.transform = rotation;
        self.toggleCameraSourceButton.transform = rotation;
    }];
}

#pragma mark - Drawing Code
- (UIColor *)fillColorForIconSublayerOfLayer:(CALayer *)layer
{
    for (CALayer *sublayer in layer.sublayers) {
        if ([sublayer.name isEqualToString:kSACameraPickerViewControllerIconLayerTag]) {
            return [UIColor colorWithCGColor:((CAShapeLayer *)sublayer).fillColor];
        }
    }
    return [UIColor clearColor];
}

- (void)setTakePhotoButtonColor:(UIColor *)takeButtonColor
{
    if (self.takePhotoButtonIconLayer) {
        [self.takePhotoButtonIconLayer removeFromSuperlayer];
    }
    
    self.takePhotoButtonIconLayer = [self takeButtonLayerForColor:takeButtonColor];
    [self.takePhotoButton.layer addSublayer:self.takePhotoButtonIconLayer];
}

- (UIColor *)takePhotoButtonColor
{
    return [self fillColorForIconSublayerOfLayer:self.takePhotoButton.layer];
}

- (CAShapeLayer *)takeButtonLayerForColor:(UIColor *)color
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.name = kSACameraPickerViewControllerIconLayerTag;
    circle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2.5, 2.5, 55, 55)].CGPath;
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = 5;
    
    CAShapeLayer *innerCircle = [CAShapeLayer layer];
    innerCircle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(7, 7, 46, 46)].CGPath;
    innerCircle.fillColor = color.CGColor;
    
    [circle addSublayer:innerCircle];
    
    return circle;
}

- (void)setFlashButtonColor:(UIColor *)flashButtonColor
{
    if (self.flashSegmentedControl) {
        self.flashSegmentedControl.tintColor = flashButtonColor;
    }
    
    if (self.flashButtonIconLayer) {
        [self.flashButtonIconLayer removeFromSuperlayer];
    }
    
    self.flashButtonIconLayer = [self flashButtonLayerForColor:flashButtonColor andFlashMode:self.captureDevice.flashMode];
    [self.toggleFlashModeButton.layer addSublayer:self.flashButtonIconLayer];
}

- (UIColor *)flashButtonColor
{
    return [self fillColorForIconSublayerOfLayer:self.toggleFlashModeButton.layer];
}

- (CAShapeLayer *)flashButtonLayerForColor:(UIColor *)color andFlashMode:(AVCaptureFlashMode)flashMode
{
    UIBezierPath *boltPath = [UIBezierPath bezierPath];
    [boltPath moveToPoint:CGPointMake(20.5, 6.5)];
    [boltPath addLineToPoint:CGPointMake(11.5, 21.5)];
    [boltPath addLineToPoint:CGPointMake(21.5, 21.5)];
    [boltPath addLineToPoint:CGPointMake(19.5, 33.5)];
    [boltPath addLineToPoint:CGPointMake(28.5, 18.5)];
    [boltPath addLineToPoint:CGPointMake(18.5, 18.5)];
    [boltPath addLineToPoint:CGPointMake(20.5, 6.5)];
    [boltPath closePath];
    
    CAShapeLayer *boltLayer = [CAShapeLayer layer];
    boltLayer.name = kSACameraPickerViewControllerIconLayerTag;
    boltLayer.path = boltPath.CGPath;
    boltLayer.fillColor = color.CGColor;
    boltLayer.backgroundColor = [UIColor redColor].CGColor;
    
    return boltLayer;
}

- (void)setToggleCameraSourceButtonColor:(UIColor *)toggleCameraButtonColor
{
    if (self.toggleCameraSourceButtonIconLayer) {
        [self.toggleCameraSourceButtonIconLayer removeFromSuperlayer];
    }
    
    self.toggleCameraSourceButtonIconLayer = [self toggleCameraSourceButtonLayerForColor:toggleCameraButtonColor];
    [self.toggleCameraSourceButton.layer addSublayer:self.toggleCameraSourceButtonIconLayer];
}

- (UIColor *)toggleCameraSourceButtonColor
{
    return [self fillColorForIconSublayerOfLayer:self.toggleCameraSourceButton.layer];
}

- (CAShapeLayer *)toggleCameraSourceButtonLayerForColor:(UIColor *)color
{
    UIBezierPath *cameraOutlinePath = [UIBezierPath bezierPath];
    [cameraOutlinePath moveToPoint:CGPointMake(6.5, 12.74)];
    [cameraOutlinePath addLineToPoint:CGPointMake(12.37, 12.74)];
    [cameraOutlinePath addLineToPoint:CGPointMake(13.54, 10.5)];
    [cameraOutlinePath addLineToPoint:CGPointMake(26.46, 10.5)];
    [cameraOutlinePath addLineToPoint:CGPointMake(27.63, 12.74)];
    [cameraOutlinePath addLineToPoint:CGPointMake(33.5, 12.74)];
    [cameraOutlinePath addLineToPoint:CGPointMake(33.5, 29.5)];
    [cameraOutlinePath addLineToPoint:CGPointMake(6.5, 29.5)];
    [cameraOutlinePath addLineToPoint:CGPointMake(6.5, 12.74)];
    [cameraOutlinePath closePath];
    
    CAShapeLayer *cameraOutlineLayer = [CAShapeLayer layer];
    cameraOutlineLayer.name = kSACameraPickerViewControllerIconLayerTag;
    cameraOutlineLayer.path = cameraOutlinePath.CGPath;
    cameraOutlineLayer.fillColor = [UIColor clearColor].CGColor;
    cameraOutlineLayer.strokeColor = color.CGColor;
    cameraOutlineLayer.lineWidth = 1;
    
    CAShapeLayer *flashLayer = [CAShapeLayer layer];
    flashLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(29, 15, 3, 3)].CGPath;
    flashLayer.fillColor = color.CGColor;

    UIBezierPath *bottomArrowHeadPath = [UIBezierPath bezierPath];
    [bottomArrowHeadPath moveToPoint:CGPointMake(11.5, 24.5)];
    [bottomArrowHeadPath addLineToPoint:CGPointMake(14.5, 20.5)];
    [bottomArrowHeadPath addLineToPoint:CGPointMake(19.5, 21.5)];
    [bottomArrowHeadPath closePath];
    
    CAShapeLayer *bottomArrowHeadLayer = [CAShapeLayer layer];
    bottomArrowHeadLayer.path = bottomArrowHeadPath.CGPath;
    bottomArrowHeadLayer.fillColor = color.CGColor;
    bottomArrowHeadLayer.strokeColor = color.CGColor;
    bottomArrowHeadLayer.lineWidth = 1;
    
    UIBezierPath *bottomArrowCirclePath = [UIBezierPath bezierPath];
    [bottomArrowCirclePath moveToPoint:CGPointMake(14.89, 23.93)];
    [bottomArrowCirclePath addCurveToPoint:CGPointMake(14.23, 21.36) controlPoint1:CGPointMake(14.46, 23.11) controlPoint2:CGPointMake(14.25, 22.23)];
    [bottomArrowCirclePath addLineToPoint:CGPointMake(15.25, 21.69)];
    [bottomArrowCirclePath addCurveToPoint:CGPointMake(15.78, 23.48) controlPoint1:CGPointMake(15.31, 22.3) controlPoint2:CGPointMake(15.48, 22.9)];
    [bottomArrowCirclePath addCurveToPoint:CGPointMake(22.51, 25.64) controlPoint1:CGPointMake(17.04, 25.93) controlPoint2:CGPointMake(20.05, 26.9)];
    [bottomArrowCirclePath addCurveToPoint:CGPointMake(23.98, 24.5) controlPoint1:CGPointMake(23.08, 25.35) controlPoint2:CGPointMake(23.57, 24.96)];
    [bottomArrowCirclePath addLineToPoint:CGPointMake(25, 24.83)];
    [bottomArrowCirclePath addCurveToPoint:CGPointMake(22.96, 26.53) controlPoint1:CGPointMake(24.47, 25.52) controlPoint2:CGPointMake(23.79, 26.11)];
    [bottomArrowCirclePath addCurveToPoint:CGPointMake(14.89, 23.93) controlPoint1:CGPointMake(20.02, 28.04) controlPoint2:CGPointMake(16.4, 26.88)];
    [bottomArrowCirclePath closePath];
    
    CAShapeLayer *bottomArrowCircleLayer = [CAShapeLayer layer];
    bottomArrowCircleLayer.path = bottomArrowCirclePath.CGPath;
    bottomArrowCircleLayer.fillColor = color.CGColor;
    
    UIBezierPath *topArrowHeadPath = [UIBezierPath bezierPath];
    [topArrowHeadPath moveToPoint:CGPointMake(27.5, 16.5)];
    [topArrowHeadPath addLineToPoint:CGPointMake(25.5, 20.5)];
    [topArrowHeadPath addLineToPoint:CGPointMake(20.5, 19.5)];
    [topArrowHeadPath closePath];
    
    CAShapeLayer *topArrowHeadLayer = [CAShapeLayer layer];
    topArrowHeadLayer.path = topArrowHeadPath.CGPath;
    topArrowHeadLayer.fillColor = color.CGColor;
    
    UIBezierPath *topArrowCirclePath = [UIBezierPath bezierPath];
    [topArrowCirclePath moveToPoint:CGPointMake(25.12, 18.45)];
    [topArrowCirclePath addCurveToPoint:CGPointMake(25.59, 21.06) controlPoint1:CGPointMake(25.48, 19.3) controlPoint2:CGPointMake(25.63, 20.19)];
    [topArrowCirclePath addLineToPoint:CGPointMake(24.6, 20.66)];
    [topArrowCirclePath addCurveToPoint:CGPointMake(24.2, 18.84) controlPoint1:CGPointMake(24.58, 20.05) controlPoint2:CGPointMake(24.45, 19.43)];
    [topArrowCirclePath addCurveToPoint:CGPointMake(17.64, 16.19) controlPoint1:CGPointMake(23.12, 16.3) controlPoint2:CGPointMake(20.18, 15.11)];
    [topArrowCirclePath addCurveToPoint:CGPointMake(16.1, 17.22) controlPoint1:CGPointMake(17.05, 16.45) controlPoint2:CGPointMake(16.53, 16.8)];
    [topArrowCirclePath addLineToPoint:CGPointMake(15.1, 16.82)];
    [topArrowCirclePath addCurveToPoint:CGPointMake(17.25, 15.27) controlPoint1:CGPointMake(15.67, 16.17) controlPoint2:CGPointMake(16.4, 15.64)];
    [topArrowCirclePath addCurveToPoint:CGPointMake(25.12, 18.45) controlPoint1:CGPointMake(20.3, 13.98) controlPoint2:CGPointMake(23.82, 15.4)];
    [topArrowCirclePath closePath];
    
    CAShapeLayer *topArrowCircleLayer = [CAShapeLayer layer];
    topArrowCircleLayer.path = topArrowCirclePath.CGPath;
    topArrowCircleLayer.fillColor = color.CGColor;
    
    [cameraOutlineLayer addSublayer:flashLayer];
    [cameraOutlineLayer addSublayer:bottomArrowHeadLayer];
    [cameraOutlineLayer addSublayer:bottomArrowCircleLayer];
    [cameraOutlineLayer addSublayer:topArrowHeadLayer];
    [cameraOutlineLayer addSublayer:topArrowCircleLayer];
    
    return cameraOutlineLayer;
}

#pragma mark - Enable / Disable Functionality
- (void)setToggleCameraButtonEnabled:(BOOL)toggleCameraButtonEnabled
{
    _toggleCameraButtonEnabled = toggleCameraButtonEnabled;
    self.toggleCameraSourceButton.hidden = !toggleCameraButtonEnabled;
}

- (void)setCancelButtonEnabled:(BOOL)cancelButtonEnabled
{
    _cancelButtonEnabled = cancelButtonEnabled;
    self.cancelButton.hidden = !cancelButtonEnabled;
}

- (void)setFlashButtonEnabled:(BOOL)flashButtonEnabled
{
    _flashButtonEnabled = flashButtonEnabled;
    self.toggleFlashModeButton.hidden = !(flashButtonEnabled && [self.captureDevice isFlashAvailable] && self.isFrontCameraActive == NO);
}

- (void)setTakeButtonEnabled:(BOOL)takeButtonEnabled
{
    _takeButtonEnabled = takeButtonEnabled;
    self.takePhotoButton.hidden = !takeButtonEnabled;
}

- (void)enableAllCameraControls
{
    self.toggleCameraButtonEnabled = YES;
    self.cancelButtonEnabled = YES;
    self.flashButtonEnabled = YES;
    self.takeButtonEnabled = YES;
}

- (void)disableAllCameraControls
{
    self.toggleCameraButtonEnabled = NO;
    self.cancelButtonEnabled = NO;
    self.flashButtonEnabled = NO;
    self.takeButtonEnabled = NO;
}

#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Modal Presentation Style
- (void)setModalPresentationStyle:(UIModalPresentationStyle)modalPresentationStyle
{
    super.modalPresentationStyle = UIModalPresentationNone;
}

@end
