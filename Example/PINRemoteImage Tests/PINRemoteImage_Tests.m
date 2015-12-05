//
//  PINRemoteImage_Tests.m
//  PINRemoteImage Tests
//
//  Created by Garrett Moon on 11/6/14.
//  Copyright (c) 2014 Garrett Moon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <PINRemoteImage/PINRemoteImage.h>
#import <PINRemoteImage/PINURLSessionManager.h>
#import <PINRemoteImage/UIImageView+PINRemoteImage.h>
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif
#import <PINCache/PINCache.h>

#if DEBUG
@interface PINRemoteImageManager ()

@property (nonatomic, strong) PINURLSessionManager *sessionManager;
@property (nonatomic, readonly) NSUInteger totalDownloads;

- (float)currentBytesPerSecond;
- (void)addTaskBPS:(float)bytesPerSecond endDate:(NSDate *)endDate;
- (void)setCurrentBytesPerSecond:(float)currentBPS;

@end

@interface PINURLSessionManager ()

@property (nonatomic, strong) NSURLSession *session;

@end
#endif

@interface PINRemoteImage_Tests : XCTestCase <PINURLSessionManagerDelegate>

@property (nonatomic, strong) PINRemoteImageManager *imageManager;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSError *error;

@end

@implementation PINRemoteImage_Tests

- (NSTimeInterval)timeoutTimeInterval {
    return 10.0;
}

- (dispatch_time_t)timeoutWithInterval:(NSTimeInterval)interval {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
}

- (dispatch_time_t)timeout {
    return [self timeoutWithInterval:[self timeoutTimeInterval]];
}

- (NSURL *)GIFURL
{
    return [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/originals/90/f5/77/90f577fc6abcd24f9a5f9f55b2d7482b.jpg"];
}

- (NSURL *)emptyURL
{
    return [NSURL URLWithString:@""];
}

- (NSURL *)fourZeroFourURL
{
    return [NSURL URLWithString:@"https://www.pinterest.com/404/"];
}

- (NSURL *)headersURL
{
    return [NSURL URLWithString:@"https://httpbin.org/headers"];
}

- (NSURL *)JPEGURL_Small
{
    return [NSURL URLWithString:@"https://media-cache-ec0.pinimg.com/345x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"];
}

- (NSURL *)JPEGURL_Medium
{
    return [NSURL URLWithString:@"https://media-cache-ec0.pinimg.com/600x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"];
}

- (NSURL *)JPEGURL_Large
{
    return [NSURL URLWithString:@"https://media-cache-ec0.pinimg.com/750x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"];
}

- (NSURL *)JPEGURL
{
    return [self JPEGURL_Medium];
}

- (NSURL *)nonTransparentWebPURL
{
    return [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/5.webp"];
}

- (NSURL *)transparentWebPURL
{
    return [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery3/4_webp_ll.webp"];
}

#pragma mark - <PINURLSessionManagerDelegate>

- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionTask *)task
{
    self.data = data;
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
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    //clear disk cache
    [self.imageManager.cache.diskCache removeAllObjects];
    self.imageManager = nil;
    [super tearDown];
}

#if USE_FLANIMATED_IMAGE
- (void)testGIFDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FLAnimatedImage *outAnimatedImage = nil;
    __block UIImage *outImage = nil;
    [self.imageManager downloadImageWithURL:[self GIFURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        outImage = result.image;
        outAnimatedImage = result.animatedImage;
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert(outAnimatedImage && [outAnimatedImage isKindOfClass:[FLAnimatedImage class]], @"Failed downloading animatedImage or animatedImage is not an FLAnimatedImage.");
    XCTAssert(outImage == nil, @"Image is not nil.");
}
#endif

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

- (void)testCustomHeaderIsAddedToImageRequests
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{ @"X-Custom-Header" : @"Custom Header Value" };
    self.imageManager = [[PINRemoteImageManager alloc] initWithSessionConfiguration:configuration];
    self.imageManager.sessionManager.delegate = self;
    [self.imageManager downloadImageWithURL:[self headersURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    NSDictionary *headers = [[NSJSONSerialization JSONObjectWithData:self.data options:NSJSONReadingMutableContainers error:nil] valueForKey:@"headers"];
    XCTAssert([headers[@"X-Custom-Header"] isEqualToString:@"Custom Header Value"]);
}

- (void)testSkipFLAnimatedImageDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FLAnimatedImage *outAnimatedImage = nil;
    __block UIImage *outImage = nil;
    [self.imageManager downloadImageWithURL:[self GIFURL]
                                    options:PINRemoteImageManagerDownloadOptionsIgnoreGIFs
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        outImage = result.image;
        outAnimatedImage = result.animatedImage;
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
    XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
}

- (void)testJPEGDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FLAnimatedImage *outAnimatedImage = nil;
    __block UIImage *outImage = nil;
    [self.imageManager downloadImageWithURL:[self JPEGURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        outImage = result.image;
        outAnimatedImage = result.animatedImage;
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
    XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
}

- (void)testErrorOnNilURLDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *outError = nil;
    [self.imageManager downloadImageWithURL:nil
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         outError = result.error;
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert([outError.domain isEqualToString:NSURLErrorDomain]);
    XCTAssert(outError.code == NSURLErrorUnsupportedURL);
    XCTAssert([outError.localizedDescription isEqualToString:@"unsupported URL"]);
}

- (void)testErrorOnEmptyURLDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *outError = nil;
    [self.imageManager downloadImageWithURL:[self emptyURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         outError = result.error;
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert([outError.domain isEqualToString:NSURLErrorDomain]);
    XCTAssert(outError.code == NSURLErrorUnsupportedURL);
    // iOS8 (and presumably 10.10) returns NSURLErrorUnsupportedURL which means the HTTP NSURLProtocol does not accept it
    NSArray *validErrorMessages = @[ @"unsupported URL", @"The operation couldn’t be completed. (NSURLErrorDomain error -1002.)"];
    XCTAssert([validErrorMessages containsObject:outError.localizedDescription], @"%@", outError.localizedDescription);
}

- (void)testErrorOn404Response
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *outError = nil;
    [self.imageManager downloadImageWithURL:[self fourZeroFourURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         outError = result.error;
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert([outError.domain isEqualToString:NSURLErrorDomain]);
    XCTAssert(outError.code == NSURLErrorRedirectToNonExistentLocation);
    XCTAssert([outError.localizedDescription isEqualToString:@"The requested URL was not found on this server."]);
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
        if ([[self.imageManager cache] objectForKey:key] != nil) {
            break;
        }
        sleep(50);
    }
}

- (void)testTransparentWebPDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FLAnimatedImage *outAnimatedImage = nil;
    __block UIImage *outImage = nil;
    [self.imageManager downloadImageWithURL:[self transparentWebPURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        XCTAssert(result.error == nil, @"error is non-nil: %@", result.error);
        outImage = result.image;
        outAnimatedImage = result.animatedImage;
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(outImage.CGImage);
    BOOL opaque = alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst || alphaInfo == kCGImageAlphaNoneSkipLast;
    XCTAssert(opaque == NO, @"transparent WebP image is opaque.");
    XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
}

- (void)testNonTransparentWebPDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block FLAnimatedImage *outAnimatedImage = nil;
    __block UIImage *outImage = nil;
    [self.imageManager downloadImageWithURL:[self nonTransparentWebPURL]
                                    options:PINRemoteImageManagerDownloadOptionsNone
                                 completion:^(PINRemoteImageManagerResult *result)
    {
        outImage = result.image;
        outAnimatedImage = result.animatedImage;
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert(outImage && [outImage isKindOfClass:[UIImage class]], @"Failed downloading image or image is not a UIImage.");
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(outImage.CGImage);
    BOOL opaque = alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipFirst || alphaInfo == kCGImageAlphaNoneSkipLast;
    XCTAssert(opaque == YES, @"non transparent WebP image is not opaque.");
    XCTAssert(outAnimatedImage == nil, @"Animated image is not nil.");
}

- (void)testCancelDownload
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSUUID *downloadUUID = [self.imageManager downloadImageWithURL:[self JPEGURL]
                                                           options:PINRemoteImageManagerDownloadOptionsNone
                                                        completion:^(PINRemoteImageManagerResult *result)
    {
        XCTAssert(NO, @"Download should have been canceled and callback should not have been called.");
        dispatch_semaphore_signal(semaphore);
    }];
    [self.imageManager cancelTaskWithUUID:downloadUUID];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) != 0, @"Semaphore should time out.");
    XCTAssert(self.imageManager.totalDownloads == 0, @"image downloaded too many times");
}

- (void)testPrefetchImage
{
    id object = [[self.imageManager cache] objectForKey:[self.imageManager cacheKeyForURL:[self JPEGURL] processorKey:nil]];
    XCTAssert(object == nil, @"image should not be in cache");
    
    [self.imageManager prefetchImageWithURL:[self JPEGURL]];
    sleep([self timeoutTimeInterval]);
    
    object = [[self.imageManager cache] objectForKey:[self.imageManager cacheKeyForURL:[self JPEGURL] processorKey:nil]];
    XCTAssert(object, @"image was not prefetched or was not stored in cache");
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

    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:NULL];
}

#if USE_FLANIMATED_IMAGE
- (void)testFLAnimatedImageView
{
    XCTestExpectation *imageSetExpectation = [self expectationWithDescription:@"animatedImageView did not have animated image set"];
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
    __weak FLAnimatedImageView *weakImageView = imageView;
    [imageView pin_setImageFromURL:[self GIFURL]
                        completion:^(PINRemoteImageManagerResult *result)
     {
         if (weakImageView.animatedImage)
             [imageSetExpectation fulfill];
     }];

    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:NULL];
}
#endif

- (void)testEarlyReturn {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
        dispatch_semaphore_signal(semaphore);
    }];
    
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    // callback can occur *before* image is stored in cache this is an optimization to avoid waiting on the cache to write.
    // So, wait until it's actually in the cache.
    [self waitForImageWithURLToBeCached:[self JPEGURL]];
    
    __block UIImage *image = nil;
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
        image = result.image;
    }];
    XCTAssert(image != nil, @"image callback did not occur synchronously.");
}

#if USE_FLANIMATED_IMAGE
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
            XCTAssert((result.image && !result.animatedImage) || (result.animatedImage && !result.image), @"image or animatedImage not downloaded");
            if (rand() % 2) {
                [[self.imageManager cache] removeObjectForKey:[self.imageManager cacheKeyForURL:url processorKey:nil]];
            }
            dispatch_group_leave(group);
        }];
    }
    XCTAssert(dispatch_group_wait(group, [self timeoutWithInterval:100]) == 0, @"Group timed out.");
}
#endif

- (void)testInvalidObject
{
    [self.imageManager.cache setObject:@"invalid" forKey:[self.imageManager cacheKeyForURL:[self JPEGURL] processorKey:nil]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block UIImage *image = nil;
    [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
        image = result.image;
        dispatch_semaphore_signal(semaphore);
    }];
    
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    XCTAssert([image isKindOfClass:[UIImage class]], @"image should be UIImage");
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
             dispatch_group_leave(group);
             XCTAssert([image isKindOfClass:[UIImage class]] && image == processedImage, @"result image is not a UIImage");
         }];
    }
    
    XCTAssert(dispatch_group_wait(group, [self timeout]) == 0, @"Group timed out.");
    
    XCTAssert(processCount <= 1, @"image processed too many times");
    XCTAssert([image isKindOfClass:[UIImage class]], @"result image is not a UIImage");
}

- (void)testProcessingCancel
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSUUID *processUUID = [self.imageManager downloadImageWithURL:[self JPEGURL] options:PINRemoteImageManagerDownloadOptionsNone
                                                     processorKey:@"process"
                                                        processor:^UIImage *(PINRemoteImageManagerResult *result, NSUInteger *cost)
     {
         XCTAssert(NO, @"Process should have been canceled and callback should not have been called.");
         return nil;
     }
                                 completion:^(PINRemoteImageManagerResult *result)
     {
         XCTAssert(NO, @"Process should have been canceled and callback should not have been called.");
         dispatch_semaphore_signal(semaphore);
     }];

    [self.imageManager cancelTaskWithUUID:processUUID];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) != 0, @"Semaphore should time out.");
    XCTAssert(self.imageManager.totalDownloads == 0, @"image should not have been downloaded either.");
}

- (void)testNumberDownloads
{
    dispatch_group_t group = dispatch_group_create();
    
    __block UIImage *image = nil;
    const NSUInteger numIntervals = 1000;

    for (NSUInteger idx = 0; idx < numIntervals; idx++) {
        dispatch_group_enter(group);
        [self.imageManager downloadImageWithURL:[self JPEGURL] completion:^(PINRemoteImageManagerResult *result) {
            dispatch_group_leave(group);
            XCTAssert([result.image isKindOfClass:[UIImage class]], @"result image is not a UIImage");
            image = result.image;
        }];
    }
    
    XCTAssert(dispatch_group_wait(group, [self timeout]) == 0, @"Group timed out.");
    
    XCTAssert(self.imageManager.totalDownloads <= 1, @"image downloaded too many times");
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
    XCTestExpectation *finishExpectation = [self expectationWithDescription:@"Finished testing off the main thread."];
    //currentBytesPerSecond is not public, should not be called on the main queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssert([self.imageManager currentBytesPerSecond] == -1, @"Without any tasks added, should be -1");
        [self.imageManager addTaskBPS:100 endDate:[NSDate dateWithTimeIntervalSinceNow:-61]];
        XCTAssert([self.imageManager currentBytesPerSecond] == -1, @"With only old task, should be -1");
        [self.imageManager addTaskBPS:100 endDate:[NSDate date]];
        XCTAssert([self isFloat:[self.imageManager currentBytesPerSecond] equalToFloat:100.0f], @"One task should be same as added task");
        [self.imageManager addTaskBPS:50 endDate:[NSDate dateWithTimeIntervalSinceNow:-30]];
        XCTAssert([self isFloat:[self.imageManager currentBytesPerSecond] equalToFloat:75.0f], @"Two tasks should be average of both tasks");
        [self.imageManager addTaskBPS:100 endDate:[NSDate dateWithTimeIntervalSinceNow:-61]];
        XCTAssert([self isFloat:[self.imageManager currentBytesPerSecond] equalToFloat:75.0f], @"Old task shouldn't be counted");
        [self.imageManager addTaskBPS:50 endDate:[NSDate date]];
        [self.imageManager addTaskBPS:50 endDate:[NSDate date]];
        [self.imageManager addTaskBPS:50 endDate:[NSDate date]];
        [self.imageManager addTaskBPS:50 endDate:[NSDate date]];
        [self.imageManager addTaskBPS:50 endDate:[NSDate date]];
        XCTAssert([self isFloat:[self.imageManager currentBytesPerSecond] equalToFloat:50.0f], @"Only last 5 tasks should be used");
        [finishExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:[self timeoutTimeInterval] handler:nil];
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
                                    progress:nil
                                  completion:^(PINRemoteImageManagerResult *result)
    {
        image = result.image;
        XCTAssert(image.size.width == 750, @"Large image should be downloaded");
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    // callback can occur *before* image is stored in cache this is an optimization to avoid waiting on the cache to write.
    // So, wait until it's actually in the cache.
    [self waitForImageWithURLToBeCached:[self JPEGURL_Large]];
    
    [self.imageManager setCurrentBytesPerSecond:5];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                                    progress:nil
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
                                    progress:nil
                                  completion:^(PINRemoteImageManagerResult *result)
    {
        image = result.image;
        XCTAssert(image.size.width == 345, @"Small image should be downloaded at low bps");
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [self waitForImageWithURLToBeCached:[self JPEGURL_Small]];
    
    [self.imageManager setCurrentBytesPerSecond:100];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                                    progress:nil
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
    
    [self.imageManager setCurrentBytesPerSecond:7];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Medium], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                                    progress:nil
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
        if ([[self.imageManager cache] objectForKey:key] == nil) {
            break;
        }
        sleep(50);
    }
    XCTAssert([[self.imageManager cache] objectForKey:[self.imageManager cacheKeyForURL:[self JPEGURL_Small] processorKey:nil]] == nil, @"Small image should have been removed from cache");
    
    [self.imageManager.cache removeAllObjects];
    [self.imageManager setShouldUpgradeLowQualityImages:NO completion:^{
        dispatch_semaphore_signal(semaphore);
    }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
    
    [self.imageManager setCurrentBytesPerSecond:7];
    [self.imageManager downloadImageWithURLs:@[[self JPEGURL_Small], [self JPEGURL_Large]]
                                     options:PINRemoteImageManagerDownloadOptionsNone
                                    progress:nil
                                  completion:^(PINRemoteImageManagerResult *result)
     {
         image = result.image;
         XCTAssert(image.size.width == 345, @"Small image should be now downloaded");
         dispatch_semaphore_signal(semaphore);
     }];
    XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
}

- (void)testAuthentication {
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	__block BOOL didCallAuthenticationChallenge = NO;
	
	[self.imageManager setAuthenticationChallenge:^(NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, PINRemoteImageManagerAuthenticationChallengeCompletionHandler aHandler) {
		didCallAuthenticationChallenge = YES;
		aHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
		dispatch_semaphore_signal(semaphore);
		
	}];
	
	[self.imageManager downloadImageWithURL: [NSURL URLWithString:@"https://media-cache-ec0.pinimg.com/600x/1b/bc/c2/1bbcc264683171eb3815292d2f546e92.jpg"]
									options:PINRemoteImageManagerDownloadOptionsNone
								 completion:nil];
	
	XCTAssert(dispatch_semaphore_wait(semaphore, [self timeout]) == 0, @"Semaphore timed out.");
	
	XCTAssert(didCallAuthenticationChallenge, @"Did not call authenticationchallenge.");
}

@end
