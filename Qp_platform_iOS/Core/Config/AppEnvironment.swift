import Foundation

nonisolated enum AppEnvironment {

    static let launchConfigURL = "https://config-service-cdn.cms-qp.opt.quickplay.com/launch/config"

    enum Quickplay {
        static let client = "sony-sony-androidmobile"
        static let deviceType = "androidmobile"
        static let cohort = "Sony1"
        static let region = "IN"
        static let storefrontProbeRegion = "all"
        static let searchPageSize = "50"
        static let storefrontPageSize = "20"
    }
    
    enum Demo {
        static let supportPhoneNumber = "+91 6398926078"
        static let hasActiveSubscription = false
        static let mockShortsVideoURLStrings = [
            "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4",
            "https://www.w3schools.com/html/mov_bbb.mp4",
            "https://www.w3schools.com/html/movie.mp4",
            "https://media.w3.org/2010/05/sintel/trailer.mp4",
            "https://media.w3.org/2010/05/bunny/trailer.mp4",
            "https://media.w3.org/2010/05/video/movie_300.mp4"
        ]
    }
}
