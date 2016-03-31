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
#import <PINRemoteImage/PINButton+PINRemoteImage.h>
#import <PINCache/PINCache.h>
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImageView.h>
#endif

#import "Kitten.h"

@interface PINViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kittens;

@property (nonatomic) BOOL shouldUseButtonCells;

@end

@interface PINImageCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@interface PINButtonCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *button;

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
    [self.collectionView registerClass:[PINButtonCell class] forCellWithReuseIdentifier:NSStringFromClass([PINButtonCell class])];
    [self.view addSubview:self.collectionView];
    
    self.kittens = [[NSMutableArray alloc] init];
    [self fetchKittenImages];
}

-(IBAction)buttonSwitchToggled:(id)sender
{

    self.shouldUseButtonCells = ((UISwitch *)sender).isOn;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView Data Source

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
    
    if (self.shouldUseButtonCells) {
        
        PINButtonCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PINButtonCell class]) forIndexPath:indexPath];
        
        Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
        cell.backgroundColor = kitten.dominantColor;
        cell.button.alpha = 0.0f;
        
        __weak PINButtonCell *weakCell = cell;
        
        [cell.button pin_setBackgroundImageFromURL:kitten.imageURL
                                 completion:^(PINRemoteImageManagerResult *result) {
                                     if (result.requestDuration > 0.25) {
                                         [UIView animateWithDuration:0.3 animations:^{
                                             weakCell.button.alpha = 1.0f;
                                         }];
                                     } else {
                                         weakCell.button.alpha = 1.0f;
                                     }
                                 }];
        
        [cell.button setTitle:@"I'm a UIButton! Try pressing me!" forState:UIControlStateNormal];
        
        
        return cell;
        
    }else{
        
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

@implementation PINButtonCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = 7.0f;
        self.layer.masksToBounds = YES;
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.frame = self.bounds;
        self.button.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
        self.button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        self.button.titleLabel.numberOfLines = 0;
        self.button.titleLabel.textColor = [UIColor whiteColor];
        self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentView addSubview:self.button];
    }
    return self;
}

-(void)buttonPressed:(id)sender
{
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
        self.button.transform = transform;
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            CGAffineTransform transform = CGAffineTransformMakeRotation(2*M_PI);
            self.button.transform = transform;
        } completion:nil];
        
    }];
}

- (void)prepareForReuse
{
    [self.button setBackgroundImage:nil forState:UIControlStateNormal];
}

@end
