//
//  AppDelegate.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/3/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "AppDelegate.h"
#import <PINRemoteImage/PINRemoteImageManager.h>
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <PINCache/PINCache.h>

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *imageView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    NSURL *imageURL = [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/92/5d/5a/925d5ac74db0dcfabc238e1686e31d16.jpg"];
    [self.imageView pin_setImageFromURL:imageURL];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
