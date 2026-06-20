import Foundation

enum AppEnvironment {
    static let webOrigin = "https://www.aha.video"
    static let webReferer = "https://www.aha.video/"
    static let userAgent = "Mozilla/5.0"

    enum SearchDefaults {
        static let region = "in"
        static let accessControl = "te,ta"
        static let deviceType = "web"
        static let profile = "profile"
        static let playbackLanguage = "ta"
        static let pageSize = "50"
    }

    enum CatalogDefaults {
        static let region = "in"
        static let accessControl = "te,ta"
        static let deviceType = "web"
        static let profile = "profile"
        static let playbackLanguage = "te,ta"
        static let pageSize = "5"
    }

    enum UserDefaults {
        static let region = "in"
        static let accessControl = "te,ta"
        static let deviceType = "web"
        static let profile = "profile"
        static let playbackLanguage = "ta"
        static let pageSize = "20"
    }

    enum Endpoint {
        static let storefrontBaseURL = "https://api-aha-cdn.api.ahacms.firstlight.ai"
        static let detailBaseURL = "https://api-aha-cdn.api.ahacms.firstlight.ai"
        static let recommendationBaseURL = "https://rg-srv-cdn.api.ahacms.firstlight.ai"
        static let searchBaseURL = "https://api-aha-cdn.api.ahacms.firstlight.ai"
        static let imageBaseURL = "https://image-resizer-cloud-cdn.api.ahacms.firstlight.ai"
        static let bookmarkBaseURL = "https://api-aha.api.ahaedge.firstlight.ai"
        static let favoriteBaseURL = "https://favorite-cloud.api.ahaedge.firstlight.ai"
    }

    enum AuthSession {
        // TODO: Move these credentials to secure storage once login APIs are wired.
        static let accessToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6InB1YmxpYzowYTU0YjRjNy1iNTIzLTQ4M2ItOGM3Yy04NmVhOGM5YWZkNGIiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOlsiZWRnZS1zZXJ2aWNlIl0sImNsaWVudF9pZCI6ImFuZHJvaWQtdWktYXBwIiwiZXhwIjoxNzgyODQ2OTYyLCJleHQiOnt9LCJpYXQiOjE3ODE2MzczNjIsImlzcyI6Imh0dHBzOi8vYXV0aC5hcGkuYWhhZWRnZS5maXJzdGxpZ2h0LmFpLyIsImp0aSI6ImQ2N2IxNTQxLTljNWItNDYyNi04MjFjLTI1NWI1ZWZiY2RkNyIsIm5iZiI6MTc4MTYzNzM2Miwic2NwIjpbIm9mZmxpbmUiLCJvcGVuaWQiXSwic3ViIjoiYW5kcm9pZC11aS1hcHAifQ.aK-myPTdTn-x49oXWNjt9KRtFcyO0XSixRT6QNhQQTllD73unVsGPzfGH7PT5OobSXBDzaIRU4Z24h2GQ-6iLVhbo4JjD6a7VlraTsZXgy8cbqytLJMDeUHvgndnxgqAUt6Ay78zYXIKP3Xga2b5IhdYZBTTQZ_UHdx0QF2OCDwFAPOS-n3GcdjJaBCpVWbPFxlkrCh7Nx2K7clhImR5j0e4jeSjVlUYzt0YF9UQdRlPsvfU2wV49oxCK6fU8n8p3YmfEBN8EvW_-qPQdIUDLrKhjq5dWauKxiNsXPTJq6sHC4MICviQYL0nh38iZDUS7ta0flFcibmWqzwZc_X1Axn9JHzMsGK4YHwiRT8oA54EYgtDSmTMhBr54-9LWmVy77VYe37VGuwbspbitOATXEZ5LKLzfnc70Cuhogu-77APi1Ml1dDSF6u5JFEXqP6JhFFi-ITY2zZ48pxlEvTX8YS1lX83KsnX4w0I176Xc65w1HAk172JPsOX7Ydwmrfv9a914ZHhGDDgVdDdiSPpGYhJYUmQrR_R9H9qsz8rkE1FjL54NIBgJ56UJHXzn5eHylTruPASq7sBOg8o-wXg1XIRhIG_h7yGYEDeMhzcJQIDw495q4-LZh00Edfc6EhK9d5cOQ1h6chXFp6oYyqKryS8XeRu-D1xptjiHhrW47s"
        static let xAuthorization = "eyJlbmMiOiJBMjU2R0NNIiwiYWxnIjoiZGlyIn0..IQbYMrx-yAFFzIs0.XSJlJp299-_cqQ9aVca8i56ljzzDvL1ZgdeYp8X5VHKQ7YF905Aztsj1hjWWG9wgAgBaoD3FyEWabug_3Aszee0MHtnGm2scMd61PfNU6Rdbbq87uavLAfVhIDYi1cQCln4Yf_L6ZdnT4izvzx4o5MCVPeZKyfiBFvGPMe_h4s2LhJulPvhIIzSTa3wemEYD8Sly6H1yJxqsqHBr7qMTC0CJIM5uGWfFaq9MuJudp_yYSuo7y_dKPgi8oBOw_hf7RbYt0gXJyVGL0tQhz33Y2yl_aw3_XEiIWvjzg3M4poS2cxLzBXEt_RTN3KybnCouvz5uT98pBaX199Lmq67Xu7s28Z_lPeQB0UVO1cM4w9y14cYdPh8bh5KtrNX17e2rRP2YllSs9TNrP12shtZLQ2H-4oZytvOy8QB7YxfYPtIN6sDLzGpmSlhdAUkVwFI_V-QtpKrvSa2E_iPBuZFlLAw6UhpUZyclQNPQm8aEKrgWvmE5m04Sn7unu4j2UgzLh51Eqd4x0NReHA5QIxSkHPoeeoS4PULCSdAaK0oIots2Z-I7CVmkDsxNR2ra7E96DJZUhG1CMc3ew7M2P-qH24JLJlIDv5gaRzQ22_AsOWhz-lRPPGVwtrG_e4iT0C7dZ0WlcijR8NwuETZjLmQjABkcXKKf_XqFxSpS0SBKRUTqWcj9swsa3MUeth4sEAhJ1huvE6cEBFVQRnhCwwV4EsRzOHbokBk0V7dPbkkATSO7MmdNT6nD5yEQFnA7QNffg_6J_v8EM0FChtRvDVKynT0xtJVqwXsWQuURMpHrVrvyTylApC7zta0waYKV_KaLC7Hm0oFwQJFZHu3jU_iXrXgoH01XtKJ5uHogxgrMIOkGscpF4LYdkPIMS7rTBU1HbawM0DJlUTvjr_ieC7drsn0kizGTR0SVzbxBdO4hV9wt-6JBB_vTWxaC_PxkJv2wLOqHNPwm3Qt05EdeQiMMeov6j2cNSM8oSOp-iXaoSWn8rU8lbhzjLu1U54LGonQE9Z3zbyfThLqs2APcilKTkdGardHBhGqr2UINCD6zyz9nOCdktfQ9xklTxcOBoOJxa8keH2pwmsTw5OVL0nelwtxuqXceX_ltkkwRcwXP1P898XSqL66ZqbDwNriMuKDnSVJgGPygK0O0tQktiRdmr7blRAFfAe829TZCwiaiiFD4DR22cK27RyvTI0ZgXd2Y0JOZB4J8gDXohsBPuoiFG7uQBFwyrCaK5y_wLGB-JOsdwhtUN11iQJFwQLX6mzxH5E6ltElzn5v9ahOvSdi-jNbml-Kiyr6l_L3fKfsu7MsJ5_RFlhDW362rAjuMYu2Xb6Zf-DL0clJvpkKxPASLcPOPPLJ1hqCqSx7k15QcPEmGVz6DmWJw-bTSJUmnrt4rj25QaFsH66lSFtGC1RbUQBowXNT3VSGwY35LAx7fNhjh66zTRnnQVCQbpIi9nTozLIJCZXvzWqN-7AOs-jRTHmOC1MibwePkf0l7yq17UyF6rBUN762h8ZTGESbeRoH3sJ0AcWYe6P3gkb8uWAhy_Y_c9wvQ4ewQdhyUunCfk1YmlkpjOlANAb5nIbykFg.q88mfphahk92RhFUVZldPw"
        static let profileRecommendationID = "499604696"
        static let supportPhoneNumber = "+91 6398926078"
        static let hasActiveSubscription = false
    }
}
