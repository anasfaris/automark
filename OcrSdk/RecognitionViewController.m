#import "RecognitionViewController.h"
#import "AppDelegate.h"
#import "XMLDictionary.h"
#import "ResultViewController.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import "UIImage+Filtering.h"
#import "UIImage+Resizing.h"
#import "UIImage+ResizeNCrop.h"

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
int pause_lock;
int yes_sid;
int yes_mark;
int yes_both;

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
    self.errorImageView.hidden = YES;
    self.studentIDField.hidden = YES;
    self.marksField.hidden = YES;
    self.saveButton.hidden = YES;
    self.errorMessageLabel.hidden = YES;
    
    pause_lock = 1;
    yes_mark = 0;
    yes_sid = 0;
    yes_both = 0;

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
    
    if (!data_error)
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
    self.cameraPicker.previewSize = CGSizeMake(280, 250);
    
    // Present the SACameraPickerViewController's View.
    [self presentViewController:self.cameraPicker animated:YES completion:nil];
    
}

// Optional - Called when the SACameraPickerViewController is Cancelled.
- (void)cameraPickerViewControllerDidCancel:(SACameraPickerViewController *)cameraPicker
{
    UIViewController *prevVC = [self.navigationController.viewControllers objectAtIndex:1];
    [self.navigationController popToViewController:prevVC animated:YES];
}

// Required - The return info from the SACameraPickerViewController.
- (void)cameraPickerViewController:(SACameraPickerViewController *)cameraPicker didTakeImageWithInfo:(NSDictionary *)info
{
    // Fetch the UIImage from the info dictionary
    UIImage *image = [info objectForKey:SACameraPickerViewControllerImageKey];
    
    // FOR TWO LINES
    UIImage *image1 = [image cropInRect:CGRectMake(0, 255, 1064, 150)]; // student number image
    UIImage *image2 = [image cropInRect:CGRectMake(0, 780, 1064, 150)]; // marks image
    
    image = [self mergeImage:image1 withImage:image2];
    UIImage *contrastedImage1 = [image1 contrastAdjustmentWithValue:200.0];
    UIImage *contrastedImage2 = [image2 contrastAdjustmentWithValue:200.0];
    image = [self mergeImage:contrastedImage1 withImage:contrastedImage2];
//    NSData *data = UIImageJPEGRepresentation(contrastedImage, 1.0);
//    NSLog(@"size = %lu", (unsigned long) data.length);
    
    self.errorImageView.image = image;
    [client processImage:contrastedImage1];
//    [NSThread sleepForTimeInterval:0.06];
    [client processImage:contrastedImage2];
    
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
	return NO;
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
    NSLog(@"listItems: %@", listItems);
    
    
    NSLog(@"%lu", (unsigned long)listItems.count);
    
    
    NSLog(@"yes_sid_before: %d", yes_sid);
    NSLog(@"yes_mark_before: %d", yes_mark);
    
    if (listItems.count <= 2) {
        NSString *sID = @"1000000000";
        NSString *guess = @"1000000000";
        if ([listItems[0] length] == 10)
            sID = listItems[0];
        else
            guess = listItems[0];
        yes_sid = 1;
        if (yes_mark)
            self.results.studentID = sID;
        else {
            self.results = [[Result alloc] init];
            self.results.studentID = sID;
        }
        if ([sID  isEqual: @"1000000000"]) {
            data_error = 1;
            self.studentIDField.text = guess;
        }
        
    } else {
        double sum = 0.0;
        
        for (id tempObject in listItems) {
            if ([tempObject length] == 2) {
                sum += [tempObject doubleValue];
            }
            NSLog(@"%@", tempObject);
        }
        NSString *totalString = [NSString stringWithFormat:@"%.1lf", sum];
        yes_mark = 1;
        if (yes_sid) {
            self.results.marks = totalString;
        } else {
            self.results = [[Result alloc] init];
            self.results.marks = totalString;
        }
        self.marksField.text = totalString;
    }
    
    if (data_error) {
        self.studentIDLabel.hidden = NO;
        self.marksLabel.hidden = NO;
        self.errorImageView.hidden = NO;
        self.studentIDField.hidden = NO;
        self.marksField.hidden = NO;
        self.saveButton.hidden = NO;
        self.errorMessageLabel.hidden = NO;
        [self.cameraPicker dismissViewControllerAnimated:YES completion:nil];
    }
    
    NSLog(@"yes_sid_after: %d", yes_sid);
    NSLog(@"yes_mark_after: %d", yes_mark);
    
    if (!data_error && yes_sid == 1 && yes_mark == 1) {
        yes_sid = 0;
        yes_mark = 0;
        self.rStudents = [defaults rm_customObjectForKey:@"result_data"];
        [self.rStudents addObject:self.results];
        [defaults rm_setCustomObject:self.rStudents forKey:@"result_data"];
        [defaults synchronize];
    }
    
    self.showXMLButton.hidden = NO;
}

//- (void)client:(Client *)sender didFinishDownloadData:(NSData *)downloadedData
//{
//	statusIndicator.hidden = YES;
//	
//	NSString* result = [[NSString alloc] initWithData:downloadedData encoding:NSUTF8StringEncoding];
//    
//    //Add some parsing here
//    NSDictionary *xmlDoc = [NSDictionary dictionaryWithXMLString:result];
//    
//    NSString *value = [xmlDoc valueForKeyPath:@"field.value.__text"];
//    NSLog(@"value: %@", value);
//	
//    NSArray *listItems = [value componentsSeparatedByString:@"-"];
//    NSLog(@"listItems: %@", listItems);
//    
//    NSLog(@"%lu", (unsigned long)listItems.count);
//    
//    NSString *sID = @"1000000000";
//    double sum = 0.0;
//    
//    NSString *guess = @"1000000000";
//    
//    for (id tempObject in listItems) {
//        if ([tempObject length] == 2) {
//            sum += [tempObject doubleValue];
//        } else if ([tempObject length] == 10) {
//            sID = tempObject;
//        } else if ([tempObject length] > 2) {
//            guess = tempObject;
//        }
//        NSLog(@"%@", tempObject);
//    }
//    
//	textView.text = result;
//    NSString *totalString = [NSString stringWithFormat:@"%.1lf", sum];
//
//    self.results = [[Result alloc] init];
//    self.results.studentID = sID;
//    self.results.marks = totalString;
//    
//    if ([sID  isEqual: @"1000000000"]) {
//        data_error = 1;
//        
//        self.studentIDLabel.hidden = NO;
//        self.marksLabel.hidden = NO;
//        self.errorImageView.hidden = NO;
//        self.studentIDField.hidden = NO;
//        self.marksField.hidden = NO;
//        self.saveButton.hidden = NO;
//        self.errorMessageLabel.hidden = NO;
//        [self.cameraPicker dismissViewControllerAnimated:YES completion:nil];
//    }
//    
//    self.studentIDField.text = guess;
//    self.marksField.text = totalString;
//
//    
//    if (!data_error) {
//        self.rStudents = [defaults rm_customObjectForKey:@"result_data"];
//        [self.rStudents addObject:self.results];
//        [defaults rm_setCustomObject:self.rStudents forKey:@"result_data"];
//        [defaults synchronize];
//    }
//    
//    self.showXMLButton.hidden = NO;
//}

- (IBAction)showXmlClicked:(id)sender {
    textView.hidden = NO;
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
