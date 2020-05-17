#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface SSLCertificateChecker : CDVPlugin

- (void)check:(CDVInvokedUrlCommand*)command;

- (void)checkissuer:(CDVInvokedUrlCommand*)command;

@end