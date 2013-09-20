#import "SSLCertificateChecker.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <CommonCrypto/CommonDigest.h>

@implementation SSLCertificateChecker {
    NSString* _callbackId;
    id _allowedFingerprint;
    id _allowedFingerprintAlt;
}

-(void)check:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    _callbackId = [arguments pop];

    NSString *serverURL    = [arguments objectAtIndex:0];
    _allowedFingerprint    = [arguments objectAtIndex:1];
    _allowedFingerprintAlt = [arguments objectAtIndex:2];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL]];

    if (![NSURLConnection connectionWithRequest:request delegate:self]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_FAILED"];
        [self writeJavascript:[pluginResult toErrorCallbackString:_callbackId]];
    }
}

// Delegate method, called from connectionWithRequest
- (void) connection: (NSURLConnection*)connection willSendRequestForAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge {
    NSString* fingerprint = [self getFingerprint: SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, 0)];
    if ([self isFingerprintTrusted: fingerprint]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"CONNECTION_SECURE"];
        [self writeJavascript:[pluginResult toSuccessCallbackString:_callbackId]];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_NOT_SECURE"];
        [self writeJavascript:[pluginResult toErrorCallbackString:_callbackId]];
    }
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
    return ((_allowedFingerprint    != [NSNull null] && [fingerprint caseInsensitiveCompare: _allowedFingerprint]    == NSOrderedSame) ||
            (_allowedFingerprintAlt != [NSNull null] && [fingerprint caseInsensitiveCompare: _allowedFingerprintAlt] == NSOrderedSame));
}

@end