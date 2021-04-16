//
//  Oriented.m
//  Example
//
//  Created by Alex Quinlivan on 16/04/21.
//  Copyright © 2021 Garrett Moon. All rights reserved.
//

#import "Oriented.h"

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

@interface NSValue (PINiOSMapping)
+ (NSValue *)valueWithCGSize:(CGSize)size;
- (CGSize)CGSizeValue;
@end

@implementation NSValue (PINiOSMapping)

+ (NSValue *)valueWithCGSize:(CGSize)size
{
    return [self valueWithSize:size];
}

- (CGSize)CGSizeValue
{
    return self.sizeValue;
}

@end

#endif

@implementation Oriented
@synthesize imageURL;
@synthesize dominantColor;
@synthesize imageSize;

+ (void)fetchImagesForWidth:(CGFloat)width completion:(void (^)(NSArray *images))completion
{
    NSArray *orientedURLs = @[[NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_0.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_1.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_2.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_3.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_4.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_5.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_6.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_7.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Landscape_8.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_0.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_1.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_2.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_3.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_4.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_5.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_6.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_7.jpg?raw=true"],
                              [NSURL URLWithString:@"https://github.com/AlexQuinlivan/exif-orientation-examples/blob/master/Portrait_8.jpg?raw=true"],
                              ];
    
    NSArray *orientedSizes = @[[NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(450, 300)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               [NSValue valueWithCGSize:CGSizeMake(300, 450)],
                               ];
  
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *orienteds = [[NSMutableArray alloc] init];
    
    CGFloat scale = 1;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    scale = [[UIScreen mainScreen] scale];
#else
    scale = [[NSScreen mainScreen] backingScaleFactor];
#endif
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger count = 0;
            for (NSInteger idx = 0; idx < 500; idx++) {
                Oriented *oriented = [[Oriented alloc] init];
                CGFloat r = (rand() % 255) / 255.0f;
                CGFloat g = (rand() % 255) / 255.0f;
                CGFloat b = (rand() % 255) / 255.0f;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                oriented.dominantColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
#else
                oriented.dominantColor = [NSColor colorWithRed:r green:g blue:b alpha:1.0f];
#endif
                
                NSUInteger orientedIdx = rand() % 18;
                
                CGSize orientedSize = [orientedSizes[orientedIdx] CGSizeValue];
                NSInteger orientedSizeWidth = orientedSize.width;
                NSInteger orientedSizeHeight = orientedSize.height;
                
                if (orientedSizeWidth > (width * scale)) {
                    orientedSizeHeight = ((width * scale) / orientedSizeWidth) * orientedSizeHeight;
                    orientedSizeWidth = (width * scale);
                }
                
                oriented.imageURL = orientedURLs[orientedIdx];
                oriented.imageSize = CGSizeMake(orientedSizeWidth / scale, orientedSizeHeight / scale);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [orienteds addObject:oriented];
                });
                count++;
            }
        });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(orienteds);
        }
    });
}

@end
