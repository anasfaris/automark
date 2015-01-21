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

@class SACameraPickerViewController;

/** This class allows you to review your images and even add metadata to them, before they are returned via the delegate.
 
 You can subclass this class to add your own properties to it. A basic subclass could be as follows:
 
    @interface MYSubclassedReviewViewController : SACameraPickerReviewViewController
    @end
 
    @implementation MYSubclassedReviewViewController
 
    - (void)retakePhoto
    {
        // Could do more here
        [super retakePhoto];
    }
 
    - (void)usePhoto
    {
        // Could do more here (e.g. Add an extra field to the userInfo dictionary)
        // [self.userInfo setObject:@"My Test Item" forKey:@"testItem"];
        [super usePhoto];
    }
 
    @end
 */

@interface SACameraPickerReviewViewController : UIViewController

/** The SACameraPickerViewController that the current *SACameraPickerReviewViewController* is processing images for */
@property (readonly, nonatomic, strong) SACameraPickerViewController *cameraPicker;

/** A dictionary containing keys and values to be returned through the *SACameraPickerViewController* delegate. */
@property (readonly, nonatomic, strong) NSMutableDictionary *userInfo;

/** The UIImageView that the *SACameraPickerReviewViewController* uses to display the image to be processed. */
@property (readonly, nonatomic, strong) UIImageView *imageView;

/** The UIButton the *SACameraPickerReviewViewController* uses to retake the photo. */
@property (readonly, nonatomic, strong) UIButton *retakeButton;

/** The UIButton the *SACameraPickerReviewViewController* uses to finish the image review process. */
@property (readonly, nonatomic, strong) UIButton *useButton;

/** Creates a new instance of an *SACameraPickerReviewViewController* using the specified *SACameraPickerViewController*.
 
 @return An instance of a *SACameraPickerReviewViewController*
 */
- (id)initWithCameraPicker:(SACameraPickerViewController *)cameraPicker;

/** Manually switch back to the 'Take Photo' view.
 
 Allows you to 'Retake' a photo by going back to the *SACameraPickerViewController's* interface.
 */
- (void)retakePhoto;

/** Manually complete the image processing.
 
 Allows you to complete the image processing and return the userInfo dictionary through the *SACameraPickerViewController's* delegate.
 */
- (void)usePhoto;

@end
