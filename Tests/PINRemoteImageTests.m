//
//  PINRemoteImage_Tests.m
//  PINRemoteImage Tests
//
//  Created by Garrett Moon on 11/6/14.
//  Copyright (c) 2014 Garrett Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <PINRemoteImage/PINAnimatedImageView.h>
#import <PINRemoteImage/PINRemoteImage.h>
#import <PINRemoteImage/PINURLSessionManager.h>
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <PINRemoteImage/PINRemoteImageCaching.h>
#import <PINRemoteImage/PINRequestRetryStrategy.h>
#import <PINCache/PINCache.h>

#import "NSDate+PINCacheTests.h"
#import "PINResume.h"
#import "PINRemoteImageDownloadTask.h"
#import "PINSpeedRecorder.h"

#import <objc/runtime.h>

static BOOL requestRetried = NO;
static NSInteger canceledCount = 0;

static inline BOOL PINImageAlphaInfoIsOpaque(CGImageAlphaInfo info) {
	switch (info) {
		case kCGImageAlphaNone:
		case kCGImageAlphaNoneSkipLast:
		case kCGImageAlphaNoneSkipFirst:
			return YES;
		default:
			return NO;
	}
}

@interface PINRemoteImageDownloadTask (Private)

- (void)scheduleDownloadWithRequest:(NSURLRequest *)request
                             resume:(PINResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PINRemoteImageManagerPriority)priority
                            isRetry:(BOOL)isRetry
                  completionHandler:(PINRemoteImageManagerDataCompletion)completionHandler;

@end

@interface PINRemoteImageDownloadTask (Swizzled)

- (void)swizzled_scheduleDownloadWithRequest:(NSURLRequest *)request
                                      resume:(PINResume *)resume
                                   skipRetry:(BOOL)skipRetry
                                    priority:(PINRemoteImageManagerPriority)priority
                                     isRetry:(BOOL)isRetry
                           completionHandler:(PINRemoteImageManagerDataCompletion)completionHandler;

@end

#if DEBUG
@interface PINRemoteImageManager ()

@property (nonatomic, strong) PINURLSessionManager *sessionManager;
@property (nonatomic, readonly) NSUInteger totalDownloads;

- (NSString *)resumeCacheKeyForURL:(NSURL *)url;

@end

@interface PINRemoteImageManager (Swizzled)

- (void)swizzled_cancelTaskWithUUID:(nonnull NSUUID *)UUID storeResumeData:(BOOL)storeResumeData;

@end

@interface PINURLSessionManager ()

@property (nonatomic, strong) NSURLSession *session;
- (void)storeTimeToFirstByte:(NSTimeInterval)timeToFirstByte forHost:(NSString *)host;

@end
#endif

@interface PINRemoteImage_Tests : XCTestCase <PINURLSessionManagerDelegate>

@property (nonatomic, strong) PINRemoteImageManager *imageManager;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSError *error;

@end

@interface PINSpeedRecorder ()

- (void)resetMeasurements;
- (void)updateSpeedsForHost:(NSString *)host bytesPerSecond:(float)bytesPerSecond startAdjustedBytesPerSecond:(float)startAdjustedBytesPerSecond timeToFirstByte:(float)timeToFirstByte;

@end

@implementation PINRemoteImage_Tests

- (NSTimeInterval)timeoutTimeInterval {
    return 30.0;
}

- (dispatch_time_t)timeoutWithInterval:(NSTimeInterval)interval {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
}

- (dispatch_time_t)timeout {
    return [self timeoutWithInterval:[self timeoutTimeInterval]];
}

- (NSURL *)GIFURL
{
    return [NSURL URLWithString:@"https://i.pinimg.com/originals/90/f5/77/90f577fc6abcd24f9a5f9f55b2d7482b.jpg"];
}

- (NSURL *)emptyURL
{
    return [NSURL URLWithString:@""];
}

- (NSURL *)fourZeroFourURL
{
    return [NSURL URLWithString:@"https://google.com/404"];
}

- (NSURL *)headersURL
{
    return [NSURL URLWithString:@"https://httpbin.org/headers"];
}

- (NSURL *)JPEGURL_Small
{
    return [NSURL URLWithString:@"https://i.pinimg.com/345x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"];
}

- (NSURL *)JPEGURL_Medium
{
    return [NSURL URLWithString:@"https://i.pinimg.com/600x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"];
}

- (NSURL *)JPEGURL_Large
{
    return [NSURL URLWithString:@"https://i.pinimg.com/750x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"];
}

- (NSURL *)JPEGURL
{
    return [self JPEGURL_Medium];
}

- (NSURL *)BASE64URL
{
    return [NSURL URLWithString:@"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUAAAD///+l2Z/dAAAAM0lEQVR4nGP4/5/h/1+G/58ZDrAz3D/McH8yw83NDDeNGe4Ug9C9zwz3gVLMDA/A6P9/AFGGFyjOXZtQAAAAAElFTkSuQmCC"];
}

- (NSURL *)transparentPNGURL
{
	return [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png"];
}

- (NSURL *)nonTransparentWebPURL
{
    return [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/5.webp"];
}

- (NSURL *)transparentWebPURL
{
    return [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery3/4_webp_ll.webp"];
}

- (NSURL *)veryLongURL
{
    return [NSURL URLWithString:@"https://placekitten.com/g/200/301?longarg=helloMomHowAreYouDoing.IamFineJustMovedToLiveWithANiceChapWeTravelTogetherInHisBlueBoxThroughSpaceAndTimeMaybeYouveMetHimAlready.YesterdayWeMetACultureOfPeopleWithTentaclesWhoSingWithAVeryCelestialVoice.SoGood.SeeYouSoon.MaybeYesterday.WhoKnows.XOXO"];
}

- (NSURL *)progressiveURL
{
    return [NSURL URLWithString:@"https://performancedemo.vir2al.ch/assets/img/progressive/thumb/spiez_sunset.jpg"];
}

- (NSURL *)progressiveURL2
{
    return [NSURL URLWithString:@"https://performancedemo.vir2al.ch/assets/img/baseline/thumb/balkon.jpg"];
}

- (NSArray <NSURL *> *)bigURLs
{
    static dispatch_once_t onceToken;
    static NSArray *bigURLs;
    dispatch_once(&onceToken, ^{
        bigURLs = @[[NSURL URLWithString:@"https://images.unsplash.com/photo-1483388381485-344c3a9ded7f"],
                    [NSURL URLWithString:@"https://images.unsplash.com/photo-1483279745275-2a5d5a1074d2"],
                    [NSURL URLWithString:@"https://images.unsplash.com/photo-1483127140828-af66a3429184"],
                    [NSURL URLWithString:@"https://images.unsplash.com/photo-1482160310982-3adf8b38daef"],
                    ];
    });
    
    return bigURLs;
}

- (NSURL *)imageFrom404URL
{
    NSString *base64EncodedUrl = @"aHR0cHM6Ly9pLnl0aW1nLmNvbS92aS9PRzlRbW9jNGVZcy9tcWRlZmF1bHQuanBn";
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:base64EncodedUrl options:0];
    NSString *base64Decoded = [[NSString alloc] initWithData:nsdataFromBase64String encoding:NSUTF8StringEncoding];
    return [[NSURL alloc] initWithString:base64Decoded];
}

#pragma mark - <PINURLSessionManagerDelegate>

- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionTask *)task
{
    self.task = task;
}

- (void)didCompleteTask:(NSURLSessionTask *)task withError:(NSError *)error
{
    self.task = task;
    self.error = error;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.imageManager = [[PINRemoteImageManager alloc] init];
    [self.imageManager.cache removeAllObjects];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    //clear disk cache
    self.imageManager = nil;
    [[PINSpeedRecorder sharedRecorder] setCurrentBytesPerSecond:-1];
    [[PINSpeedRecorder sharedRecorder] resetMeasurements];
    [super tearDown];
}

- (void)testGIFDownload
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download animatedImage"];
    [self.imageManager downloadImageWithURL:[self GIFURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        UIImage *outImage = result.image;
        id outAnimatedImage = result.alternativeRepresentation;
        
        XCTAssert(outAnimatedImage && [outAnimatedImage isKindOfClass:[PINCachedAnimatedImage class]], @"Failed downloading animatedImage or animatedImage is not a PINCachedAnimatedImage.");
        XCTAssert(outImage == nil, @"Image is not nil.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testInitWithNilConfiguration
{
    self.imageManager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:nil];
    XCTAssertNotNil(self.imageManager.sessionManager.session.configuration);
}

- (void)testInitWithConfiguration
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{ @"Authorization" : @"Pinterest 123456" };
    self.imageManager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:configuration];
    XCTAssert([self.imageManager.sessionManager.session.configuration.HTTPAdditionalHeaders isEqualToDictionary:@{ @"Authorization" : @"Pinterest 123456" }]);
}

- (void)testURLSessionManagerDeallocated
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"URLSessionManager should be deallocated"];
    __block __weak PINURLSessionManager *sessionManager = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        PINRemoteImageManager *manager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:nil];
        sessionManager = manager.sessionManager;
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssert(sessionManager == nil);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testCustomHeaderIsAddedToImageRequests
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom header was added to image request"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{ @"X-Custom-Header" : @"Custom Header Value" };
    self.imageManager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:configuration];
    self.imageManager.sessionManager.delegate = self;
  
    //sleep for a moment so values have a chance to asynchronously set.
    usleep(10000);
  
    [self.imageManager downloadImageWithURL:[self headersURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         NSDictionary *headers = [self.task.currentRequest allHTTPHeaderFields];
         
         XCTAssert([headers[@"X-Custom-Header"] isEqualToString:@"Custom Header Value"]);
         
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testRequestConfigurationIsUsedForImageRequest
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Requestion configuration block was called image request"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{ @"X-Custom-Header" : @"Custom Header Value" };

    self.imageManager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:configuration];
    [self.imageManager setRequestConfiguration:^NSURLRequest * _Nonnull(NSURLRequest * _Nonnull request) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest setValue:@"Custom Header 2 Value" forHTTPHeaderField:@"X-Custom-Header-2"];
        return mutableRequest;
    }];
  
    //sleep for a moment so values have a chance to asynchronously set.
    usleep(10000);
  
    self.imageManager.sessionManager.delegate = self;
    [self.imageManager downloadImageWithURL:[self headersURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         NSDictionary *headers = [self.task.currentRequest allHTTPHeaderFields];
         XCTAssert([headers[@"X-Custom-Header"] isEqualToString:@"Custom Header Value"]);
         XCTAssert([headers[@"X-Custom-Header-2"] isEqualToString:@"Custom Header 2 Value"]);

         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testResponseHeadersReturned
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"Headers returned in image download result"];
  [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult * _Nonnull result) {
      NSDictionary *headers = [(NSHTTPURLResponse *)result.response allHeaderFields];
      XCTAssert(headers != nil, @"Expected headers back");
      
      [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testSkipPINAnimatedImageDownload
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download animated image"];
    [self.imageManager downloadImageWithURL:[self GIFURL]
                                    options:PINRemoteImageManagerDisallowAlternateRepresentations
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        UIImage *outImage = result.image;
        id outAnimatedImage = result.alternativeRepresentation;
        
        XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
        XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testIgnoreCache
{
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:nil];
    [self waitForImageWithURLToBeCached:[self JPEGURL]];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Download ignoring cache"];
    [self.imageManager downloadImageWithURL:[self JPEGURL]
                                    options:PINRemoteImageManagerDownloadOptionsIgnoreCache
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         XCTAssert(result.resultType == PINRemoteImageResultTypeDownload, @"Image was fetched from cache");

         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testJPEGDownload
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Downloading JPEG image"];
    [self.imageManager downloadImageWithURL:[self JPEGURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        UIImage *outImage = result.image;
        id outAnimatedImage = result.alternativeRepresentation;
        
        XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
        XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testBase64
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Decoding base64 image"];
    [self.imageManager downloadImageWithURL:[self BASE64URL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         UIImage *outImage = result.image;
         PINCachedAnimatedImage *outAnimatedImage = result.alternativeRepresentation;
         
         XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
         XCTAssert(CGSizeEqualToSize(outImage.size, CGSizeMake(16,16)), @"Failed decoding image, image size is wrong.");
         XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
         
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testHTTPResponse404WithData
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"image from 404 response should set correctly"];
    PINRemoteImageManager *manager = [[PINRemoteImageManager alloc] init];
    NSURL *url = [self imageFrom404URL];
    [manager downloadImageWithURL:url completion:^(PINRemoteImageManagerResult * _Nonnull result) {
        XCTAssertNotNil(result.image);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval]  handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void)testErrorOnNilURLDownload
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTestExpectation *expectation = [self expectationWithDescription:@"Error on nil image url download"];
    [self.imageManager downloadImageWithURL:nil
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
#pragma clang diagnostic pop
     {
         NSError *outError = result.error;
         
         XCTAssert([outError.domain isEqualToString:NSURLErrorDomain]);
         XCTAssert(outError.code == NSURLErrorUnsupportedURL);
         XCTAssert([outError.localizedDescription isEqualToString:@"unsupported URL"]);
         
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testErrorOnEmptyURLDownload
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Error on empty image url download"];
    [self.imageManager downloadImageWithURL:[self emptyURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         NSError *outError = result.error;
         
         XCTAssert([outError.domain isEqualToString:NSURLErrorDomain]);
         XCTAssert(outError.code == NSURLErrorUnsupportedURL);
         // iOS8 (and presumably 10.10) returns NSURLErrorUnsupportedURL which means the HTTP NSURLProtocol does not accept it
         NSArray *validErrorMessages = @[ @"unsupported URL", @"The operation couldn’t be completed. (NSURLErrorDomain error -1002.)"];
         XCTAssert([validErrorMessages containsObject:outError.localizedDescription], @"%@", outError.localizedDescription);
         
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testErrorOn404Response
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Error on 404 response"];
    [self.imageManager downloadImageWithURL:[self fourZeroFourURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         NSError *outError = result.error;
         
         XCTAssert([outError.domain isEqualToString:PINURLErrorDomain]);
         XCTAssert(outError.code == 404);
         
         [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testDecoding
{
    dispatch_group_t group = dispatch_group_create();
    __block UIImage *outImageDecoded = nil;
    __block UIImage *outImageEncoded = nil;
    PINRemoteImageManager *encodedManager = [[PINRemoteImageManager alloc] init];
    
    dispatch_group_enter(group);
    [self.imageManager downloadImageWithURL:[self JPEGURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        outImageDecoded = result.image;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    dispatch_group_enter(group);
    [encodedManager downloadImageWithURL:[self JPEGURL]
                                 options:PINRemoteImageManagerDownloadOptionsSkipDecode
                              completion:^(PINRemoteImageManagerResult *result)
    {
        outImageEncoded = result.image;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    CFTimeInterval before = CACurrentMediaTime();
    [self drawImage:outImageEncoded];
    CFTimeInterval after = CACurrentMediaTime();
    CFTimeInterval encodedDrawTime = after - before;
    
    before = CACurrentMediaTime();
    [self drawImage:outImageDecoded];
    after = CACurrentMediaTime();
    CFTimeInterval decodedDrawTime = after - before;
    
    XCTAssert(outImageEncoded && [outImageEncoded isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
    XCTAssert(outImageDecoded && [outImageDecoded isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
    XCTAssert(encodedDrawTime / decodedDrawTime > 2, @"Drawing decoded image should be much faster");
}

- (void)drawImage:(UIImage *)image
{
    UIGraphicsBeginImageContext(image.size);
    
    [image drawAtPoint:CGPointZero];
    
    UIGraphicsEndImageContext();
}

- (void)waitForImageWithURLToBeCached:(NSURL *)URL
{
    NSString *key = [self.imageManager cacheKeyForURL:URL processorKey:nil];
    for (NSUInteger idx = 0; idx < 100; idx++) {
        if ([[self.imageManager cache] objectExistsForKey:key]) {
            break;
        }
        if (idx == 99) {
            XCTAssert(NO, @"image never set to cache.");
        }
        usleep(50000);
    }
}

- (void)testTransparentWebPDownload
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download transparent WebP image"];
    [self.imageManager downloadImageWithURL:[self transparentWebPURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        XCTAssert(result.error == nil, @"error is non-nil: %@", result.error);
        
        UIImage *outImage = result.image;
        id outAnimatedImage = result.alternativeRepresentation;
        
        XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
        
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(outImage.CGImage);
        BOOL opaque = alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst || alphaInfo == kCGImageAlphaNoneSkipLast;
        
        XCTAssert(opaque == NO, @"transparent WebP image is opaque.");
        XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testNonTransparentWebPDownload
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download non transparent WebP image"];
    [self.imageManager downloadImageWithURL:[self nonTransparentWebPURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        UIImage *outImage = result.image;
        id outAnimatedImage = result.alternativeRepresentation;
        
        XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
        
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(outImage.CGImage);
        BOOL opaque = alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst || alphaInfo == kCGImageAlphaNoneSkipLast;
        
        XCTAssert(opaque == YES, @"non transparent WebP image is not opaque.");
        XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testPrefetchImage
{
    id key  = [self.imageManager cacheKeyForURL:[self JPEGURL] processorKey:nil];

    id object = [[self.imageManager cache] objectFromMemoryForKey:key];
    XCTAssert(object == nil, @"image should not be in cache");
    
    [self.imageManager prefetchImageWithURL:[self JPEGURL]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"image was prefetched into cache"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while ([[self.imageManager cache] objectFromMemoryForKey:key] == nil) {
            usleep(10000);
        }
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testUIImageView
{
    XCTestExpectation *imageSetExpectation = [self expectationWithDescription:@"imageView did not have image set"];
    UIImageView *imageView = [[UIImageView alloc] init];
    __weak UIImageView *weakImageView = imageView;
    [imageView pin_setImageFromURL:[self JPEGURL]
                        completion:^(PINRemoteImageManagerResult *result)
     {
         if (weakImageView.image)
             [imageSetExpectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testPINAnimatedImageView
{
    XCTestExpectation *imageSetExpectation = [self expectationWithDescription:@"animatedImageView did not have animated image set"];
    PINAnimatedImageView *imageView = [[PINAnimatedImageView alloc] init];
    __weak PINAnimatedImageView *weakImageView = imageView;
    [imageView pin_setImageFromURL:[self GIFURL]
                        completion:^(PINRemoteImageManagerResult *result)
     {
         if (weakImageView.animatedImage)
             [imageSetExpectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testEarlyReturn
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download JPEG image"];
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
    
    // callback can occur *before* image is stored in cache this is an optimization to avoid waiting on the cache to write.
    // So, wait until it's actually in the cache.
    [self waitForImageWithURLToBeCached:[self JPEGURL]];
    
    __block UIImage *image = nil;
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
        image = result.image;
    }];
    XCTAssert(image != nil, @"image callback did not occur synchronously.");
}

- (void)testload
{
    srand([[NSDate date] timeIntervalSince1970]);
    dispatch_group_t group = dispatch_group_create();
    __block NSInteger count = 0;
    const NSInteger numIntervals = 10000;
    NSLock *countLock = [[NSLock alloc] init];
    for (NSUInteger idx = 0; idx < numIntervals; idx++) {
        dispatch_group_enter(group);
        NSURL *url = nil;
        if (rand() % 2 == 0) {
            url = [self JPEGURL];
        } else {
            url = [self GIFURL];
        }
        [self.imageManager downloadImageWithURL:url
                                        options:PINRemoteImageManagerDownloadOptionsNone
                                     completion:^(PINRemoteImageManagerResult *result)
        {
            [countLock lock];
            count++;
            XCTAssert(count <= numIntervals, @"callback called too many times");
            [countLock unlock];
            XCTAssert((result.image && !result.alternativeRepresentation) || (result.alternativeRepresentation && !result.image), @"image or alternativeRepresentation not downloaded");
            if (rand() % 2) {
                [[self.imageManager cache] removeObjectForKey:[self.imageManager cacheKeyForURL:url processorKey:nil]];
            }
            dispatch_group_leave(group);
        }];
    }
    XCTAssert(dispatch_group_wait(group, [self timeoutWithInterval:100]) == 0, @"Group timed out.");
}

- (void)testInvalidObject
{
    NSString * const kPINRemoteImageDiskCacheName = @"PINRemoteImageManagerCache";
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
  
    PINDiskCache *tempDiskCache = [[PINDiskCache alloc] initWithName:kPINRemoteImageDiskCacheName rootPath:cachePath serializer:^NSData * _Nonnull(id<NSCoding>  _Nonnull object, NSString * _Nonnull key) {
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    } deserializer:^id<NSCoding> _Nonnull(NSData * _Nonnull data, NSString * _Nonnull key) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }];
    
    [tempDiskCache setObject:@"invalid" forKey:[self.imageManager cacheKeyForURL:[self JPEGURL] processorKey:nil]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download JPEG image"];
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
        UIImage *image = result.image;
        
        XCTAssert([image isKindOfClass:[UIImage class]], @"image should be UIImage");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
    
}

- (void)testImageFromCacheReturnsNilErrorForCacheMiss
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image from cache"];

    [self.imageManager imageFromCacheWithURL:[self JPEGURL] processorKey:nil options:PINRemoteImageManagerDownloadOptionsNone completion:^(PINRemoteImageManagerResult * _Nonnull result) {
         XCTAssert(result.image == nil, @"Image was found in cache");
         XCTAssert(result.error == nil, @"Error was returned in cache miss");

         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testProcessingLoad
{
    dispatch_group_t group = dispatch_group_create();
    
    __block UIImage *image = nil;
    const NSUInteger numIntervals = 1000;
    __block NSInteger processCount = 0;
    __block UIImage *processedImage = nil;
    NSLock *processCountLock = [[NSLock alloc] init];
    for (NSUInteger idx = 0; idx < numIntervals; idx++) {
        dispatch_group_enter(group);
        [self.imageManager downloadImageWithURL:[self JPEGURL] options:PINRemoteImageManagerDownloadOptionsNone
                                   processorKey:@"process"
                                      processor:^UIImage *(PINRemoteImageManagerResult *result, NSUInteger *cost)
         {
             [processCountLock lock];
             processCount++;
             [processCountLock unlock];
             
             UIImage *inputImage = result.image;
             XCTAssert(inputImage, @"no input image");
             UIGraphicsBeginImageContextWithOptions(inputImage.size, NO, 0);
             CGContextRef context = UIGraphicsGetCurrentContext();
             
             CGRect destRect = CGRectMake(0, 0, inputImage.size.width, inputImage.size.height);
             [[UIColor clearColor] set];
             CGContextFillRect(context, destRect);
             
             CGRect pathRect = CGRectMake(0, 0, inputImage.size.width, inputImage.size.height);
             UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathRect
                                                             cornerRadius:MIN(inputImage.size.width, inputImage.size.height) / 2.0];
             CGContextAddPath(context, path.CGPath);
             CGContextClosePath(context);
             CGContextClip(context);
             
             [inputImage drawInRect:CGRectMake(0, 0, inputImage.size.width, inputImage.size.height)];
             
             UIImage *roundedImage = nil;
             roundedImage = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             processedImage = roundedImage;
             
             return roundedImage;
         }
                                     completion:^(PINRemoteImageManagerResult *result)
         {
             image = result.image;
             XCTAssert([image isKindOfClass:[UIImage class]] && image == processedImage, @"result image is not a UIImage");
             dispatch_group_leave(group);
         }];
    }
    
    XCTAssert(dispatch_group_wait(group, [self timeout]) == 0, @"Group timed out.");
    
    XCTAssert(processCount <= 1, @"image processed too many times");
    XCTAssert([image isKindOfClass:[UIImage class]], @"result image is not a UIImage");
}

- (void)testNumberDownloads
{
    dispatch_group_t group = dispatch_group_create();
    
    __block UIImage *image = nil;
    const NSUInteger numIntervals = 1000;

    for (NSUInteger idx = 0; idx < numIntervals; idx++) {
        dispatch_group_enter(group);
        [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
            XCTAssert([result.image isKindOfClass:[UIImage class]], @"result image is not a UIImage");
            image = result.image;
            dispatch_group_leave(group);
        }];
    }
    
    XCTAssert(dispatch_group_wait(group, [self timeout]) == 0, @"Group timed out.");
    
    XCTAssert(self.imageManager.totalDownloads <= 1, @"image downloaded too many times: %lu", (unsigned long)self.imageManager.totalDownloads);
    XCTAssert([image isKindOfClass:[UIImage class]], @"result image is not a UIImage");
}

- (BOOL)isFloat:(float)one equalToFloat:(float)two
{
    if (fabsf(one - two) < FLT_EPSILON) {
        return YES;
    }
    return NO;
}

- (void)testBytesPerSecond
{
    NSString *host = @"none.com";

    XCTAssert([[PINSpeedRecorder sharedRecorder] weightedAdjustedBytesPerSecondForHost:host] == -1, @"Without any tasks added, should be -1");
    [[PINSpeedRecorder sharedRecorder] updateSpeedsForHost:host bytesPerSecond:100 startAdjustedBytesPerSecond:100 timeToFirstByte:0];
    XCTAssert([self isFloat:[[PINSpeedRecorder sharedRecorder] weightedAdjustedBytesPerSecondForHost:host] equalToFloat:100.0f], @"One task should be same as added task");
    [[PINSpeedRecorder sharedRecorder] updateSpeedsForHost:host bytesPerSecond:50 startAdjustedBytesPerSecond:50 timeToFirstByte:0];
    XCTAssert([self isFloat:[[PINSpeedRecorder sharedRecorder] weightedAdjustedBytesPerSecondForHost:host] equalToFloat:90.0], @"Last task should be weighted");
}

- (void)testQOS
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.imageManager setHighQualityBPSThreshold:10 completion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [self.imageManager setLowQualityBPSThreshold:5 completion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [self.imageManager setShouldUpgradeLowQualityImages:NO completion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    __block UIImage *image;
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                               progressImage:nil
                                  completion:^(PINRemoteImageManagerResult *result)
    {
        image = result.image;
        XCTAssert(image.size.width == 750, @"Large image should be downloaded. result.image: %@, result.error: %@", result.image, result.error);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    // callback can occur *before* image is stored in cache this is an optimization to avoid waiting on the cache to write.
    // So, wait until it's actually in the cache.
    [self waitForImageWithURLToBeCached:[self JPEGURL_Large]];
    
    [[PINSpeedRecorder sharedRecorder] setCurrentBytesPerSecond:5];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                               progressImage:nil
                                  completion:^(PINRemoteImageManagerResult *result)
    {
        image = result.image;
        XCTAssert(image.size.width == 750, @"Large image should be found in cache");
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");

    [self.imageManager.cache removeAllObjects];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                               progressImage:nil
                                  completion:^(PINRemoteImageManagerResult *result)
    {
        image = result.image;
        XCTAssert(image.size.width == 345, @"Small image should be downloaded at low bps");
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [self waitForImageWithURLToBeCached:[self JPEGURL_Small]];
    
    [[PINSpeedRecorder sharedRecorder] setCurrentBytesPerSecond:100];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                               progressImage:nil
                                  completion:^(PINRemoteImageManagerResult *result)
    {
        image = result.image;
        XCTAssert(image.size.width == 345, @"Small image should be found in cache");
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [self.imageManager setShouldUpgradeLowQualityImages:YES completion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [[PINSpeedRecorder sharedRecorder] setCurrentBytesPerSecond:7];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                               progressImage:nil
                                  completion:^(PINRemoteImageManagerResult *result)
     {
         image = result.image;
         XCTAssert(image.size.width == 600, @"Medium image should be now downloaded");
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    //small image should have been removed from cache
    NSString *key = [self.imageManager cacheKeyForURL:[self JPEGURL_Small] processorKey:nil];
    for (NSUInteger idx = 0; idx < 100; idx++) {
        if ([[self.imageManager cache] objectFromMemoryForKey:key] == nil) {
            break;
        }
        usleep(100);
    }
    XCTAssert(
        [[self.imageManager cache] objectFromMemoryForKey:[self.imageManager cacheKeyForURL:[self JPEGURL_Small] processorKey:nil]] == nil, @"Small image should have been removed from cache");

    [self.imageManager.cache removeAllObjects];
    [self.imageManager setShouldUpgradeLowQualityImages:NO completion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [[PINSpeedRecorder sharedRecorder] setCurrentBytesPerSecond:7];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                               progressImage:nil
                                  completion:^(PINRemoteImageManagerResult *result)
     {
         image = result.image;
         XCTAssert(image.size.width == 345, @"Small image should be now downloaded");
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
}

- (void)testCacheControlSupport
{
    self.imageManager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:nil alternativeRepresentationProvider:nil imageCache:[PINRemoteImageManager defaultImageTtlCache] managerConfiguration:nil];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    id cache = self.imageManager.cache;
    XCTAssert([cache isKindOfClass:[PINCache class]]);
    PINCache *pinCache = (PINCache *)cache;
    pinCache.diskCache.ageLimit = 0; // forever, which is more than 31536000 (which is about a yr fwiw)
    XCTAssert(pinCache.diskCache.isTTLCache, @"Default imageManager did not use a ttl cache");

    // JPEGURL_Small includes the header "Cache-Control: max-age=31536000, immutable"
    // If that ever changes, this might start failing
    [self.imageManager downloadImageWithURL:[self JPEGURL_Small] completion:^(PINRemoteImageManagerResult *result) {
        XCTAssert(result.resultType == PINRemoteImageResultTypeDownload, @"Expected PINRemoteImageResultTypeDownload(3), got %lu", (unsigned long)result.resultType);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");

    NSString *key = [self.imageManager cacheKeyForURL:[self JPEGURL_Small] processorKey:nil];
    id diskCachedObj = [cache objectFromDiskForKey:key];
    XCTAssert(diskCachedObj != nil, @"Image was not found in the disk cache");
    [self.imageManager downloadImageWithURL:[self JPEGURL_Small] completion:^(PINRemoteImageManagerResult *result) {
        XCTAssert(result.resultType == PINRemoteImageResultTypeMemoryCache, @"Expected PINRemoteImageResultTypeCache(2), got %lu", (unsigned long)result.resultType);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");

    [NSDate startMockingDateWithDate:[NSDate dateWithTimeIntervalSinceNow:32000000]];
    diskCachedObj = [cache objectFromDiskForKey:key];
    XCTAssert(diskCachedObj == nil, @"Image was not discarded from the disk cache");
    [self.imageManager downloadImageWithURL:[self JPEGURL_Small] completion:^(PINRemoteImageManagerResult *result) {
        XCTAssert(result.resultType == PINRemoteImageResultTypeDownload, @"Expected PINRemoteImageResultTypeDownload(3), got %lu", (unsigned long)result.resultType);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    [NSDate stopMockingDate];


    // nonTransparentWebPURL includes the header "expires: <about 1 yr from now>"
    // If that ever changes, this might start failing
    [self.imageManager downloadImageWithURL:[self nonTransparentWebPURL] completion:^(PINRemoteImageManagerResult *result) {
        XCTAssert(result.resultType == PINRemoteImageResultTypeDownload, @"Expected PINRemoteImageResultTypeDownload(3), got %lu", (unsigned long)result.resultType);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");

    key = [self.imageManager cacheKeyForURL:[self nonTransparentWebPURL] processorKey:nil];
    diskCachedObj = [cache objectFromDiskForKey:key];
    XCTAssert(diskCachedObj != nil, @"Image was not found in the disk cache");
    [self.imageManager downloadImageWithURL:[self nonTransparentWebPURL] completion:^(PINRemoteImageManagerResult *result) {
        XCTAssert(result.resultType == PINRemoteImageResultTypeMemoryCache, @"Expected PINRemoteImageResultTypeCache(2), got %lu", (unsigned long)result.resultType);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");

    [NSDate startMockingDateWithDate:[NSDate dateWithTimeIntervalSinceNow:32000000]];
    diskCachedObj = [cache objectFromDiskForKey:key];
    XCTAssert(diskCachedObj == nil, @"Image was not discarded from the disk cache");
    [self.imageManager downloadImageWithURL:[self nonTransparentWebPURL] completion:^(PINRemoteImageManagerResult *result) {
        XCTAssert(result.resultType == PINRemoteImageResultTypeDownload, @"Expected PINRemoteImageResultTypeDownload(3), got %lu", (unsigned long)result.resultType);
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    [NSDate stopMockingDate];

}

- (void)testAuthentication
{
	XCTestExpectation *expectation = [self expectationWithDescription:@"Authentification challenge was called"];
    __block BOOL authHit = NO;
	[self.imageManager setAuthenticationChallenge:^(NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, PINRemoteImageManagerAuthenticationChallengeCompletionHandler aHandler) {
		aHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        authHit = YES;
		[expectation fulfill];
	}];
    
    //Wait for async authentication challenge setter to complete
    sleep(1);
	
	[self.imageManager downloadImageWithURL:[NSURL URLWithString:@"https://i.pinimg.com/600x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"]
									options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult * _Nonnull result) {
                                     XCTAssert(authHit, @"should not complete without hitting auth challenge.");
                                 }];
	
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testDiskCacheOnLongURLs
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image is available in the disk cache"];
    id<PINRemoteImageCaching> cache = self.imageManager.cache;
    NSURL *longURL = [self veryLongURL];
    NSString *key = [self.imageManager cacheKeyForURL:longURL processorKey:nil];
    [self.imageManager downloadImageWithURL:longURL
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        XCTAssertNotNil(result.image, @"Image should not be nil");
        id diskCachedObj = [cache objectFromDiskForKey:key];
        XCTAssertNotNil(diskCachedObj);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testLongCacheKeyCreationPerformance
{
    [self measureBlock:^{
        NSURL *longURL = [self veryLongURL];
        for (NSUInteger i = 0; i < 10000; i++) {
            __unused NSString *key = [self.imageManager cacheKeyForURL:longURL processorKey:nil];
        }
    }];
}

- (void)testDefaultCacheKeyCreationPerformance
{
    [self measureBlock:^{
        NSURL *defaultURL = [self JPEGURL];
        for (NSUInteger i = 0; i < 10000; i++) {
            __unused NSString *key = [self.imageManager cacheKeyForURL:defaultURL processorKey:nil];
        }
    }];
}

- (void)testThatNondecodedJPEGImageHasNoAlpha
{
	XCTestExpectation *expectation = [self expectationWithDescription:@"Downloading JPEG image"];
	[self.imageManager downloadImageWithURL:[self JPEGURL]
									options:PINRemoteImageManagerDownloadOptionsSkipDecode
								 completion:^(PINRemoteImageManagerResult *result)
	 {
		 UIImage *outImage = result.image;
		 
		 XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
		 XCTAssert(PINImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(outImage.CGImage)), @"Opaque image has an alpha channel.");
		 
		 [expectation fulfill];
	 }];
	[self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testThatDecodedJPEGImageHasNoAlpha
{
	XCTestExpectation *expectation = [self expectationWithDescription:@"Downloading JPEG image"];
	[self.imageManager downloadImageWithURL:[self JPEGURL]
									options:PINRemoteImageManagerDownloadOptionsNone
								 completion:^(PINRemoteImageManagerResult *result)
	 {
		 UIImage *outImage = result.image;
		 
		 XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
		 XCTAssert(PINImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(outImage.CGImage)), @"Opaque image has an alpha channel.");
		 
		 [expectation fulfill];
	 }];
	[self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}


- (void)testThatNondecodedTransparentPNGImageHasAlpha
{
	XCTestExpectation *expectation = [self expectationWithDescription:@"Downloading PNG image"];
	[self.imageManager downloadImageWithURL:[self transparentPNGURL]
									options:PINRemoteImageManagerDownloadOptionsSkipDecode
								 completion:^(PINRemoteImageManagerResult *result)
	 {
		 UIImage *outImage = result.image;
		 
		 XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
		 XCTAssertFalse(PINImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(outImage.CGImage)), @"Transparent image has no alpha.");
		 
		 [expectation fulfill];
	 }];
	[self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testThatDecodedTransparentPNGImageHasAlpha
{
	XCTestExpectation *expectation = [self expectationWithDescription:@"Downloading PNG image"];
	[self.imageManager downloadImageWithURL:[self transparentPNGURL]
									options:PINRemoteImageManagerDownloadOptionsNone
								 completion:^(PINRemoteImageManagerResult *result)
	 {
		 UIImage *outImage = result.image;
		 
		 XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
		 XCTAssertFalse(PINImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(outImage.CGImage)), @"Transparent image has no alpha.");
		 
		 [expectation fulfill];
	 }];
	[self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testExponentialRetryStrategy
{
    PINRequestExponentialRetryStrategy *exponentialRetryStrategy = [[PINRequestExponentialRetryStrategy alloc] initWithRetryMaxCount:3 delayBase:2];
    
    NSError *retryableError = [NSError errorWithDomain:PINURLErrorDomain code:501 userInfo:@{}];
    NSError *nonRetryableError1 = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnsupportedURL userInfo:@{}];
    NSError *nonRetryableError2 = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain code:0 userInfo:@{}];
    XCTAssertTrue([exponentialRetryStrategy shouldRetryWithError:retryableError], @"Retryable error");
    XCTAssertFalse([exponentialRetryStrategy shouldRetryWithError:nonRetryableError1], @"Non retryable error");
    XCTAssertFalse([exponentialRetryStrategy shouldRetryWithError:nonRetryableError2], @"Non retryable error");
    
    
    XCTAssertTrue([exponentialRetryStrategy shouldRetryWithError:retryableError], @"Original request failed");
    [exponentialRetryStrategy incrementRetryCount];
    XCTAssertEqual([exponentialRetryStrategy nextDelay], 2, @"First delay, exponential strategy");
    
    XCTAssertTrue([exponentialRetryStrategy shouldRetryWithError:retryableError], @"First retry failed");
    [exponentialRetryStrategy incrementRetryCount];
    XCTAssertEqual([exponentialRetryStrategy nextDelay], 4, @"Second delay, exponential strategy");
    
    XCTAssertTrue([exponentialRetryStrategy shouldRetryWithError:retryableError], @"Second retry failed");
    [exponentialRetryStrategy incrementRetryCount];
    XCTAssertEqual([exponentialRetryStrategy nextDelay], 8, @"Third delay, exponential strategy");
    
    XCTAssertFalse([exponentialRetryStrategy shouldRetryWithError:retryableError], @"Third retry failed");
}

- (void)testMaximumNumberOfDownloads
{
    __block NSInteger count = 0;
    NSUInteger totalDownloads = [self bigURLs].count;
    static NSUInteger maxNumberOfConcurrentDownloads = 2;
    NSLock *countLock = [[NSLock alloc] init];
    XCTestExpectation *expectation = [self expectationWithDescription:@"All images downloaded"];
    
    void (^imageCompletion) (PINRemoteImageManagerResult* _Nonnull result) = ^(PINRemoteImageManagerResult * _Nonnull result) {
        [countLock lock];
        count++;
        if (count == totalDownloads) {
            [expectation fulfill];
        }
        [countLock unlock];
    };
    
    __weak typeof(self) weakSelf = self;
    [self.imageManager setMaxNumberOfConcurrentDownloads:maxNumberOfConcurrentDownloads completion:^{
        for (NSUInteger idx = 0; idx < totalDownloads; idx++) {
            [weakSelf.imageManager downloadImageWithURL:[weakSelf bigURLs][idx] completion:imageCompletion];
        }
    }];
    
    //I want this retain cycle
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    __block void (^checkConcurrentDownloads) (void);
    checkConcurrentDownloads = ^{
        usleep(10000);
        [self.imageManager.sessionManager concurrentDownloads:^(NSUInteger concurrentDownloads) {
            XCTAssert(concurrentDownloads <= maxNumberOfConcurrentDownloads, @"concurrent downloads: %lu", (unsigned long)concurrentDownloads);
            checkConcurrentDownloads();
        }];
    };
#pragma clang diagnostic pop
    
    checkConcurrentDownloads();
    
    //Give this one a bit longer since these are big images.
    [self waitForExpectationsWithTimeout:120 handler:nil];
}

- (void)testResume
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    PINWeakify(self);
    [self.imageManager setEstimatedRemainingTimeThresholdForProgressiveDownloads:0.001 completion:^{
        PINStrongify(self);
        [self.imageManager setProgressiveRendersMaxProgressiveRenderSize:CGSizeMake(10000, 10000) completion:^{
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    __block BOOL renderedImageQualityGreater = NO;
    [self.imageManager downloadImageWithURL:[self progressiveURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                              progressImage:^(PINRemoteImageManagerResult * _Nonnull result) {
                                  [self.imageManager cancelTaskWithUUID:result.UUID storeResumeData:YES];
                                  //Wait a second for cancelation.
                                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                      dispatch_semaphore_signal(semaphore);
                                  });
                              }
                                 completion:^(PINRemoteImageManagerResult * _Nonnull result) {
                                     XCTAssert(result.image == nil, @"should not complete download: %@", result);
                                 }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    PINResume *resume = [self.imageManager.cache objectFromDiskForKey:[self.imageManager resumeCacheKeyForURL:[self progressiveURL]]];
    XCTAssert(resume.resumeData.length > 0, @"Resume should have > 0 data length");

    //Shorten resume data to improve reliability of test (expect to get progressive render callback before download completes.
    resume = [PINResume resumeData:[resume.resumeData subdataWithRange:NSMakeRange(0, 10)] ifRange:resume.ifRange totalBytes:resume.totalBytes];
    [self.imageManager.cache setObjectOnDisk:resume forKey:[self.imageManager resumeCacheKeyForURL:[self progressiveURL]]];
    
    [self.imageManager downloadImageWithURL:[self progressiveURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                              progressImage:^(PINRemoteImageManagerResult * _Nonnull result) {
                                  // We expect renderedImageQualitySame to be true because we want an initial progress callback on a resumed
                                  // download. Otherwise, a canceled download which had already rendered progress, may not render progress again
                                  // until completed.
                                  XCTAssert(result.renderedImageQuality + FLT_EPSILON >= ((CGFloat)resume.resumeData.length / resume.totalBytes), @"expected renderedImageQuality (%f) to be greater or equal to progress (%f)", result.renderedImageQuality, (CGFloat)resume.resumeData.length / resume.totalBytes);
                                  renderedImageQualityGreater = YES;
                              }
                                 completion:^(PINRemoteImageManagerResult * _Nonnull result) {
                                     XCTAssert(renderedImageQualityGreater, @"Rendered image quality should non-zero and be greater than resume length. resume data length: %lu total: %lld", (unsigned long)resume.resumeData.length, resume.totalBytes);
                                     XCTAssert(result.image && result.error == nil, @"Image not downloaded");
                                     //Wait a second for disk storage.
                                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                         dispatch_semaphore_signal(semaphore);
                                     });
                                 }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    NSData *resumedImageData = [self.imageManager.cache objectFromDiskForKey:[self.imageManager cacheKeyForURL:[self progressiveURL] processorKey:nil]];
    
    [self.imageManager.cache removeAllObjects];
    
    [self.imageManager downloadImageWithURL:[self progressiveURL] completion:^(PINRemoteImageManagerResult * _Nonnull result) {
        //Wait a second for disk storage.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_signal(semaphore);
        });
    }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    NSData *nonResumedImageData = [self.imageManager.cache objectFromDiskForKey:[self.imageManager cacheKeyForURL:[self progressiveURL] processorKey:nil]];
    
    XCTAssert([nonResumedImageData isEqualToData:resumedImageData], @"Resumed image data and non resumed image data should be the same.");
}

- (void)testResumeSkipCancelation
{
    //Test that images aren't canceled if the cost of resuming is high (i.e. time to first byte is longer than the time left to download)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    PINWeakify(self);
    [self.imageManager setEstimatedRemainingTimeThresholdForProgressiveDownloads:0.001 completion:^{
        PINStrongify(self);
        [self.imageManager setProgressiveRendersMaxProgressiveRenderSize:CGSizeMake(10000, 10000) completion:^{
            dispatch_semaphore_signal(semaphore);
        }];
    }];
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    XCTestExpectation *progressExpectation = [self expectationWithDescription:@"progress is rendered"];
    
    [[PINSpeedRecorder sharedRecorder] updateSpeedsForHost:[[self progressiveURL] host] bytesPerSecond:0 startAdjustedBytesPerSecond:0 timeToFirstByte:0];
    
    __block BOOL canceled = NO;
    [self.imageManager downloadImageWithURL:[self progressiveURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                              progressImage:^(PINRemoteImageManagerResult * _Nonnull result) {
                                  if (canceled == NO) {
                                      canceled = YES;
                                      [self.imageManager cancelTaskWithUUID:result.UUID storeResumeData:YES];
                                      [progressExpectation fulfill];
                                      dispatch_semaphore_signal(semaphore);
                                  }
                              }
                                 completion:^(PINRemoteImageManagerResult * _Nonnull result) {
                                     XCTAssert(result.image == nil, @"should not complete download: %@", result);
                                 }];
    
    dispatch_semaphore_wait(semaphore, [self timeout]);
    
    //Remove any progress
    [self.imageManager.cache removeObjectForKey:[self.imageManager resumeCacheKeyForURL:[self progressiveURL]]];
    
    XCTestExpectation *progress2Expectation = [self expectationWithDescription:@"progress 2 is rendered"];
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"image is completed"];
    
    [[PINSpeedRecorder sharedRecorder] resetMeasurements];
    [[PINSpeedRecorder sharedRecorder] updateSpeedsForHost:[[self progressiveURL] host] bytesPerSecond:100000 startAdjustedBytesPerSecond:100000 timeToFirstByte:10];
    
    canceled = NO;
    [self.imageManager downloadImageWithURL:[self progressiveURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                              progressImage:^(PINRemoteImageManagerResult * _Nonnull result) {
                                  if (canceled == NO) {
                                      canceled = YES;
                                      [self.imageManager cancelTaskWithUUID:result.UUID storeResumeData:YES];
                                      [progress2Expectation fulfill];
                                  }
                              }
                                 completion:^(PINRemoteImageManagerResult * _Nonnull result) {
                                     [completedExpectation fulfill];
                                 }];
    
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

- (void)testRetry
{
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  PINRemoteImageManager *manager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:config];
  
  //Do nasty swizzling to test this
  SEL originalSelector = @selector(scheduleDownloadWithRequest:resume:skipRetry:priority:isRetry:completionHandler:);
  SEL swizzledSelector = @selector(swizzled_scheduleDownloadWithRequest:resume:skipRetry:priority:isRetry:completionHandler:);
  
  Method originalMethod = class_getInstanceMethod([PINRemoteImageDownloadTask class], originalSelector);
  Method swizzledMethod = class_getInstanceMethod([PINRemoteImageDownloadTask class], swizzledSelector);
  
  BOOL added = class_addMethod([PINRemoteImageDownloadTask class], originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
  if (added) {
    class_replaceMethod([PINRemoteImageDownloadTask class], swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
  
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  __block BOOL requestFinished = NO;
  [manager downloadImageWithURL:[self progressiveURL] completion:^(PINRemoteImageManagerResult * _Nonnull result) {
    XCTAssert(result.image && result.error == nil, @"Should not have resulted in an error");
    requestFinished = YES;
    dispatch_semaphore_signal(semaphore);
  }];
  
  dispatch_semaphore_wait(semaphore, [self timeout]);
  
  XCTAssert(requestFinished, @"Request should have finished before timeout");
  XCTAssert(requestRetried, @"Request should have been retried.");
  
  method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)testCancelAllTasks
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel all tasks"];
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self.imageManager downloadImageWithURL:[self progressiveURL2] options:0 progressDownload:^(int64_t completedBytes, int64_t totalBytes) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_group_leave(group);
        });
    } completion:nil];
    
    dispatch_group_enter(group);
    [self.imageManager downloadImageWithURL:[self progressiveURL] options:0 progressDownload:^(int64_t completedBytes, int64_t totalBytes) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_group_leave(group);
        });
    } completion:nil];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        SEL originalSelector = @selector(cancelTaskWithUUID:storeResumeData:);
        SEL swizzledSelector = @selector(swizzled_cancelTaskWithUUID:storeResumeData:);
        
        Method originalMethod = class_getInstanceMethod([PINRemoteImageManager class], originalSelector);
        Method swizzledMethod = class_getInstanceMethod([PINRemoteImageManager class], swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
        [self.imageManager cancelAllTasks];
        
        // Give manager 2 seconds to cancel all tasks
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            XCTAssert(canceledCount == 2);
            [expectation fulfill];
        });
    });
    dispatch_group_wait(group, [self timeout]);
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
}

@end

@implementation PINRemoteImageManager (Swizzled)

- (void)swizzled_cancelTaskWithUUID:(nonnull NSUUID *)UUID storeResumeData:(BOOL)storeResumeData
{
    canceledCount++;
    [self swizzled_cancelTaskWithUUID:UUID storeResumeData:storeResumeData];
}

@end

@implementation PINRemoteImageDownloadTask (Swizzled)

- (void)swizzled_scheduleDownloadWithRequest:(NSURLRequest *)request
                                      resume:(PINResume *)resume
                                   skipRetry:(BOOL)skipRetry
                                    priority:(PINRemoteImageManagerPriority)priority
                                     isRetry:(BOOL)isRetry
                           completionHandler:(PINRemoteImageManagerDataCompletion)completionHandler
{
    static BOOL requestModified = NO;
    NSMutableURLRequest *modifiedRequest = nil;
    if (requestModified == NO) {
      requestModified = YES;
      modifiedRequest = [request mutableCopy];
      [modifiedRequest setTimeoutInterval:0.00001];
    } else {
      modifiedRequest = [request mutableCopy];
      [modifiedRequest setTimeoutInterval:30];
      requestRetried = YES;
    }
    [self swizzled_scheduleDownloadWithRequest:modifiedRequest resume:resume skipRetry:skipRetry priority:priority isRetry:isRetry completionHandler:completionHandler];
}

@end
