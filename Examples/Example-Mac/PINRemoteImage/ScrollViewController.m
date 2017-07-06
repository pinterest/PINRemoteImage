//
//  ScrollViewController.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "ScrollViewController.h"

#import <Quartz/Quartz.h>
#import <PINRemoteImage/PINRemoteImageManager.h>
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <PINRemoteImage/PINRemoteImageCaching.h>

#import "PINViewWithBackgroundColor.h"
#import "Kitten.h"

@interface PINImageCollectionViewItem : NSCollectionViewItem

@end

@interface ScrollViewController ()
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kittens;
@end

@implementation ScrollViewController


#pragma mark - Lifecycle

- (instancetype)init
{
    srand([[NSDate date] timeIntervalSince1970]);
    
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self == nil) { return self; }
    [[[PINRemoteImageManager sharedImageManager] cache] removeAllObjects];
    return self;
}


#pragma mark - NSViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.collectionView registerNib:[[NSNib alloc] initWithNibNamed:@"PINImageCollectionViewItemView" bundle:nil] forItemWithIdentifier:@"ItemIdentifier"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.kittens = [NSMutableArray new];
    [self fetchKittenImages];
}

- (void)viewWillLayout
{
    [super viewWillLayout];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}


#pragma mark - Load images

- (void)fetchKittenImages
{
    [Kitten fetchKittenForWidth:CGRectGetWidth(self.collectionView.frame) completion:^(NSArray *kittens) {
        [self.kittens addObjectsFromArray:kittens];
        [self.collectionView reloadData];
    }];
}


#pragma mark - <NSCollectionViewDataSource, NSCollectionViewDelegate>

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.kittens.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    PINImageCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"PINImageCollectionViewItemView" forIndexPath:indexPath];
    Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
    item.imageView.alphaValue = 0.0f;
    [((PINViewWithBackgroundColor *)item.view) setBackgroundColor:kitten.dominantColor];
    __weak NSCollectionViewItem *weakItem = item;

    [item.imageView pin_setImageFromURL:kitten.imageURL
                             completion:^(PINRemoteImageManagerResult *result) {
                                 if (result.requestDuration > 0.25) {
                                     [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                                         context.duration = 0.3;
                                         context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                                         weakItem.imageView.animator.alphaValue = 1.0f;
                                     } completionHandler:^{
                                     }];
                                 } else {
                                     weakItem.imageView.alphaValue = 1.0f;
                                 }
                             }];
    return item;
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Kitten *kitten = [self.kittens objectAtIndex:indexPath.item];
    return NSMakeSize(CGRectGetWidth(collectionView.frame), kitten.imageSize.height);
}

@end


@implementation PINImageCollectionViewItem

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.imageView.image = nil;
}

@end
