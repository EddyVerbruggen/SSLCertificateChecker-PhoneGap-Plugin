#import "SSLCertificateChecker.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <CommonCrypto/CommonDigest.h>
#import <openssl/x509.h>

@interface CustomURLConnectionDelegate : NSObject <NSURLConnectionDelegate>;

@property (strong, nonatomic) CDVPlugin *_plugin;
@property (strong, nonatomic) NSString *_callbackId;
@property (nonatomic, assign) BOOL _checkInCertChain;
@property (nonatomic, assign) BOOL _checkIssuer;
@property (strong, nonatomic) NSArray *_allowedFingerprints;
@property (nonatomic, assign) BOOL sentResponse;

- (id)initWithPlugin:(CDVPlugin*)plugin callbackId:(NSString*)callbackId checkInCertChain:(BOOL)checkInCertChain allowedFingerprints:(NSArray*)allowedFingerprints;

@end

@implementation CustomURLConnectionDelegate

- (id)initWithPlugin:(CDVPlugin*)plugin callbackId:(NSString*)callbackId checkInCertChain:(BOOL)checkInCertChain allowedFingerprints:(NSArray*)allowedFingerprints checkIssuer:(BOOL)checkIssuer
{
    self.sentResponse = FALSE;
    self._plugin = plugin;
    self._callbackId = callbackId;
    self._checkInCertChain = FALSE; // if for some reason this code is called we will still not check the chain because it's insecure
    self._checkIssuer = checkIssuer;
    self._allowedFingerprints = allowedFingerprints;
    return self;
}

// Delegate method, called from connectionWithRequest
- (void) connection: (NSURLConnection*)connection willSendRequestForAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge {
    SecTrustRef trustRef = [[challenge protectionSpace] serverTrust];
    SecTrustEvaluate(trustRef, NULL);
    
    //    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    [connection cancel];
    
    CFIndex count = 1;
    if (self._checkInCertChain) {
        count = SecTrustGetCertificateCount(trustRef);
    }
    
    for (CFIndex i = 0; i < count; i++)
    {
        SecCertificateRef certRef = SecTrustGetCertificateAtIndex(trustRef, i);
        NSString *fingerprint = nil;
        
        if (self._checkIssuer) {
            fingerprint = [self getIssuer:certRef];
        } else {
            fingerprint = [self getFingerprint:certRef];
        }

        if ([self isFingerprintTrusted: fingerprint]) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"CONNECTION_SECURE"];
            [self._plugin.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
            self.sentResponse = TRUE;
            break;
        }
    }

    if (! self.sentResponse) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_NOT_SECURE"];
        [self._plugin.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
    }

}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

// Delegate method, called from connectionWithRequest
- (void) connection: (NSURLConnection*)connection didFailWithError: (NSError*)error {
    connection = nil;

    NSString *resultCode = @"CONNECTION_FAILED. Details:";
    NSString *errStr = [NSString stringWithFormat:@"%@ %@", resultCode, [error localizedDescription]];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:errStr];
    [self._plugin.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    connection = nil;

    if (![self sentResponse]) {
        NSLog(@"Connection was not checked because it was cached. Considering it secure to not break your app.");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"CONNECTION_SECURE"];
        [self._plugin.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
    }
}

- (NSString*) getFingerprint: (SecCertificateRef) cert {
    /*NSData* certData = (__bridge NSData*) SecCertificateCopyData(cert);
    unsigned char sha1Bytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, (int)certData.length, sha1Bytes);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", sha1Bytes[i]];
    }*/

    NSData* certData = (__bridge NSData*) SecCertificateCopyData(cert);
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(certData.bytes, (CC_LONG)certData.length, digest);//int
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];//3
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", digest[i]];
    }

    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString*) getIssuerValue: (const char *)issuerId issuerX509Name:(X509_NAME *)issuerX509Name
{
    NSString *issuer = nil;
    int nid = OBJ_txt2nid(issuerId);
    int index = X509_NAME_get_index_by_NID(issuerX509Name, nid, -1);

    X509_NAME_ENTRY *issuerNameEntry = X509_NAME_get_entry(issuerX509Name, index);

    if (issuerNameEntry) {
        ASN1_STRING *issuerNameASN1 = X509_NAME_ENTRY_get_data(issuerNameEntry);

        if (issuerNameASN1 != NULL) {
            unsigned char *issuerName = ASN1_STRING_data(issuerNameASN1);
            issuer = [NSString stringWithUTF8String:(char *)issuerName];
        }
    }
    return issuer;
}

- (NSString*) certificateGetIssuerName: (X509 *) certificateX509
{
    NSMutableString *issuer = [NSMutableString string];
    NSArray *issuerKeys;
    NSString *key;

    issuerKeys = [NSArray arrayWithObjects: @"CN", @"O", @"L", @"ST", @"C", nil];

    if (certificateX509 != NULL) {
        X509_NAME *issuerX509Name = X509_get_issuer_name(certificateX509);

        if (issuerX509Name != NULL) {
            for (key in issuerKeys) {
                NSString *issuerValue = nil;
                issuerValue = [self getIssuerValue:[key UTF8String] issuerX509Name:issuerX509Name];

                if (issuer.length > 0) {
                    [issuer appendString: @","];
                }
                [issuer appendString: [NSString stringWithFormat:@"%@=%@", key, issuerValue]];
            }
        }
    }

    return issuer;
}

- (NSString*) getIssuer: (SecCertificateRef) cert {

    NSData *certificateData = (NSData *) CFBridgingRelease(SecCertificateCopyData(cert));
    const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);

    NSString *issuer = [self certificateGetIssuerName:certificateX509];

    return issuer;
}

- (BOOL) isFingerprintTrusted: (NSString*)fingerprint {
    for (NSString *fp in self._allowedFingerprints) {
        if ([fingerprint caseInsensitiveCompare: fp] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

@end


@interface SSLCertificateChecker ()

@property (strong, nonatomic) NSString *_callbackId;
@property (strong, nonatomic) NSMutableData *_connections;

@end

@implementation SSLCertificateChecker

- (void)check:(CDVInvokedUrlCommand*)command {

    int cacheSizeMemory = 0*4*1024*1024; // 0MB
    int cacheSizeDisk = 0*32*1024*1024; // 0MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];

    NSString *serverURL = [command.arguments objectAtIndex:0];
    //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:6.0];

    CustomURLConnectionDelegate *delegate = [[CustomURLConnectionDelegate alloc] initWithPlugin:self//No cambiar self por plugin ya que deja de funcionar
                                                                                     callbackId:command.callbackId
                                                                               checkInCertChain:[[command.arguments objectAtIndex:1] boolValue]
                                                                            allowedFingerprints:[command.arguments objectAtIndex:2]
                                                                                    checkIssuer:FALSE];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    if(![[NSURLConnection alloc]initWithRequest:request delegate:delegate]){
        //if (![NSURLConnection connectionWithRequest:request delegate:delegate]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_FAILED"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
    }
}

- (void)checkissuer:(CDVInvokedUrlCommand*)command {

    int cacheSizeMemory = 0*4*1024*1024; // 0MB
    int cacheSizeDisk = 0*32*1024*1024; // 0MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];

    NSString *serverURL = [command.arguments objectAtIndex:0];
    //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:6.0];

    CustomURLConnectionDelegate *delegate = [[CustomURLConnectionDelegate alloc] initWithPlugin:self//No cambiar self por plugin ya que deja de funcionar
                                                                                     callbackId:command.callbackId
                                                                               checkInCertChain:[[command.arguments objectAtIndex:1] boolValue]
                                                                            allowedFingerprints:[command.arguments objectAtIndex:2] //allowedIssuers
                                                                                    checkIssuer:TRUE];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    if(![[NSURLConnection alloc]initWithRequest:request delegate:delegate]){
        //if (![NSURLConnection connectionWithRequest:request delegate:delegate]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:@"CONNECTION_FAILED"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
    }
}

@end
