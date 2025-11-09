import Foundation
import MatrixRustSDK

@Observable
public final class LiveRoom: MatrixRustSDK.Room {
    var typingHandle: TaskHandle?
    
    public var typingUserIds: [String] = []
    
    public init(room: MatrixRustSDK.Room) {
        super.init(unsafeFromRawPointer: room.uniffiClonePointer())
        startListening()
    }
    
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        super.init(unsafeFromRawPointer: pointer)
        startListening()
    }
    
    func startListening() {
        self.typingHandle = subscribeToTypingNotifications(listener: self)
    }
}

extension LiveRoom: TypingNotificationsListener {
    public func call(typingUserIds: [String]) {
        self.typingUserIds = typingUserIds
    }
}
