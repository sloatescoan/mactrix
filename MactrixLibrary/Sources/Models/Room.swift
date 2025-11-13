import Foundation

public protocol Room: Hashable, Identifiable {
    var displayName: String? { get }
    var topic: String? { get }
    var encryptionState: EncryptionState { get }
}

public struct MockRoom: Room, Identifiable {
    public let id: String
    
    public let displayName: String?
    public let topic: String?
    public let encryptionState: EncryptionState
    
    public static var previewRoom: MockRoom {
        return MockRoom(id: UUID().uuidString, displayName: "Test Room", topic: "The topic of the room", encryptionState: .encrypted)
    }
}
