//
//  NSString+MD5Tests.swift
//  PINRemoteImage
//
//  Created by Rodrigo Ruiz Murguía on 27/01/22.
//  Copyright © 2022 Pinterest. All rights reserved.
//

@testable import PINRemoteImage
import XCTest

class NSString_MD5Tests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testCryptoKitCacheKeyMD5() throws {
        let testString: NSString = "My awesome test string"
        let expectedKey: NSString = "4a7719ad08fce9edc64b6ecc59bdf061"
        let actualKey = testString.cryptoKitCacheKeyMD5()

        XCTAssertEqual(expectedKey, actualKey)
    }

    func testCacheKeyForURL() throws {
        let manager = PINRemoteImageManager.shared()
        let expectedKey = "301b1cb35f86b7959817ef3ccc35f438"
        let bigString = String(repeating: "a", count: 250)
        let urlString = "http://www.mycooldomain.com/\(bigString)"
        let url = try XCTUnwrap(URL(string: urlString))

        let actualKey = manager.cacheKey(for: url, processorKey: "processor key")

        XCTAssertEqual(expectedKey, actualKey)
    }

}
