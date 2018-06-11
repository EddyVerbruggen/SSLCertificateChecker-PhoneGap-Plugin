#import "SSLCertificateChecker.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPluginResult.h>
#import <CommonCrypto/CommonDigest.h>

@interface CustomURLSessionDelegate : NSObject <NSURLSessionDelegate>;

@property (strong, nonatomic) CDVPlugin *_plugin;
@property (strong, nonatomic) NSString *_callbackId;
@property (nonatomic, assign) BOOL _checkInCertChain;
@property (strong, nonatomic) NSArray *_allowedFingerprints;
@property (nonatomic, assign) BOOL sentResponse;

- (id)initWithPlugin:(CDVPlugin*)plugin callbackId:(NSString*)callbackId checkInCertChain:(BOOL)checkInCertChain allowedFingerprints:(NSArray*)allowedFingerprints;

@end

@implementation CustomURLSessionDelegate

- (id)initWithPlugin:(CDVPlugin*)plugin callbackId:(NSString*)callbackId checkInCertChain:(BOOL)checkInCertChain allowedFingerprints:(NSArray*)allowedFingerprints
{
    self.sentResponse = FALSE;
    self._plugin = plugin;
    self._callbackId = callbackId;
    self._checkInCertChain = FALSE; // if for some reason this code is called we will still not check the chain because it's insecure
    self._allowedFingerprints = allowedFingerprints;
    
    return self;
}

-  (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSLog(@"didReceiveChallenge ");
    
    SecTrustRef trustRef = [[challenge protectionSpace] serverTrust];
    SecTrustEvaluate(trustRef, NULL);
   
    CFIndex count = 1;
    if (self._checkInCertChain) {
        count = SecTrustGetCertificateCount(trustRef);
    }
    
    for (CFIndex i = 0; i < count; i++)
    {
        SecCertificateRef certRef = SecTrustGetCertificateAtIndex(trustRef, i);
        NSString* fingerprint = [self getFingerprint:certRef];
        
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

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSLog(@"didReceiveResponse ");
    
    NSHTTPURLResponse *respon = (NSHTTPURLResponse *)response;
    NSLog(@"respon %ld", (long)respon.statusCode);
    NSLog(@"URL %@",respon.URL);
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData ");
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received String %@",str);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSLog(@"didCompleteWithError ");
    
    NSString *resultCode = @"CONNECTION_FAILED. Details:";
    NSString *errStr = [NSString stringWithFormat:@"%@ %@", resultCode, [error localizedDescription]];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION messageAsString:errStr];
    [self._plugin.commandDelegate sendPluginResult:pluginResult callbackId:self._callbackId];
    
    /*
    if(error == nil)
    {
        NSLog(@"Communication is Succesfull");
    }
    else
        NSLog(@"Error %@",[error userInfo]);
     */
}

- (NSString*) getFingerprint: (SecCertificateRef) cert {
	/*
    NSData* certData = (__bridge NSData*) SecCertificateCopyData(cert);
    unsigned char sha1Bytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, (int)certData.length, sha1Bytes);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", sha1Bytes[i]];
    }
	*/

	NSData* certData = (__bridge NSData*) SecCertificateCopyData(cert);
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(certData.bytes, (CC_LONG)certData.length, digest);//int
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];//3
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [fingerprint appendFormat:@"%02x ", digest[i]];
    }

    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
    NSString *serverURL = [command.arguments objectAtIndex:0];
    NSURL *url = [NSURL URLWithString:serverURL];
    
    CustomURLSessionDelegate *delegate = [[CustomURLSessionDelegate alloc] initWithPlugin:self
                                                                               callbackId:command.callbackId
                                                                         checkInCertChain:[[command.arguments objectAtIndex:1] boolValue]
                                                                      allowedFingerprints:[command.arguments objectAtIndex:2]];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration: [NSURLSessionConfiguration ephemeralSessionConfiguration]
                                                                 delegate: delegate
                                                            delegateQueue:  nil];
    
    NSURLSessionDataTask * dataTask = [session dataTaskWithURL:url
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                 if(error != nil){
                                                     NSLog(@"Error = %@", error);
                                                 }
                                                 else if(data != nil) {
                                                            NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                            NSLog(@"Data = %@", text);
                                                 }
                                             }];
    
    [dataTask resume];
}

@end

