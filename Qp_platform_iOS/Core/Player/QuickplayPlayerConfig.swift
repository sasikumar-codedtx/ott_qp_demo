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
    let heartBeatSyncIntervalMs: TimeInterval
    let streamConcurrencyEndpoint: String
    let imageResizerURL: String
    let defaultQpat: String
    let bookmarkSyncIntervalMs: TimeInterval

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
        heartBeatSyncIntervalMs: TimeInterval = 60000,
        streamConcurrencyEndpoint: String,
        imageResizerURL: String,
        defaultQpat: String,
        bookmarkSyncIntervalMs: TimeInterval = 60000
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
        self.heartBeatSyncIntervalMs = heartBeatSyncIntervalMs
        self.streamConcurrencyEndpoint = streamConcurrencyEndpoint
        self.imageResizerURL = imageResizerURL
        self.defaultQpat = defaultQpat
        self.bookmarkSyncIntervalMs = bookmarkSyncIntervalMs
    }

    init(config: QuickplayRuntimeConfig) {
        self.init(
            oauthEndpoint: config.oauthURL + "/oauth2/token",
            registrationEndpoint: config.clientRegistrationURL,
            contentAuthEndpoint: config.contentAuthURL,
            clientId: config.clientID,
            clientSecret: config.clientSecret,
            xClientId: config.xClientID.isEmpty ? config.clientID : config.xClientID,
            xPropertyId: "",
            guestFlatEndpoint: "https://auth-gw.edge-qp.opt.quickplay.com",
            heartbeatEndpoint: config.heartBeatURL,
            heartBeatSyncIntervalMs: config.heartBeatSyncIntervalMs,
            streamConcurrencyEndpoint: config.streamConcurrencyURL,
            imageResizerURL: config.imageResizeURL,
            defaultQpat: config.defaultQpat,
            bookmarkSyncIntervalMs: config.bookmarkSyncIntervalMs
        )
    }
}
