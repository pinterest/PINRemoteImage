//
//  PINAnimatedImageTests.swift
//  PINRemoteImageTests
//
//  Created by Garrett Moon on 9/16/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

import XCTest
import PINRemoteImage

class PINAnimatedImageTests: XCTestCase, PINRemoteImageManagerAlternateRepresentationProvider {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func timeoutInterval() -> TimeInterval {
        return 30
    }

    // MARK: - Animated Images
    func animatedWebPURL() -> URL? {
        return URL.init(string: "https://res.cloudinary.com/demo/image/upload/fl_awebp/bored_animation.webp")
    }
    
    func testWebpAnimatedImages() {
        let expectation =  self.expectation(description: "Result should be downloaded")
        let imageManager = PINRemoteImageManager.init(sessionConfiguration: nil, alternativeRepresentationProvider: self)
        imageManager.downloadImage(with: self.animatedWebPURL()!) { (result : PINRemoteImageManagerResult) in
            XCTAssertNotNil(result.alternativeRepresentation, "alternative representation should be non-nil.")
            XCTAssertNil(result.image, "image should not be returned")
            
            guard let animatedData = result.alternativeRepresentation as? Data else {
                XCTAssert(false, "alternativeRepresentation should be able to be coerced into data")
                return
            }
            
            guard let animatedImage = PINWebPAnimatedImage.init(animatedImageData: animatedData) else {
                XCTAssert(false, "could not create webp image")
                return
            }
            
            let frameCount = animatedImage.frameCount
            var totalDuration : CFTimeInterval = 0
            XCTAssert(frameCount > 1, "Frame count should be greater than 1")
            for frameIdx in 0 ..< frameCount {
                XCTAssertNotNil(animatedImage.image(at: UInt(frameIdx), cacheProvider: nil))
                totalDuration += animatedImage.duration(at: UInt(frameIdx))
            }
            XCTAssert(animatedImage.totalDuration > 0, "Total duration should be greater than 0")
            XCTAssertEqual(totalDuration, animatedImage.totalDuration, "Total duration should be equal to the sum of each frames duration")
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: self.timeoutInterval(), handler: nil)
    }
    
    func alternateRepresentation(with data: Data!, options: PINRemoteImageManagerDownloadOptions = []) -> Any! {
        return data
    }
}
