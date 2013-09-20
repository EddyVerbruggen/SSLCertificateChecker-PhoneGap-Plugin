#import "SSLCertificateChecker.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <CommonCrypto/CommonDigest.h>

@implementation SSLCertificateChecker {
    NSString* _callbackId;
    NSString* _fingerprint;
}

// TODO these will be passed in via JS call
NSString* TRUSTED_FINGERPRINTS[] = {
    // fingerprint of server certificate of 'mobiel-bankieren.triodos.nl', valid through 2015:
    @"C8 75 04 E1 C2 B7 A5 CD 86 25 8A B1 91 21 3F 6F 77 F1 2C A1",
    // fingerprint of server certificate of 'orange.triodos.nl', valid through 2014:
    @"60 FB 5E 46 C0 AB E9 BF 2F EA D1 B9 BB C6 4B DF 63 0A 44 3E"
};

int NUM_TRUSTED_FINGERPRINTS = sizeof(TRUSTED_FINGERPRINTS) / sizeof(NSString*);

-(void)check:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {

    _callbackId = [arguments pop];
    
    NSString *serverURL = [arguments objectAtIndex:0];
    // TODO fprint array
    _fingerprint = [arguments objectAtIndex:1];


    // create url
    NSURL* endpointURL = [NSURL URLWithString:serverURL];
    NSLog(@"SSLCertificateChecker checks url %@", endpointURL);
    
    // connect
    NSURLRequest *request = [NSURLRequest requestWithURL:endpointURL];

    // delegate:self causes willSendRequestForAuthenticationChallenge method below to be called
    if (![NSURLConnection connectionWithRequest:request delegate:self]) {
        NSLog(@"SSLCertificateChecker connect result: not connected");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"not connected"];
        [self writeJavascript:[pluginResult toErrorCallbackString:_callbackId]];
    }
}

// Delegate method
- (void) connection: (NSURLConnection*)connection willSendRequestForAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge {
    // Get the SecTrustRef from the server
    NSURLProtectionSpace* protSpace = challenge.protectionSpace;
    SecTrustRef trust = protSpace.serverTrust;
    
    // Compare SecTrustGetCertificateAtIndex[0] with predefined fingerprints of trusted certificates.
    NSString* fingerprint = [self getFingerprint: SecTrustGetCertificateAtIndex(trust, 0)];
    //    fingerprint = @"########## TESTINGTESTING123 ##########";
    if ([self isFingerprintTrusted: fingerprint]) {
        NSLog(@"found match for fingerprint. Nothing on the hand, so lets continue");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"secure"];
        [self writeJavascript:[pluginResult toSuccessCallbackString:_callbackId]];
    } else {
        // If we arrive here, then there is a connection, but it is not secure.
        NSLog(@"no match found for fingerprint, HACKING IN PROGRESS???");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"not secure"];
        [self writeJavascript:[pluginResult toErrorCallbackString:_callbackId]];
    }
}

- (NSString*) getFingerprint: (SecCertificateRef) cert {
    NSData* certData = (__bridge NSData*) SecCertificateCopyData(cert); // Note: added __bridge as suggested by XCode
    unsigned char sha1Bytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, certData.length, sha1Bytes);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", sha1Bytes[i]];
    }
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (BOOL) isFingerprintTrusted: (NSString*)fingerprint {
//    for (int i = 0; i < NUM_TRUSTED_FINGERPRINTS; i++) {
        if ([fingerprint caseInsensitiveCompare: _fingerprint] == NSOrderedSame) {
            return TRUE;
        }
//    }
    return FALSE;
}

- (BOOL) isFingerprintTrusted_OLD: (NSString*)fingerprint {
    for (int i = 0; i < NUM_TRUSTED_FINGERPRINTS; i++) {
        if ([fingerprint caseInsensitiveCompare: TRUSTED_FINGERPRINTS[i]] == NSOrderedSame) {
            return TRUE;
        }
    }
    return FALSE;
}

@end