
public protocol Room: Hashable {
    var displayName: String? { get }
    var topic: String? { get }
    var encryptionState: EncryptionState { get }
}

public struct MockRoom: Room {
    public let displayName: String?
    public let topic: String?
    public let encryptionState: EncryptionState
    
    public static var previewRoom: MockRoom {
        return MockRoom(displayName: "Test Room", topic: "The topic of the room", encryptionState: .encrypted)
    }
}
