//
//  PINRemoteImageDataConvertible.h
//  PINRemoteImage
//
//  Created by Andy Finnell on 5/23/24.
//  Copyright © 2024 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Protocol for describing a class that convert into image data.
 */
@protocol PINRemoteImageDataConvertible

@property (nonatomic, readonly) NSData *data;

@end
