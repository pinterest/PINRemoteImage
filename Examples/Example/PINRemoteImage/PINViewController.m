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

#import "ImageSource.h"
#import "Kitten.h"
#import "Oriented.h"

@interface PINViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *images;

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
    [Kitten fetchImagesForWidth:CGRectGetWidth(self.collectionView.frame) completion:^(NSArray *kittens) {
        [self.images removeAllObjects];
        [self.images addObjectsFromArray:kittens];
        [self.collectionView reloadData];
    }];
}

- (void)fetchOrientedImages
{
    [Oriented fetchImagesForWidth:CGRectGetWidth(self.collectionView.frame) completion:^(NSArray *oriented) {
        [self.images removeAllObjects];
        [self.images addObjectsFromArray:oriented];
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
    
    self.images = [[NSMutableArray alloc] init];
    [self fetchOrientedImages];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<ImageSource> image = [self.images objectAtIndex:indexPath.item];
    return image.imageSize;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PINImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PINImageCell class]) forIndexPath:indexPath];
    id<ImageSource> image = [self.images objectAtIndex:indexPath.item];
    cell.backgroundColor = image.dominantColor;
    cell.imageView.alpha = 0.0f;
    __weak PINImageCell *weakCell = cell;
    
    [cell.imageView pin_setImageFromURL:image.imageURL
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
    [super prepareForReuse];
    self.imageView.image = nil;
}

@end
