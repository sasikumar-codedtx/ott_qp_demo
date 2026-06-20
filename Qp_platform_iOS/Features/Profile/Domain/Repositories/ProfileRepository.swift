import Foundation

protocol ProfileRepository {
    func fetchProfiles() async throws -> [Profile]
    func fetchAvatarOptions() async throws -> [AvatarOption]
    func saveProfile(draft: ProfileDraft) async throws -> Profile
}
