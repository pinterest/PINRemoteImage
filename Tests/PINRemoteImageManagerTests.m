//
//  PINRemoteImageManagerTests.m
//  
//
//  Created by Rodrigo Ruiz Murguia on 28/01/22.
//

#import <PINRemoteImage/PINRemoteImageManager.h>
#import <XCTest/XCTest.h>

@interface PINRemoteImageManager (TestSecrets)

-(NSString *) hashCacheKey_removeMeIOS13:(NSString *) string;

@end

@interface PINRemoteImageManagerTests : XCTestCase

@end

@implementation PINRemoteImageManagerTests

- (void)setUp
{
}

- (void)tearDown
{
}

- (void)testCCMD5AndCryptoKitCacheKeyGenerateSameKey
{

    if(@available(iOS 13, tvOS 15.0, macOS 10.15, *)) {} else {
        XCTSkip(@"This test can only run in an OS with CryptoKit enabled");
    }

    PINRemoteImageManager *manager = [PINRemoteImageManager sharedImageManager];

    int num = 250;
    NSMutableString *bigString = [NSMutableString stringWithCapacity:num];
    for (int i = 0; i < num; i++) {
        [bigString appendFormat:@"%C", (unichar)('a')];
    }

    NSString *urlString = [@"http://www.mycooldomain.com/" stringByAppendingString:bigString];
    NSArray<NSString* >* deviations = @[ @"/api", @"/home", @"/play" ];

    for(NSString* deviation in deviations) {
        NSString* composedString = [urlString stringByAppendingString:deviation];
        NSString* ccmd5Key = [manager hashCacheKey_removeMeIOS13:composedString];
        NSString* cryptoKitKey = [composedString cryptoKitCacheKeyMD5];

        NSString* error = [NSString stringWithFormat: @"%@%@%@", @"Hashes of: ", composedString, @" do not match"];
        XCTAssertEqualObjects(ccmd5Key, cryptoKitKey, @"%@", error);
    }
}

@end
