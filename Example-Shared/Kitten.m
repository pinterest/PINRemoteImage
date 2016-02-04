//
//  Kitten.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "Kitten.h"

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


@implementation Kitten

+ (void)fetchKittenForWidth:(CGFloat)width completion:(void (^)(NSArray *kittens))completion
{
    NSArray *kittenURLs = @[[NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/92/5d/5a/925d5ac74db0dcfabc238e1686e31d16.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/ff/b3/ae/ffb3ae40533b7f9463cf1c04d7ab69d1.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/e4/b7/7c/e4b77ca06e1d4a401b1a49d7fadd90d9.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/46/e1/59/46e159d76b167ed9211d662f95e7bf6f.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/7a/72/77/7a72779329942c06f888c148eb8d7e34.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/60/21/8f/60218ff43257fb3b6d7c5b888f74a5bf.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/90/e8/e4/90e8e47d53e71e0d97691dd13a5617fb.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/96/ae/31/96ae31fbc52d96dd3308d2754a6ca37e.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/9b/7b/99/9b7b99ff63be31bba8f9863724b3ebbc.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/80/23/51/802351d953dd2a8b232d0da1c7ca6880.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/f5/c4/f0/f5c4f04fa2686338dc3b08420d198484.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/2b/06/4f/2b064f3e0af984a556ac94b251ff7060.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/17/1f/c0/171fc02398143269d8a507a15563166a.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/8a/35/33/8a35338bbf67c86a198ba2dd926edd82.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/4d/6e/3c/4d6e3cf970031116c57486e85c2a4cab.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/54/25/ee/5425eeccba78731cf7be70f0b8808bd2.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/04/f1/3f/04f13fdb7580dcbe8c4d6b7d5a0a5ec2.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/dc/16/4e/dc164ed33af9d899e5ed188e642f00e9.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/c1/06/13/c106132936189b6cb654671f2a2183ed.jpg"],
                            [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/46/43/ed/4643eda4e1be4273721a76a370b90346.jpg"],
                            ];
    
    NSArray *kittenSizes = @[[NSValue valueWithCGSize:CGSizeMake(503, 992)],
                             [NSValue valueWithCGSize:CGSizeMake(500, 337)],
                             [NSValue valueWithCGSize:CGSizeMake(522, 695)],
                             [NSValue valueWithCGSize:CGSizeMake(557, 749)],
                             [NSValue valueWithCGSize:CGSizeMake(710, 1069)],
                             [NSValue valueWithCGSize:CGSizeMake(522, 676)],
                             [NSValue valueWithCGSize:CGSizeMake(500, 688)],
                             [NSValue valueWithCGSize:CGSizeMake(377, 700)],
                             [NSValue valueWithCGSize:CGSizeMake(334, 494)],
                             [NSValue valueWithCGSize:CGSizeMake(625, 469)],
                             [NSValue valueWithCGSize:CGSizeMake(625, 833)],
                             [NSValue valueWithCGSize:CGSizeMake(625, 469)],
                             [NSValue valueWithCGSize:CGSizeMake(625, 469)],
                             [NSValue valueWithCGSize:CGSizeMake(625, 791)],
                             [NSValue valueWithCGSize:CGSizeMake(625, 833)],
                             [NSValue valueWithCGSize:CGSizeMake(605, 605)],
                             [NSValue valueWithCGSize:CGSizeMake(504, 750)],
                             [NSValue valueWithCGSize:CGSizeMake(500, 500)],
                             [NSValue valueWithCGSize:CGSizeMake(640, 640)],
                             [NSValue valueWithCGSize:CGSizeMake(500, 473)],
                             ];
  
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *kittens = [[NSMutableArray alloc] init];
    
    CGFloat scale = 1;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    scale = [[UIScreen mainScreen] scale];
#else
    scale = [[NSScreen mainScreen] backingScaleFactor];
#endif
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger count = 0;
            for (NSInteger idx = 0; idx < 500; idx++) {
                Kitten *kitten = [[Kitten alloc] init];
                CGFloat r = (rand() % 255) / 255.0f;
                CGFloat g = (rand() % 255) / 255.0f;
                CGFloat b = (rand() % 255) / 255.0f;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                kitten.dominantColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
#else
                kitten.dominantColor = [NSColor colorWithRed:r green:g blue:b alpha:1.0f];
#endif
                
                NSUInteger kittenIdx = rand() % 20;
                
                CGSize kittenSize = [kittenSizes[kittenIdx] CGSizeValue];
                NSInteger kittenSizeWidth = kittenSize.width;
                NSInteger kittenSizeHeight = kittenSize.height;
                
                if (kittenSizeWidth > (width * scale)) {
                    kittenSizeHeight = ((width * scale) / kittenSizeWidth) * kittenSizeHeight;
                    kittenSizeWidth = (width * scale);
                }
                
                kitten.imageURL = kittenURLs[kittenIdx];
                kitten.imageSize = CGSizeMake(kittenSizeWidth / scale, kittenSizeHeight / scale);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [kittens addObject:kitten];
                });
                count++;
            }
        });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(kittens);
        }
    });
}

@end
