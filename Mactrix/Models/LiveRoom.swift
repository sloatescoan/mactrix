import Foundation
import MatrixRustSDK
import Models

@Observable
public final class LiveRoom: MatrixRustSDK.Room, Models.Room {
    public var typingUserIds: [String] = []
    public var fetchedMembers: [MatrixRustSDK.RoomMember]? = nil
    
    private var typingHandle: TaskHandle?
    
    public convenience init(room: MatrixRustSDK.Room) {
        self.init(unsafeFromRawPointer: room.uniffiClonePointer())
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        super.init(unsafeFromRawPointer: pointer)
        startListening()
    }
    
    private func startListening() {
        self.typingHandle = subscribeToTypingNotifications(listener: self)
    }
    
    
    public func syncMembers() async throws {
        // guard not already synced
        guard fetchedMembers == nil else { return }
        
        print("syncing members for room: \(self.id)")
        
        let memberIter = try await self.members()
        var result = [MatrixRustSDK.RoomMember]()
        while let memberChunk = memberIter.nextChunk(chunkSize: 1000) {
            result.append(contentsOf: memberChunk)
        }
        fetchedMembers = result
        
        print("synced \(fetchedMembers?.count, default: "(unknown)") members")
    }
    
    public var displayName: String? {
        self.displayName()
    }
    
    public var topic: String? {
        self.topic()
    }
    
    public var encryptionState: Models.EncryptionState {
        self.encryptionState().asModel
    }
}

extension LiveRoom: TypingNotificationsListener {
    public func call(typingUserIds: [String]) {
        self.typingUserIds = typingUserIds
    }
}
