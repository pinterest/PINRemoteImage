//
//  AppDelegate.swift
//  PINOperationExample
//
//  Created by Martin Púčik on 02/05/2020.
//  Copyright © 2020 Pinterest. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let queue: PINOperationQueue = PINOperationQueue(maxConcurrentOperations: 5)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let operationCount = 100
        let group = DispatchGroup()
        for _ in 0..<operationCount {
            group.enter()
            queue.scheduleOperation({
                group.leave()
            }, with: .default)
        }

        let success = group.wait(timeout: .now() + 20)
        if success != .success {
            fatalError("Timed out before completing 100 operations")
        }
        return true
    }
}
