#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface SSLCertificateChecker : CDVPlugin

- (void)check:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end