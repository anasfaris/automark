#import <UIKit/UIKit.h>
#import "Client.h"
#import "Result.h"

@interface RecognitionViewController : UIViewController<ClientDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *statusIndicator;

@property (strong, nonatomic) IBOutlet UILabel *studentID;
@property (strong, nonatomic) IBOutlet UILabel *totalMarks;

@property Result *results;
@property Result *tests;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *showXMLButton;

@property (strong, nonatomic) NSMutableArray *rStudents;

@end
