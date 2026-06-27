//
//  Qp_platform_iOSApp.swift
//  Qp_platform_iOS
//
//  Created by Sasikumar Govindaraj on 20/06/26.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

@main
struct Qp_platform_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        ImageCacheManager.configure()
        Task {
            _ = await QuickplayConfigurationStore.shared.current()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
