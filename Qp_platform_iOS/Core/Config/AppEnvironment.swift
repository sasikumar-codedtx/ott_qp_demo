import Foundation

nonisolated enum AppEnvironment {
    static let webOrigin = "https://www.sonyliv.com"
    static let webReferer = "https://www.sonyliv.com/"
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    enum Quickplay {
        static let client = "sony-sony-androidmobile"
        static let deviceType = "androidmobile"
        static let cohort = "Sony1"
        static let region = "IN"
        static let storefrontProbeRegion = "all"
        static let searchPageSize = "50"
        static let storefrontPageSize = "20"
    }

    enum Endpoint {
        static let launchConfigURL = "https://config-service-cdn.cms-qp.opt.quickplay.com/launch/config"
        static let fallbackCatalogBaseURL = "https://catalog-service-cdn.cms-qp.opt.quickplay.com"
        static let fallbackStorefrontBaseURL = "https://storefront.cms-qp.opt.quickplay.com"
        static let microDramaStorefrontListURL = "\(fallbackStorefrontBaseURL)/storefront/list?reg=all&dt=androidmobile&client=sony-sony-androidmobile&pf=regular&chrt=Sony1"
        static let newAndHotStorefrontListURL = "\(fallbackStorefrontBaseURL)/storefront/list?reg=all&dt=androidmobile&client=sony-sony-androidmobile&pf=regular&chrt=Sony1"
        static let fallbackDetailBaseURL = "https://data-store.cms-qp.opt.quickplay.com"
        static let fallbackSearchBaseURL = "https://search-cdn.cms-qp.opt.quickplay.com"
        static let fallbackRecommendationBaseURL = "https://rg-srv.cms-qp.opt.quickplay.com"
        static let fallbackImageBaseURL = "https://image-resizer-cloud.cms-qp.opt.quickplay.com"
        static let fallbackPersonalisationBaseURL = "https://user-catalog.edge-qp.opt.quickplay.com"
    }

    enum Demo {
        static let supportPhoneNumber = "+91 6398926078"
        static let hasActiveSubscription = false
    }
}
