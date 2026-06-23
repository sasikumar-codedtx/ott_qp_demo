import Foundation

struct QuickplayPlayerConfig {
    let oauthEndpoint: String
    let registrationEndpoint: String
    let contentAuthEndpoint: String
    let clientId: String
    let clientSecret: String
    let xClientId: String
    let xPropertyId: String
    let guestFlatEndpoint: String
    let heartbeatEndpoint: String
    let streamConcurrencyEndpoint: String
    let imageResizerURL: String

    static var current: QuickplayPlayerConfig {
        QuickplayPlayerConfig(
            oauthEndpoint: AppEnvironment.Endpoint.playerOAuthURL,
            registrationEndpoint: AppEnvironment.Endpoint.playerRegistrationURL,
            contentAuthEndpoint: AppEnvironment.Endpoint.playerContentAuthURL,
            clientId: "ios-ui-app",
            clientSecret: "c1c6c9f6-375e-4a25-ab5c-1bffd3b48a1c",
            xClientId: "ios-ui-app",
            xPropertyId: "",
            guestFlatEndpoint: AppEnvironment.Endpoint.playerGuestFlatURL,
            heartbeatEndpoint: AppEnvironment.Endpoint.playerHeartbeatURL,
            streamConcurrencyEndpoint: AppEnvironment.Endpoint.playerStreamConcurrencyURL,
            imageResizerURL: AppEnvironment.Endpoint.fallbackImageBaseURL
        )
    }
}
