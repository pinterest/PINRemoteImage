//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#if __has_include(<webp/decode.h>)
@import UIKit;

@interface UIImage (WebP)

+ (UIImage *)imageWithWebPData:(NSData *)webPData;

@end
#endif
