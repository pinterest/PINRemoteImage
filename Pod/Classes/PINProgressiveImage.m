//
//  PINProgressiveImage.m
//  Pods
//
//  Created by Garrett Moon on 2/9/15.
//
//

#import "PINProgressiveImage.h"

#import <ImageIO/ImageIO.h>
#import <CoreImage/CoreImage.h>

#import "PINRemoteImage.h"
#import "UIImage+DecodedImage.h"

@interface PINProgressiveImage ()

@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, assign) int64_t expectedNumberOfBytes;
@property (nonatomic, assign) CGImageSourceRef imageSource;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) BOOL isProgressiveJPEG;
@property (nonatomic, strong) UIImage *cachedImage;
@property (nonatomic, assign) NSUInteger currentThreshold;
@property (nonatomic, assign) float bytesPerSecond;
@property (nonatomic, strong) CIContext *processingContext;
@property (nonatomic, strong) CIFilter *gaussianFilter;
@property (nonatomic, assign) NSUInteger scannedByte;
@property (nonatomic, assign) NSInteger sosCount;
@property (nonatomic, strong) NSLock *lock;
#if DEBUG
@property (nonatomic, assign) CFTimeInterval scanTime;
#endif

@property (nonatomic, assign) BOOL inBackground;

@end

@implementation PINProgressiveImage

@synthesize progressThresholds = _progressThresholds;
@synthesize estimatedRemainingTimeThreshold = _estimatedRemainingTimeThreshold;
@synthesize startTime = _startTime;

- (instancetype)init
{
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
        self.lock.name = @"PINProgressiveImage";
        
        _imageSource = CGImageSourceCreateIncremental(NULL);;
        self.size = CGSizeZero;
        self.isProgressiveJPEG = NO;
        self.currentThreshold = 0;
        self.progressThresholds = @[@0.00, @0.35, @0.65];
        self.startTime = CACurrentMediaTime();
        self.estimatedRemainingTimeThreshold = -1;
        self.sosCount = 0;
        self.scannedByte = 0;
#if DEBUG
        self.scanTime = 0;
#endif
        
#if PIN_APP_EXTENSIONS
        self.inBackground = YES;
#else
        self.inBackground = [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
    }
    return self;
}

- (void)dealloc
{
    [self.lock lock];
        self.processingContext = nil;
        if (self.imageSource) {
            CFRelease(_imageSource);
        }
    [self.lock unlock];
#if !PIN_APP_EXTENSIONS
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
}

#pragma mark - NSNotifications

- (void)willResignActive:(NSNotification *)notification
{
    [self.lock lock];
        self.inBackground = YES;
        self.processingContext = nil;
    [self.lock unlock];
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self.lock lock];
        self.inBackground = NO;
    [self.lock unlock];
}

#pragma mark - public

- (void)setProgressThresholds:(NSArray *)progressThresholds
{
    [self.lock lock];
        _progressThresholds = [progressThresholds copy];
    [self.lock unlock];
}

- (NSArray *)progressThresholds
{
    [self.lock lock];
        NSArray *progressThresholds = _progressThresholds;
    [self.lock unlock];
    return progressThresholds;
}

- (void)setEstimatedRemainingTimeThreshold:(CFTimeInterval)estimatedRemainingTimeThreshold
{
    [self.lock lock];
        _estimatedRemainingTimeThreshold = estimatedRemainingTimeThreshold;
    [self.lock unlock];
}

- (CFTimeInterval)estimatedRemainingTimeThreshold
{
    [self.lock lock];
        CFTimeInterval estimatedRemainingTimeThreshold = _estimatedRemainingTimeThreshold;
    [self.lock unlock];
    return estimatedRemainingTimeThreshold;
}

- (void)setStartTime:(CFTimeInterval)startTime
{
    [self.lock lock];
        _startTime = startTime;
    [self.lock unlock];
}

- (CFTimeInterval)startTime
{
    [self.lock lock];
        CFTimeInterval startTime = _startTime;
    [self.lock unlock];
    return startTime;
}

- (void)updateProgressiveImageWithData:(NSData *)data expectedNumberOfBytes:(int64_t)expectedNumberOfBytes
{
    [self.lock lock];
        if (self.mutableData == nil) {
            NSUInteger bytesToAlloc = 0;
            if (expectedNumberOfBytes > 0) {
                bytesToAlloc = (NSUInteger)expectedNumberOfBytes;
            }
            self.mutableData = [[NSMutableData alloc] initWithCapacity:bytesToAlloc];
            self.expectedNumberOfBytes = expectedNumberOfBytes;
        }
        [self.mutableData appendData:data];
        
        while ([self hasCompletedFirstScan] == NO && self.scannedByte < self.mutableData.length) {
    #if DEBUG
            CFTimeInterval start = CACurrentMediaTime();
    #endif
            NSUInteger startByte = self.scannedByte;
            if (startByte > 0) {
                startByte--;
            }
            if ([self scanForSOSinData:self.mutableData startByte:startByte scannedByte:&_scannedByte]) {
                self.sosCount++;
            }
    #if DEBUG
            CFTimeInterval total = CACurrentMediaTime() - start;
            self.scanTime += total;
    #endif
        }
        
        if (self.imageSource) {
            CGImageSourceUpdateData(self.imageSource, (CFDataRef)self.mutableData, NO);
        }
    [self.lock unlock];
}

- (UIImage *)currentImage
{
    [self.lock lock];
        if (self.imageSource == nil) {
            [self.lock unlock];
            return nil;
        }
        
        if (self.currentThreshold == _progressThresholds.count) {
            [self.lock unlock];
            return nil;
        }
        
        if (_estimatedRemainingTimeThreshold < 0 || self.estimatedRemainingTime < _estimatedRemainingTimeThreshold) {
            [self.lock unlock];
            return nil;
        }
        
        if ([self hasCompletedFirstScan] == NO) {
            [self.lock unlock];
            return nil;
        }
        
    #if DEBUG
        if (self.scanTime > 0) {
            PINLog(@"scan time: %f", self.scanTime);
            self.scanTime = 0;
        }
    #endif
        
        UIImage *currentImage = nil;
        
        //Size information comes after JFIF so jpeg properties should be available at or before size?
        if (self.size.width <= 0 || self.size.height <= 0) {
            //attempt to get size info
            NSDictionary *imageProperties = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(self.imageSource, 0, NULL));
            CGSize size = self.size;
            if (size.width <= 0 && imageProperties[(NSString *)kCGImagePropertyPixelWidth]) {
                size.width = [imageProperties[(NSString *)kCGImagePropertyPixelWidth] floatValue];
            }
            
            if (size.height <= 0 && imageProperties[(NSString *)kCGImagePropertyPixelHeight]) {
                size.height = [imageProperties[(NSString *)kCGImagePropertyPixelHeight] floatValue];
            }
            
            self.size = size;
            
            NSDictionary *jpegProperties = imageProperties[(NSString *)kCGImagePropertyJFIFDictionary];
            NSNumber *isProgressive = jpegProperties[(NSString *)kCGImagePropertyJFIFIsProgressive];
            self.isProgressiveJPEG = jpegProperties && [isProgressive boolValue];
        }
        
        float progress = 0;
        if (self.expectedNumberOfBytes > 0) {
            progress = (float)self.mutableData.length / (float)self.expectedNumberOfBytes;
        }
        
        //Don't bother if we're basically done
        if (progress >= 0.99) {
            [self.lock unlock];
            return nil;
        }
    
        if (self.isProgressiveJPEG && self.size.width > 0 && self.size.height > 0 && progress > [_progressThresholds[self.currentThreshold] floatValue]) {
            while (self.currentThreshold < _progressThresholds.count && progress > [_progressThresholds[self.currentThreshold] floatValue]) {
                self.currentThreshold++;
            }
            PINLog(@"Generating preview image");
            CGImageRef image = CGImageSourceCreateImageAtIndex(self.imageSource, 0, NULL);
            if (image) {
                currentImage = [self postProcessImage:[UIImage imageWithCGImage:image] withProgress:progress];
                CGImageRelease(image);
            }
        }
    
    [self.lock unlock];
    return currentImage;
}

- (NSData *)data
{
    [self.lock lock];
    NSData *data = [self.mutableData copy];
    [self.lock unlock];
    return data;
}

#pragma mark - private

//Must be called within lock
- (BOOL)scanForSOSinData:(NSData *)data startByte:(NSUInteger)startByte scannedByte:(NSUInteger *)scannedByte
{
    //check if we have a complete scan
    Byte scanMarker[2];
    //SOS marker
    scanMarker[0] = 0xFF;
    scanMarker[1] = 0xDA;
    
    //scan one byte back in case we only got half the SOS on the last data append
    NSRange scanRange;
    scanRange.location = startByte;
    scanRange.length = data.length - scanRange.location;
    NSRange sosRange = [data rangeOfData:[NSData dataWithBytes:scanMarker length:2] options:0 range:scanRange];
    if (sosRange.location != NSNotFound) {
        if (scannedByte) {
            *scannedByte = NSMaxRange(sosRange);
        }
        return YES;
    }
    if (scannedByte) {
        *scannedByte = NSMaxRange(scanRange);
    }
    return NO;
}

//Must be called within lock
- (BOOL)hasCompletedFirstScan
{
    return self.sosCount >= 2;
}

//Must be called within lock
- (float)bytesPerSecond
{
    CFTimeInterval length = CACurrentMediaTime() - _startTime;
    return self.mutableData.length / length;
}

//Must be called within lock
- (CFTimeInterval)estimatedRemainingTime
{
    if (self.expectedNumberOfBytes < 0) {
        return MAXFLOAT;
    }
    
    NSUInteger remainingBytes = (NSUInteger)self.expectedNumberOfBytes - self.mutableData.length;
    if (remainingBytes == 0) {
        return 0;
    }
    
    float bytesPerSecond = self.bytesPerSecond;
    if (bytesPerSecond == 0) {
        return MAXFLOAT;
    }
    return remainingBytes / self.bytesPerSecond;
}

//Must be called within lock
- (UIImage *)postProcessImage:(UIImage *)inputImage withProgress:(float)progress
{
    if (self.processingContext == nil) {
        self.processingContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(self.inBackground), kCIContextPriorityRequestLow: @YES}];
    }
    
    if (self.gaussianFilter == nil) {
        self.gaussianFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [self.gaussianFilter setDefaults];
    }
    
    UIImage *outputUIImage = nil;
    if (self.processingContext && self.gaussianFilter) {
        [self.gaussianFilter setValue:[CIImage imageWithCGImage:inputImage.CGImage]
                               forKey:kCIInputImageKey];
        
        CGFloat radius = inputImage.size.width / 50.0;
        radius = radius * MAX(0, 1.0 - progress);
        [self.gaussianFilter setValue:[NSNumber numberWithFloat:radius]
                               forKey:kCIInputRadiusKey];
        
        CIImage *outputImage = [self.gaussianFilter outputImage];
        if (outputImage) {
            CGImageRef outputImageRef = [self.processingContext createCGImage:outputImage fromRect:CGRectMake(0, 0, inputImage.size.width, inputImage.size.height)];
            
            if (outputImageRef) {
                //"decoding" the image here copies it to CPU memory?
                outputUIImage = [UIImage pin_decodedImageWithCGImageRef:outputImageRef];
                CGImageRelease(outputImageRef);
            }
        }
    }
    
    if (outputUIImage == nil) {
        outputUIImage = inputImage;
    }
    
    return outputUIImage;
}

@end
