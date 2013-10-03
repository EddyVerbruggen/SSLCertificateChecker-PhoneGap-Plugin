#import "SSLCertificateChecker.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <CommonCrypto/CommonDigest.h>

@interface SSLCertificateChecker ()

@property (strong, nonatomic) NSString *_allowedFingerprint;
@property (strong, nonatomic) NSString *_allowedFingerprintAlt;
@property (strong, nonatomic) NSString *_callbackId;

@end

@implementation SSLCertificateChecker

//-(void)check:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
- (void)check:(CDVInvokedUrlCommand*)command {
    self._callbackId = [command.callbackId];

    NSString *serverURL    = [command.arguments objectAtIndex:0];
    self._allowedFingerprint    = [command.arguments objectAtIndex:1];
    self._allowedFingerprintAlt = [command.arguments objectAtIndex:2];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL]];

    if (![NSURLConnection connectionWithRequest:request delegate:self]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_FAILED"];
        [self writeJavascript:[pluginResult toErrorCallbackString:self._callbackId]];
    }
}

// Delegate method, called from connectionWithRequest
- (void) connection: (NSURLConnection*)connection willSendRequestForAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge {
    NSString* fingerprint = [self getFingerprint: SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, 0)];
    if ([self isFingerprintTrusted: fingerprint]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"CONNECTION_SECURE"];
        [self writeJavascript:[pluginResult toSuccessCallbackString:self._callbackId]];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_NOT_SECURE"];
        [self writeJavascript:[pluginResult toErrorCallbackString:self._callbackId]];
    }
}

// Delegate method, called from connectionWithRequest
- (void) connection: (NSURLConnection*)connection didFailWithError: (NSError*)error {
    NSString *resultCode = @"CONNECTION_FAILED. Details:";
    NSString *errStr = [NSString stringWithFormat:@"%@ %@", resultCode, [error localizedDescription]];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:errStr];
    [self writeJavascript:[pluginResult toErrorCallbackString:self._callbackId]];
}

- (NSString*) getFingerprint: (SecCertificateRef) cert {
    NSData* certData = (__bridge NSData*) SecCertificateCopyData(cert);
    unsigned char sha1Bytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, certData.length, sha1Bytes);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", sha1Bytes[i]];
    }
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (BOOL) isFingerprintTrusted: (NSString*)fingerprint {
    return ((self._allowedFingerprint    != [NSNull null] && [fingerprint caseInsensitiveCompare: self._allowedFingerprint]    == NSOrderedSame) ||
            (self._allowedFingerprintAlt != [NSNull null] && [fingerprint caseInsensitiveCompare: self._allowedFingerprintAlt] == NSOrderedSame));
}

@end