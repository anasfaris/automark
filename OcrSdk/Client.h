#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HTTPOperation.h"

@protocol ClientDelegate;

@interface Client : NSObject<HTTPOperationAuthenticationDelegate> {

}

@property (strong, nonatomic) NSString* applicationID;
@property (strong, nonatomic) NSString* password;

@property (strong, nonatomic) NSString* installationID;

@property (assign) id<ClientDelegate> delegate;

- (id)initWithApplicationID:(NSString*)applicationID password:(NSString*)password;

- (NSString*)activateNewInstallation:(NSString*)deviceID;
- (void)processImage:(UIImage*)image;

@end

@protocol ClientDelegate <NSObject>

@optional

- (void)clientDidFinishUpload:(Client*)sender;
- (void)clientDidFinishProcessing:(Client*)sender;
- (void)client:(Client*)sender didFinishDownloadData:(NSData*)downloadedData;
- (void)client:(Client*)sender didFailedWithError:(NSError*)error;

@end