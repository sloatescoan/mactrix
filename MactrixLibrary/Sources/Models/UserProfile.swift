import Foundation

public protocol UserProfile: Identifiable {
    var userId: String { get }
    var displayName: String? { get }
    var avatarUrl: String? { get }
}

extension UserProfile {
    var id: String { userId }
}
