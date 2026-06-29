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
        configureAppearance()
        Task {
            _ = await QuickplayConfigurationStore.shared.current()
        }
    }

    private func configureAppearance() {
        let toolbar = UIToolbar.appearance()
        toolbar.barTintColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1)
        toolbar.tintColor = .white
        toolbar.isTranslucent = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
