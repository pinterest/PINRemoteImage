//
//  PINCache_SPM_IntegrationApp.swift
//  PINCache-SPM-Integration
//
//  Created by Petro Rovenskyy on 19.11.2020.
//

import SwiftUI
import PINCache

final class AppDelegate: UIResponder, UIApplicationDelegate {
    static let cacheKey: String = "pinCache"
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        PINCache.shared.setObject("Hello! I'm cached string",
                                  forKey: Self.cacheKey)
        return true
    }
}

@main
struct PINCache_SPM_IntegrationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView(cacheKey: AppDelegate.cacheKey)
        }
    }
}
