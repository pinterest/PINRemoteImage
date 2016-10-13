//
//  PINViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 08/11/2014.
//  Copyright (c) 2014 Garrett Moon. All rights reserved.
//

#import "PINViewController.h"

#import <PINRemoteImage/PINRemoteImage.h>
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <PINRemoteImage/PINRemoteImageCaching.h>
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImageView.h>
#endif

#import "Kitten.h"

@interface PINViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kittens;

@end

@interface PINImageCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

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

- (void)fetchKittenImages
{
    [Kitten fetchKittenForWidth:CGRectGetWidth(self.collectionView.frame) completion:^(NSArray *kittens) {
        [self.kittens addObjectsFromArray:kittens];
        [self.collectionView reloadData];
    }];
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
    [self fetchKittenImages];
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
