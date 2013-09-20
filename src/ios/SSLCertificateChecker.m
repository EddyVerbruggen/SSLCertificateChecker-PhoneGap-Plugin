#import "SSLCertificateChecker.h"
#import "CertificatePinner.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <CommonCrypto/CommonDigest.h>

@implementation SSLCertificateChecker

-(void)check:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    CDVPluginResult* pluginResult = nil;
    NSString* javaScript = nil;

    @try {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                         messageAsString:[theCertificatePinner verifyAndReturnConnectionState]];
        javaScript = [pluginResult toSuccessCallbackString:callbackId];
    } @catch (NSException* exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION
                                         messageAsString:[exception reason]];
        javaScript = [pluginResult toErrorCallbackString:callbackId];
    }

    [self writeJavascript:javaScript];
}

@end