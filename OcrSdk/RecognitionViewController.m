#import "RecognitionViewController.h"
#import "AppDelegate.h"
#import "XMLDictionary.h"
#import "ResultViewController.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import "UIImage+Filtering.h"
#import "UIImage+Resizing.h"

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
    
    // Optionally Set the Image Size
    self.cameraPicker.previewSize = CGSizeMake(320, 30);
    
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
    UIImage *contrastedImage = [image contrastAdjustmentWithValue:200.0];
    NSData *data = UIImageJPEGRepresentation(contrastedImage, 1.0);
    NSLog(@"size = %lu", (unsigned long) data.length);
    
    self.errorImageView.image = contrastedImage;
    [client processImage:contrastedImage];
    
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
    
    NSString *sID = @"1000000000";
    double sum = 0.0;
    
    NSString *guess = @"1000000000";
    
    for (id tempObject in listItems) {
        if ([tempObject length] == 2) {
            sum += [tempObject doubleValue];
        } else if ([tempObject length] == 10) {
            sID = tempObject;
        } else if ([tempObject length] > 2) {
            guess = tempObject;
        }
        NSLog(@"%@", tempObject);
    }
    
	textView.text = result;
    NSString *totalString = [NSString stringWithFormat:@"%.1lf", sum];

    self.results = [[Result alloc] init];
    self.results.studentID = sID;
    self.results.marks = totalString;
    
    if ([sID  isEqual: @"1000000000"]) {
        data_error = 1;
        
        self.studentIDLabel.hidden = NO;
        self.marksLabel.hidden = NO;
        self.errorImageView.hidden = NO;
        self.studentIDField.hidden = NO;
        self.marksField.hidden = NO;
        self.saveButton.hidden = NO;
        self.errorMessageLabel.hidden = NO;
        [self.cameraPicker dismissViewControllerAnimated:YES completion:nil];
    }
    
    self.studentIDField.text = guess;
    self.marksField.text = totalString;

    
    if (!data_error) {
        self.rStudents = [defaults rm_customObjectForKey:@"result_data"];
        [self.rStudents addObject:self.results];
        [defaults rm_setCustomObject:self.rStudents forKey:@"result_data"];
        [defaults synchronize];
    }
    
    self.showXMLButton.hidden = NO;
}

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
