//
//  Pin.swift
//  PINRemoteImage
//
//  Created by Andrew Breckenridge on 4/8/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

import Foundation

public struct Pin<Base: Any> {
    /// Base object to extend.
    public let base: Base

    /// Creates extensions with base object.
    ///
    /// - parameter base: Base object.
    public init(_ base: Base) {
        self.base = base
    }
}

/// A type that has pin extensions.
public protocol PinCompatible {
    /// Extended type
    associatedtype CompatibleType

    /// Reactive extensions.
    static var pin: Pin<CompatibleType>.Type { get set }

    /// Reactive extensions.
    var pin: Pin<CompatibleType> { get set }
}

// Default implemenation of PinCompatible without
extension PinCompatible {
    /// Reactive extensions.
    public static var pin: Pin<Self>.Type {
        get {
            return Pin<Self>.self
        }
        set {
            // this enables using Reactive to "mutate" base type
        }
    }

    /// Reactive extensions.
    public var pin: Pin<Self> {
        get {
            return Pin(self)
        }
        set {
            // this enables using Reactive to "mutate" base object
        }
    }
}
