# SACameraPickerViewController

[![CI Status](http://img.shields.io/travis/Toby Herbert/SACameraPickerViewController.svg?style=flat)](https://travis-ci.org/Toby Herbert/SACameraPickerViewController)
[![Version](https://img.shields.io/cocoapods/v/SACameraPickerViewController.svg?style=flat)](http://cocoadocs.org/docsets/SACameraPickerViewController)
[![License](https://img.shields.io/cocoapods/l/SACameraPickerViewController.svg?style=flat)](http://cocoadocs.org/docsets/SACameraPickerViewController)
[![Platform](https://img.shields.io/cocoapods/p/SACameraPickerViewController.svg?style=flat)](http://cocoadocs.org/docsets/SACameraPickerViewController)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

SACameraPickerViewController requires the Frameworks *UIKit* and *AVFoundation*.

## Installation

SACameraPickerViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "SACameraPickerViewController"

## Example

*SACameraPickerViewController* allows you to take photos from either the Front or Back Camera, whilst allowing you to adjust the design of the UI.

A basic example, using the default UI, could be:

```
if ([SACameraPickerViewController isCameraPickerViewControllerAvailable]) {
    self.cameraPicker = [[SACameraPickerViewController alloc] initWithCameraPickerViewControllerMode:SACameraPickerViewControllerModeNormal];
    self.cameraPicker.delegate = self;
    [self presentViewController:self.cameraPicker animated:YES completion:nil];
}
```

In the above example, we check to see if the current device has a Camera (using the isCameraPickerViewControllerAvailable method)

Then we create a new instance of the SACameraPickerViewController class using the camera mode: SACameraPickerViewControllerModeNormal.

Next, we set the delegate the picker will use. When the image has been taken, the picker will call the delegate method cameraPickerViewController:didTakeImageWithInfo:

Finally, we present the picker to the user.

## Author

Toby Herbert, tobyherbert@synappsdev.co.uk

## License

SACameraPickerViewController is available under the MIT license. See the LICENSE file for more info.

