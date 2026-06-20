import Foundation

extension URLCache {
    static let imageCache: URLCache = {
        URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "qp_platform_image_cache"
        )
    }()
}

extension URLSession {
    static let imageSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = .imageCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
}
