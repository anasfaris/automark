#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ActivationInfo : NSObject<NSXMLParserDelegate> {
	BOOL isReadingAuthToken;
}

@property (strong, nonatomic) NSString* installationID;

- (id)initWithData:(NSData*)data;

@end
