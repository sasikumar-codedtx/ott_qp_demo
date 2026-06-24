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

    init(
        oauthEndpoint: String,
        registrationEndpoint: String,
        contentAuthEndpoint: String,
        clientId: String,
        clientSecret: String,
        xClientId: String,
        xPropertyId: String,
        guestFlatEndpoint: String,
        heartbeatEndpoint: String,
        streamConcurrencyEndpoint: String,
        imageResizerURL: String
    ) {
        self.oauthEndpoint = oauthEndpoint
        self.registrationEndpoint = registrationEndpoint
        self.contentAuthEndpoint = contentAuthEndpoint
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.xClientId = xClientId
        self.xPropertyId = xPropertyId
        self.guestFlatEndpoint = guestFlatEndpoint
        self.heartbeatEndpoint = heartbeatEndpoint
        self.streamConcurrencyEndpoint = streamConcurrencyEndpoint
        self.imageResizerURL = imageResizerURL
    }

    init(config: QuickplayRuntimeConfig) {
        self.init(
            oauthEndpoint: config.oauthURL,
            registrationEndpoint: config.clientRegistrationURL,
            contentAuthEndpoint: config.contentAuthURL,
            clientId: config.clientID,
            clientSecret: config.clientSecret,
            xClientId: config.xClientID.isEmpty ? config.clientID : config.xClientID,
            xPropertyId: "",
            guestFlatEndpoint: config.guestFlatURL,
            heartbeatEndpoint: config.heartBeatURL,
            streamConcurrencyEndpoint: config.streamConcurrencyURL,
            imageResizerURL: config.imageResizeURL
        )
    }
}
