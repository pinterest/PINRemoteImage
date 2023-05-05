//
//  ImageSource.h
//  Example
//
//  Created by Alex Quinlivan on 16/04/21.
//  Copyright © 2021 Garrett Moon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ImageSource <NSObject>

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) id dominantColor;
@property (nonatomic, assign) CGSize imageSize;

+ (void)fetchImagesForWidth:(CGFloat)width completion:(void (^)(NSArray *images))completion;

@end

NS_ASSUME_NONNULL_END
