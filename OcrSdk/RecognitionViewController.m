#import "RecognitionViewController.h"
#import "AppDelegate.h"
#import "XMLDictionary.h"
#import "ResultViewController.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import "UIImage+Filtering.h"
#import "UIImage+Resizing.h"
#import "UIImage+ResizeNCrop.h"
#import "RKDropdownAlert.h"

// To create an application and obtain a password,
// register at http://cloud.ocrsdk.com/Account/Register
// More info on getting your application id and password at
// http://ocrsdk.com/documentation/faq/#faq3

// Name of application you created
static NSString* MyApplicationID = @"Automark";
// Password should be sent to your e-mail after application was created
static NSString* MyPassword = @"pIx+8CK/ce7yqSim3FINWu/h";

@implementation RecognitionViewController

@synthesize textView;
@synthesize statusIndicator;

NSUserDefaults* defaults;
Client *client;
UIImageView *imageView;
int data_error;
int range_error;
int pause_lock;
int yes_sid;
int yes_mark;
int yes_mark2;
int yes_both;
int process_number;
int stop;
double sum;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add tap to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.studentIDField.delegate = self;
    self.marksField.delegate = self;
    
    self.studentIDLabel.hidden = YES;
    self.marksLabel.hidden = YES;
    self.studentIDImageView.hidden = YES;
    self.marksImageView.hidden = YES;
    self.marksImageView2.hidden = YES;
    self.studentIDField.hidden = YES;
    self.marksField.hidden = YES;
    self.saveButton.hidden = YES;
    self.errorMessageLabel.hidden = YES;
    self.detectTextView.hidden = YES;
    
    pause_lock = 1;
    yes_mark = 0;
    yes_sid = 0;
    yes_both = 0;
    range_error = 0;
    process_number = 0;
    sum = 0.0;
    stop = 0;
    
    self.detectedValues = [[NSMutableArray alloc] init];
    
    
    [self performSelector:@selector(takePhoto:) withObject:self afterDelay:1.0];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
	[self setTextView:nil];
	[self setStatusIndicator:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	textView.hidden = YES;
	
	statusIndicator.hidden = YES;

	
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Declare local storage
    defaults = [NSUserDefaults standardUserDefaults];
    self.showXMLButton.hidden = NO;
	
	client = [[Client alloc] initWithApplicationID:MyApplicationID password:MyPassword];
	[client setDelegate:self];
	
	if([[NSUserDefaults standardUserDefaults] stringForKey:@"installationID"] == nil) {
		NSString* deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
		
		NSLog(@"First run: obtaining installation ID..");
		NSString* installationID = [client activateNewInstallation:deviceID];
		NSLog(@"Done. Installation ID is \"%@\"", installationID);
		
		[[NSUserDefaults standardUserDefaults] setValue:installationID forKey:@"installationID"];
	}
	
	NSString* installationID = [[NSUserDefaults standardUserDefaults] stringForKey:@"installationID"];
	
	client.applicationID = [client.applicationID stringByAppendingString:installationID];
    
    if (!data_error && !stop)
        [self performSelector:@selector(takePhoto:) withObject:self afterDelay:0.0];
    data_error = 0;
    
    [super viewDidAppear:animated];
}

-(void)dismissKeyboard {
    [self.studentIDField resignFirstResponder];
    [self.marksField resignFirstResponder];
}

- (void)takePhoto:(id)sender
{
    
    self.cameraPicker = [[SACameraPickerViewController alloc] initWithCameraPickerViewControllerMode:SACameraPickerViewControllerModeNormal];
    
    // Set the SACameraPickerViewController's Delegate
    self.cameraPicker.delegate = self;
    
    // ONE LINE
//    self.cameraPicker.previewSize = CGSizeMake(320, 30);
    
    // TWO LINES
//    self.cameraPicker.previewSize = CGSizeMake(280, 250);
    
    // 10 FIELDS
//    self.cameraPicker.previewSize = CGSizeMake(280, 270);
    self.cameraPicker.previewSize = CGSizeMake(310, 320);
    
    // Present the SACameraPickerViewController's View.
    [self presentViewController:self.cameraPicker animated:YES completion:nil];
    
}

// Optional - Called when the SACameraPickerViewController is Cancelled.
- (void)cameraPickerViewControllerDidCancel:(SACameraPickerViewController *)cameraPicker
{
    stop = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *prevVC = [self.navigationController.viewControllers objectAtIndex:1];
        [self.navigationController popToViewController:prevVC animated:YES];
    });
}

// Required - The return info from the SACameraPickerViewController.
- (void)cameraPickerViewController:(SACameraPickerViewController *)cameraPicker didTakeImageWithInfo:(NSDictionary *)info
{
    // Fetch the UIImage from the info dictionary
    UIImage *originalImage = [info objectForKey:SACameraPickerViewControllerImageKey];
    
    // Crop the images
//    UIImage *croppedImage1 = [originalImage cropInRect:CGRectMake(0, 255, 1064, 150)]; // student number image
//    UIImage *croppedImage2 = [originalImage cropInRect:CGRectMake(0, 780, 1064, 150)]; // marks image
    
    // Crop the images for 10 fields                             (x, y, width, height)
    UIImage *croppedImage1 = [originalImage cropInRect:CGRectMake(0, 190, 1064, 150)]; // student number image
    UIImage *croppedImage2 = [originalImage cropInRect:CGRectMake(0, 620, 1064, 150)]; // marks image
    UIImage *croppedImage3 = [originalImage cropInRect:CGRectMake(0, 950, 1064, 150)]; // marks image 2
    
    // Apply contrast to images
    UIImage *contrastedImage1 = [croppedImage1 contrastAdjustmentWithValue:200.0];
    UIImage *contrastedImage2 = [croppedImage2 contrastAdjustmentWithValue:200.0];
    UIImage *contrastedImage3 = [croppedImage3 contrastAdjustmentWithValue:200.0];
    
    // Get image size
//    NSData *data1 = UIImageJPEGRepresentation(originalImage, 1.0);
//    NSData *data2 = UIImageJPEGRepresentation(croppedImage1, 1.0);
//    NSData *data3 = UIImageJPEGRepresentation(contrastedImage1, 1.0);
//    NSLog(@"Size of original image in bytes = %lu", (unsigned long) data1.length);
//    NSLog(@"Size of cropped image in bytes = %lu", (unsigned long) data2.length);
//    NSLog(@"Size of cropped and contrasted image in bytes = %lu", (unsigned long) data3.length);
    
    self.studentIDImageView.image = contrastedImage1;
    self.marksImageView.image = contrastedImage2;
    self.marksImageView2.image = contrastedImage3;
    self.studentIDImageView.hidden = NO;
    self.marksImageView.hidden = NO;
    self.marksImageView2.hidden = NO;

//        process_number = 1;
//        [client processImage:contrastedImage1];

    [client processImage:contrastedImage1];
    [client processImage:contrastedImage2];
    [client processImage:contrastedImage3];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [client processImage:contrastedImage3];
//    });
    
}

// Function to merge to images together
- (UIImage*)mergeImage:(UIImage*)first withImage:(UIImage*)second
{
    // get size of the first image
    CGImageRef firstImageRef = first.CGImage;
    CGFloat firstWidth = CGImageGetWidth(firstImageRef);
    CGFloat firstHeight = CGImageGetHeight(firstImageRef);
    
    // get size of the second image
    CGImageRef secondImageRef = second.CGImage;
    CGFloat secondWidth = CGImageGetWidth(secondImageRef);
    CGFloat secondHeight = CGImageGetHeight(secondImageRef);
    
    // build merged size
    CGSize mergedSize = CGSizeMake((firstWidth+secondWidth), MAX(firstHeight, secondHeight));
    
    // capture image context ref
    UIGraphicsBeginImageContext(mergedSize);
    
    //Draw images onto the context
    [first drawInRect:CGRectMake(0, 0, firstWidth, firstHeight)];
    //[second drawInRect:CGRectMake(firstWidth, 0, secondWidth, secondHeight)];
    [second drawInRect:CGRectMake(firstWidth-40, 0, secondWidth, secondHeight) blendMode:kCGBlendModeNormal alpha:1.0]; // merge addons
    
    // assign context to new UIImage
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // end context
    UIGraphicsEndImageContext();
    
    return newImage;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
//	return NO;
}

#pragma mark - ClientDelegate implementation

- (void)clientDidFinishUpload:(Client *)sender
{

}

- (void)clientDidFinishProcessing:(Client *)sender
{

}

- (void)client:(Client *)sender didFinishDownloadData:(NSData *)downloadedData
{
    statusIndicator.hidden = YES;
    
    NSString* result = [[NSString alloc] initWithData:downloadedData encoding:NSUTF8StringEncoding];
    
    //Add some parsing here
    NSDictionary *xmlDoc = [NSDictionary dictionaryWithXMLString:result];
    
    NSString *value = [xmlDoc valueForKeyPath:@"field.value.__text"];
    NSLog(@"value: %@", value);
    
    NSArray *listItems = [value componentsSeparatedByString:@"-"];

    if (listItems.count <= 2) {
        NSString *sID = @"1000000000";
        NSString *guess = @"1000000000";
        if ([listItems[0] length] == 10)
            sID = listItems[0];
        else
            guess = listItems[0];
        yes_sid = 1;
        if (yes_mark) {
            self.results.studentID = sID;
            self.studentIDField.text = sID;
        }
        else {
            self.results = [[Result alloc] init];
            self.results.studentID = sID;
            self.studentIDField.text = sID;
        }
        if ([sID  isEqual: @"1000000000"]) {
            data_error = 1;
            self.studentIDField.text = guess;
        }
        
    } else if (listItems.count <= 6) {
        
        for (id tempObject in listItems) {
            if ([tempObject length] == 2) {
                sum += [tempObject doubleValue];
            }
        }
        if (yes_mark == 1)
            yes_mark2 = 1;
        else
            yes_mark = 1;
        if (yes_sid != 1)
            self.results = [[Result alloc] init];

        if (sum > 100) data_error = 2;
    } else {
        data_error = 1;
    }
    
    
    self.marksField.text = [NSString stringWithFormat:@"%.1lf", sum];
    
    NSArray *confidence = [xmlDoc valueForKeyPath:@"field.line.char._confidence"];
    NSLog(@"confidence: %@", confidence);
    
    for (id tempObject in confidence) {
        NSString *str = [NSString stringWithFormat:@"%@", tempObject];
        if ([str isEqualToString:@"0"]) {
            data_error = 1;
            NSLog(@"Error from confidence");
        }
    }
    
    NSMutableArray *suspicious = [xmlDoc valueForKeyPath:@"field.line.char._suspicious"];
    NSLog(@"suspicious: %@", suspicious);
    
    for (id tempObject in suspicious) {
        NSString *str = [NSString stringWithFormat:@"%@", tempObject];
        if ([str isEqualToString:@"true"])
            data_error = 1;
    }
    
    if (data_error == 2) {
        [self showButton:@"There is a problem in the result. The marks detected are more than the total marks. Please revalidate and save!"];
    } else if (data_error) {
        [self showButton:@"We are unsure about this result. Please resubmit and press save!"];
    }
    
    if (!data_error && yes_sid == 1 && yes_mark == 1 && yes_mark2 == 1) {
        NSString *totalString = [NSString stringWithFormat:@"%.1lf", sum];
        self.results.marks = totalString;
        
        yes_sid = 0;
        yes_mark = 0;
        yes_mark2 = 0;
        sum = 0;
        self.rStudents = [defaults rm_customObjectForKey:@"result_data"];
        NSLog(@"%@", self.results.marks);
        [self.rStudents addObject:self.results];
        [defaults rm_setCustomObject:self.rStudents forKey:@"result_data"];
        [defaults synchronize];
    }
    
    [self.detectedValues addObject:value];
    
    self.showXMLButton.hidden = NO;
}

-(void)showButton:(NSString *)message {
    self.studentIDLabel.hidden = NO;
    self.marksLabel.hidden = NO;
//    self.errorMessageLabel.text = message;
    self.studentIDImageView.hidden = NO;
    self.marksImageView.hidden = NO;
    self.marksImageView2.hidden = NO;
    self.studentIDField.hidden = NO;
    self.marksField.hidden = NO;
    self.saveButton.hidden = NO;
//    self.errorMessageLabel.hidden = NO;
    self.navigationController.title = @"Alert!";
    [self.cameraPicker dismissViewControllerAnimated:YES completion:nil];
    
    [RKDropdownAlert title:@"Alert!" message:message backgroundColor:[UIColor redColor] textColor:[UIColor whiteColor] time:3];
}

- (IBAction)showXmlClicked:(id)sender {
//    textView.hidden = NO;
    self.detectTextView.text = [NSString stringWithFormat:@"%@", self.detectedValues];
    self.detectTextView.hidden = NO;
    self.detectedValues = [[NSMutableArray alloc] init];
}

- (IBAction)saveButtonClicked:(id)sender {
    self.results.studentID = self.studentIDField.text;
    self.results.marks = self.marksField.text;
    
    self.rStudents = [defaults rm_customObjectForKey:@"result_data"];
    [self.rStudents addObject:self.results];
    [defaults rm_setCustomObject:self.rStudents forKey:@"result_data"];
    [defaults synchronize];
    
    UIViewController *prevVC = [self.navigationController.viewControllers objectAtIndex:1];
    [self.navigationController popToViewController:prevVC animated:YES];
}

- (void)client:(Client *)sender didFailedWithError:(NSError *)error
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
													message:[error localizedDescription]
												   delegate:nil 
										  cancelButtonTitle:@"Cancel" 
										  otherButtonTitles:nil, nil];
	
	[alert show];
	
	statusIndicator.hidden = YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if (sender != self.saveButton){
        NSLog(@"Other pressed");
        return;
    }

}

@end
