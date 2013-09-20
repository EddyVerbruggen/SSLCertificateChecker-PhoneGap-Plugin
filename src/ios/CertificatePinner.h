#import <UIKit/UIKit.h>

@interface CertificatePinner : NSObject

- (id) init;
- (void) verifyConnection;
- (NSString*) verifyAndReturnConnectionState;
- (NSString*) getConnectionState;

@end

extern CertificatePinner* theCertificatePinner;