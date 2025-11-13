import Foundation
import MatrixRustSDK

@Observable
public final class LiveRoom: MatrixRustSDK.Room {
    private var typingHandle: TaskHandle?
    
    public var typingUserIds: [String] = []
    public var fetchedMembers: [MatrixRustSDK.RoomMember]? = nil
    
    public convenience init(room: MatrixRustSDK.Room) {
        self.init(unsafeFromRawPointer: room.uniffiClonePointer())
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        super.init(unsafeFromRawPointer: pointer)
        startListening()
    }
    
    func startListening() {
        self.typingHandle = subscribeToTypingNotifications(listener: self)
    }
    
    func syncMembers() async throws {
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
}

extension LiveRoom: TypingNotificationsListener {
    public func call(typingUserIds: [String]) {
        self.typingUserIds = typingUserIds
    }
}
