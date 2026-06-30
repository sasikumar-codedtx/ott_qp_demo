import Foundation

nonisolated enum AppEnvironment {

    static let launchConfigURL = "https://config-service-cdn.cms-qp.opt.quickplay.com/launch/config"

    enum Quickplay {
        static let client = "sony-sony-androidmobile"
        static let deviceType = "androidmobile"
        static let region = "IN"
        static let storefrontProbeRegion = "all"
        static let searchPageSize = "10"
        static let storefrontPageSize = "10"
    }
    
    enum Demo {
        static let supportPhoneNumber = "+91 6398926078"
    }
}
