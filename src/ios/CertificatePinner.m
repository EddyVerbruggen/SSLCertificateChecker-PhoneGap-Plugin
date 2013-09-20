#import "CertificatePinner.h"
#import "Constants.h"
#import <CommonCrypto/CommonDigest.h>

// Global variable to hold singleton CertificatePinner;
CertificatePinner* theCertificatePinner = nil;

@implementation CertificatePinner {
    NSString* _connectionState;
}

- (id) init {
    [super init];
    _connectionState = @"NOT VERIFIED";
    if (theCertificatePinner != nil) {
        [NSException raise:@"CertificatePinner is no singleton" format:@"CertificatePinner must be instantiated only once."];
    }
    theCertificatePinner = self;
    return self;
}

- (NSString*) getConnectionState {
    return _connectionState;
}

- (NSString*) verifyAndReturnConnectionState {
  if ([[self getConnectionState] isEqualToString: @"NOT VERIFIED"]) {
    [self verifyConnection];
  }
  return [self getConnectionState];
}


- (void) verifyConnection {
    NSURL* endpointURL = [NSURL URLWithString:ENDPOINT];
    NSLog(@"CertificatePinner checks url %@", endpointURL);
    
    // 1. Connect to the SSL server:
    NSURLRequest *request = [NSURLRequest requestWithURL:endpointURL];
    // delegate:self causes willSendRequestForAuthenticationChallenge method below to be called
    if (![NSURLConnection connectionWithRequest:request delegate:self]) {
        _connectionState = @"NOT CONNECTED";
    }
}

// Delegate method 
- (void) connection: (NSURLConnection*)connection
                willSendRequestForAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge {
    // Get the SecTrustRef from the server
    NSURLProtectionSpace* protSpace = challenge.protectionSpace;
    SecTrustRef trust = protSpace.serverTrust;
    
    // Compare SecTrustGetCertificateAtIndex[0] with predefined fingerprints of trusted certificates.
    NSString* fingerprint = [self getFingerprint: SecTrustGetCertificateAtIndex(trust, 0)];
//    fingerprint = @"########## TESTINGTESTING123 ##########";
    if ([self isFingerprintTrusted: fingerprint]) {
        NSLog(@"found match for fingerprint. Nothing on the hand, so lets continue");
        _connectionState = @"SERVER CERTIFICATE IS TRUSTED";
    } else {
        // If we arrive here, then there is a connection, but it is not secure.
        NSLog(@"no match found for fingerprint, HACKING IN PROGRESS???");
        _connectionState = @"SERVER CERTIFICATE IS NOT TRUSTED";
    }
}

- (NSString*) getFingerprint: (SecCertificateRef) cert {
    NSData* certData = (NSData*) SecCertificateCopyData(cert);
    unsigned char sha1Bytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, certData.length, sha1Bytes);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", sha1Bytes[i]];
    }
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (BOOL) isFingerprintTrusted: (NSString*)fingerprint {
    for (int i = 0; i < NUM_TRUSTED_FINGERPRINTS; i++) {
        if ([fingerprint caseInsensitiveCompare: TRUSTED_FINGERPRINTS[i]] == NSOrderedSame) {
            return TRUE;
        }
    }
    return FALSE;
}

@end
