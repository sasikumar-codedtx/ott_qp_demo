import Foundation
import Kingfisher

enum ImageCacheManager {
    static let diskLimitBytes: UInt = 500 * 1024 * 1024
    static let memoryLimitBytes = 100 * 1024 * 1024

    static func configure() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = memoryLimitBytes
        cache.memoryStorage.config.expiration = .seconds(600)
        cache.diskStorage.config.sizeLimit = diskLimitBytes
        cache.diskStorage.config.expiration = .days(30)

        // Cap concurrent image downloads per host so fast scrolling doesn't saturate
        // bandwidth and make every visible card appear to load simultaneously.
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpMaximumConnectionsPerHost = 4
        KingfisherManager.shared.downloader.sessionConfiguration = sessionConfig
    }

    static func clear(completion: @escaping () -> Void = {}) {
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache {
            completion()
        }
    }
}
