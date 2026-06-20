import Foundation

struct SaveProfileUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute(draft: ProfileDraft) async throws -> Profile {
        try await repository.saveProfile(draft: draft)
    }
}
