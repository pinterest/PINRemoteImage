//
//  NSString+MD5.swift
//  PINRemoteImage
//
//  Created by Rodrigo Ruiz Murguia on 27/01/22.
//  Copyright © 2022 Pinterest. All rights reserved.
//

#if canImport(CryptoKit)
import CryptoKit
#endif

import Foundation

@available(iOS 13, *)
@available(tvOS 15.0, *)
@available(macOS 10.15, *)
extension NSString {

    private func MD5(with format: String) -> NSString {
#if canImport(CryptoKit)
        let string = self as String
        let data = Data(string.utf8)
        let digest = Insecure.MD5.hash(data: data)

        return digest.map { byte in
            String(format: format, byte)
        }.joined() as NSString
#else
        fatalError("This API is only available for iOS >= 13")
#endif

    }

    @objc
    public func cryptoKitCacheKeyMD5() -> NSString {
        return MD5(with: "%02lx")
    }
}
