//
//  PINViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 08/11/2014.
//  Copyright (c) 2014 Garrett Moon. All rights reserved.
//

#import "PINViewController.h"

#import <PINRemoteImage/UIImageView+PINRemoteImage.h>
#import <PINCache/PINCache.h>
#import <FLAnimatedImage/FLAnimatedImageView.h>

@interface PINViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kittens;

@end

@interface PINImageCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@interface Kitten : NSObject

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIColor *dominantColor;
@property (nonatomic, assign) CGSize imageSize;

@end

@implementation PINViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    srand([[NSDate date] timeIntervalSince1970]);
    if (self = [super initWithCoder:aDecoder]) {
        [[[PINRemoteImageManager sharedImageManager] cache] removeAllObjects];
    }
    return self;
}

- (void)addImages
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
    CGRect bounds = self.collectionView.bounds;
    NSMutableArray *tmpKittens = [[NSMutableArray alloc] init];
        CGFloat scale = [[UIScreen mainScreen] scale];
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger count = 0;
            for (NSInteger idx = 0; idx < 500; idx++) {
                Kitten *kitten = [[Kitten alloc] init];
                CGFloat r = (rand() % 255) / 255.0f;
                CGFloat g = (rand() % 255) / 255.0f;
                CGFloat b = (rand() % 255) / 255.0f;
                kitten.dominantColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0f];
                
                NSUInteger kittenIdx = rand() % 20;
                
                CGSize size = [kittenSizes[kittenIdx] CGSizeValue];
                NSInteger width = size.width;
                NSInteger height = size.height;
                
                if (width > (bounds.size.width * scale)) {
                    height = ((bounds.size.width * scale) / width) * height;
                    width = (bounds.size.width * scale);
                }
                
                kitten.imageURL = kittenURLs[kittenIdx];
                kitten.imageSize = CGSizeMake(width / scale, height / scale);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [tmpKittens addObject:kitten];
                });
                count++;
            }
        });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.kittens addObjectsFromArray:tmpKittens];
        [self.collectionView reloadData];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[PINImageCell class] forCellWithReuseIdentifier:NSStringFromClass([PINImageCell class])];
    [self.view addSubview:self.collectionView];
    
    self.kittens = [[NSMutableArray alloc] init];
    [self addImages];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
    return kitten.imageSize;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.kittens.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PINImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PINImageCell class]) forIndexPath:indexPath];
    Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
    cell.backgroundColor = kitten.dominantColor;
    cell.imageView.alpha = 0.0f;
    __weak PINImageCell *weakCell = cell;
    
    [cell.imageView pin_setImageFromURL:kitten.imageURL
                             completion:^(PINRemoteImageManagerResult *result) {
                                 if (result.requestDuration > 0.25) {
                                     [UIView animateWithDuration:0.3 animations:^{
                                         weakCell.imageView.alpha = 1.0f;
                                     }];
                                 } else {
                                     weakCell.imageView.alpha = 1.0f;
                                 }
                             }];
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

@implementation PINImageCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = 7.0f;
        self.layer.masksToBounds = YES;
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)prepareForReuse
{
    self.imageView.image = nil;
}

@end

@implementation Kitten

@end