#import <UIKit/UIKit.h>
#import "Client.h"
#import "Result.h"
#import "SACameraPickerViewController.h"

@interface RecognitionViewController : UIViewController<ClientDelegate, SACameraPickerViewControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *statusIndicator;
@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;

@property (strong, nonatomic) IBOutlet UILabel *studentIDLabel;
@property (strong, nonatomic) IBOutlet UILabel *marksLabel;
@property (strong, nonatomic) IBOutlet UITextField *studentIDField;
@property (strong, nonatomic) IBOutlet UITextField *marksField;

@property (strong, nonatomic) IBOutlet UIImageView *studentIDImageView;
@property (strong, nonatomic) IBOutlet UIImageView *marksImageView;
@property (strong, nonatomic) IBOutlet UIImageView *marksImageView2;

@property (strong, nonatomic) IBOutlet UITextView *detectTextView;

@property Result *results;
@property Result *tests;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *showXMLButton;

@property (strong, nonatomic) NSMutableArray *rStudents;
@property (strong, nonatomic) NSMutableArray *detectedValues;

@property (nonatomic, strong) SACameraPickerViewController *cameraPicker;

@end
