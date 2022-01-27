//
//  NSString+MD5.swift
//  PINRemoteImage
//
//  Created by Rodrigo Ruiz Murguia on 27/01/22.
//  Copyright © 2022 Pinterest. All rights reserved.
//

import CryptoKit
import Foundation

extension NSString {

    private func MD5(with format: String) -> NSString {
        guard #available(iOS 13, *),
              #available(tvOSApplicationExtension 13.0, *) else { return "" }

        let string = self as String
        guard let data = string.data(using: .utf8) else { return "" }
        let digest = Insecure.MD5.hash(data: data)

        return digest.map { byte in
            String(format: format, byte)
        }.joined() as NSString
    }

    @objc
    public func cryptoKitCacheKeyMD5() -> NSString {
        guard #available(iOS 13, *),
              #available(tvOSApplicationExtension 13.0, *)else { return "" }
        return MD5(with: "%02lx")
    }
}
