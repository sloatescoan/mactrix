import Foundation
import MatrixRustSDK
import Models

extension MatrixRustSDK.Room: Models.Room {
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

extension MatrixRustSDK.EncryptionState {
    var asModel: Models.EncryptionState {
        switch self {
        case .notEncrypted:
            return .notEncrypted
        case .encrypted:
            return .encrypted
        case .unknown:
            return .unknown
        }
    }
}

extension MatrixRustSDK.Room: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: MatrixRustSDK.Room, rhs: MatrixRustSDK.Room) -> Bool {
        return lhs.id() == rhs.id()
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.id())
    }
}

extension MatrixRustSDK.Room: @retroactive Identifiable {
    public var id: String {
        self.id()
    }
}

extension MatrixRustSDK.TimelineItem: @retroactive Equatable, @retroactive Identifiable {
    public var id: String {
        self.uniqueId().id
    }
    
    public static func == (lhs: MatrixRustSDK.TimelineItem, rhs: MatrixRustSDK.TimelineItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MatrixRustSDK.Reaction: @retroactive Identifiable {
    public var id: String {
        self.key
    }
}

extension MatrixRustSDK.Timestamp {
    public var date: Date {
        Date(timeIntervalSince1970: Double(self) / 1000)
    }
}

extension MatrixRustSDK.VirtualTimelineItem {
    var asModel: Models.VirtualTimelineItem {
        switch self {
        case .dateDivider(ts: let ts):
            return .dateDivider(date: ts.date)
        case .readMarker:
            return .readMarker
        case .timelineStart:
            return .timelineStart
        }
    }
}
