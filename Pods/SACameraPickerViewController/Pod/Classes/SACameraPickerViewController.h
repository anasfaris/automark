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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SACameraPickerReviewViewController.h"

static NSString * const SACameraPickerViewControllerImageKey = @"SACameraPickerImage";

static char const * const SACameraPickerViewControllerMetadata = "SACameraPickerViewControllerMetadata";

typedef NS_ENUM(NSUInteger, SACameraPickerViewControllerMode) {
    /** This is the default mode. Taller in Portrait, Wider in Landscape. */
    SACameraPickerViewControllerModeNormal = 0,
    
    /** This mode takes a Square picture. */
    SACameraPickerViewControllerModeSquare,
    
    /** This mode takes a Square picture, then crops the image to a circle. */
    SACameraPickerViewControllerModeCircle
};

@class SACameraPickerViewController;

@protocol SACameraPickerViewControllerDelegate <NSObject>
@required

/** Called when the *SACameraPickerViewController* finishes processing an image, returning the cameraPicker and an info dictionary.
 
 If you subclass the *SACameraPickerReviewViewController*, the returned info dictionary will additionally contain all values from the userInfo dictionary.
 
 @param cameraPicker The SACameraPickerViewController that processed the image.
 @param info An NSDictionary containing the processed image and any other metadata you specified.
 */
- (void)cameraPickerViewController:(SACameraPickerViewController *)cameraPicker didTakeImageWithInfo:(NSDictionary *)info;

@optional

/** Called when the *SACameraPickerViewController* has taken an image
 
 If you return a valid *SACameraPickerReviewViewController* (or subclass), the captured image will be passed to your controller for 'approval' before being returned to the delegate via the *cameraPickerViewController:didTakeImageWithInfo:* method.
 
 @param cameraPicker The SACameraPickerViewController that is asking for the SACameraPickerReviewViewController.
 @return A SACameraPickerReviewViewController object that handles the images review process.
 @see cameraPickerViewController:didTakeImageWithInfo:
 */
- (SACameraPickerReviewViewController *)cameraPickerViewControllerPrepareReviewViewController:(SACameraPickerViewController *)cameraPicker;

/** Called if the SACameraPickerViewController cancels the image capturing process
 
 @param cameraPicker The SACameraPickerViewController that cancelled the image capturing process
 */
- (void)cameraPickerViewControllerDidCancel:(SACameraPickerViewController *)cameraPicker;

@end

/** This class allows you to take photos from either the Front or Back Camera, whilst allowing you to adjust the design of the UI.
 
 A basic example, using the default UI, could be:
 
    if ([SACameraPickerViewController isCameraPickerViewControllerAvailable]) {
        self.cameraPicker = [[SACameraPickerViewController alloc] initWithCameraPickerViewControllerMode:SACameraPickerViewControllerModeNormal];
        self.cameraPicker.delegate = self;
        [self presentViewController:self.cameraPicker animated:YES completion:nil];
    }
 
 In the above example, we check to see if the current device has a Camera (using the *isCameraPickerViewControllerAvailable* method)
 
 Then we create a new instance of the *SACameraPickerViewController* class using the camera mode: SACameraPickerViewControllerModeNormal.
 
 Next, we set the delegate the picker will use.
 When the image has been taken, the picker will call the delegate method *cameraPickerViewController:didTakeImageWithInfo:*
 
 Finally, we present the picker to the user.
 
 */

@interface SACameraPickerViewController : UIViewController

/** The delegate the *SACameraPickerViewController* should use to return results to. */
@property (nonatomic, assign) id <SACameraPickerViewControllerDelegate> delegate;

/** The UIButton the *SACameraPickerViewController* uses to cancel the image capturing process. */
@property (readonly, nonatomic, strong) UIButton *cancelButton;

/** The UIButton the *SACameraPickerViewController* uses to toggle between flash modes. */
@property (readonly, nonatomic, strong) UIButton *toggleFlashModeButton;

/** The UIButton the *SACameraPickerViewController* uses to capture the image. */
@property (readonly, nonatomic, strong) UIButton *takePhotoButton;

/** The UIButton the *SACameraPickerViewController* uses to toggle between image capture sources. */
@property (readonly, nonatomic, strong) UIButton *toggleCameraSourceButton;

/** The tint color of the Cancel UIButton. */
@property (nonatomic, strong) UIColor *cancelButtonColor;

/** The tint color of the Flash UIButton. */
@property (nonatomic, strong) UIColor *flashButtonColor;

/** The tint color of the Take Photo UIButton. */
@property (nonatomic, strong) UIColor *takePhotoButtonColor;

/** The tint color of the Camera Input Source UIButton. */
@property (nonatomic, strong) UIColor *toggleCameraSourceButtonColor;

/** The size of the camera's live preview layer. */
@property (nonatomic, assign) CGSize previewSize;

/** Whether or not the Cancel button should be enabled. */
@property (nonatomic, assign) BOOL cancelButtonEnabled;

/** Whether or not the *SACameraPickerViewController* should crop the returned image to a circle. */
@property (nonatomic, assign) BOOL cropCircularImages;

/** Whether or not the Flash UIButton should be enabled. */
@property (nonatomic, assign) BOOL flashButtonEnabled;

/** Whether or not the Take Photo button should be enabled. */
@property (nonatomic, assign) BOOL takeButtonEnabled;

/** Whether or not the camera input source UIButton should be enabled. */
@property (nonatomic, assign) BOOL toggleCameraButtonEnabled;

/** Whether or not the front camera is the current input source. */
@property (readonly, nonatomic, assign) BOOL isFrontCameraActive;

/** Checks to see if the current device has a camera and as such, if the *SACameraPickerViewController* can be used.
 
 @return Whether or not the *SACameraPickerViewController* can be used.
 */
+ (BOOL)isCameraPickerViewControllerAvailable;

/** Creates a new instance of an *SACameraPickerViewController* using the specified *SACameraPickerViewControllerMode*.
 
 The default *SACameraPickerViewControllerMode* is *SACameraPickerViewControllerModeNormal*
 
 @return An instance of a *SACameraPickerViewController*
 */
- (id)initWithCameraPickerViewControllerMode:(SACameraPickerViewControllerMode)cameraPickerMode;

/** Creates a new instance of an *SACameraPickerViewController* using the specified *SACameraPickerViewControllerMode*. This method also sets the cameraPicker's *previewSize* and image output size to the specified *frameSize*.
 
 The default *SACameraPickerViewControllerMode* is *SACameraPickerViewControllerModeNormal*
 
 @return An instance of a *SACameraPickerViewController*
 */
- (id)initWithCameraPickerViewControllerMode:(SACameraPickerViewControllerMode)cameraPickerMode frameSize:(CGSize)frameSize;

/** Allows you to manually take a picture
 
 If you would like to take a picture manually, you can do so by calling this method. Instead of the image being passed back through the delegate, it is returned via this method.
 
 @return A UIImage of the captured image.
 */
- (UIImage *)takePicture;

/** Enables all camera UI controls
 
 You can enable all of the UI controls by calling this method. By default, all camera controls are already enabled.
 
 @see disableAllCameraControls
 */
- (void)enableAllCameraControls;

/** Disables all camera UI controls
 
 You can disable all of the UI controls by calling this method. By default, all camera controls are enabled.
 
 @see enableAllCameraControls
 */
- (void)disableAllCameraControls;

/** Manually toggle the input camera source
 
 You can manually toggle the device's camera input source by calling this method.
 
 @return A Boolean of whether or not the camera source input was successfully changed.
 */
- (BOOL)toggleCaptureDeviceInput;

@end
