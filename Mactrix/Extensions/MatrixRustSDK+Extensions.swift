import Foundation
import MatrixRustSDK
import Models

extension MatrixRustSDK.RoomMember: @retroactive Identifiable, Models.RoomMember {
    public var id: String {
        self.userId
    }
    
    public var roleForPowerLevel: Models.RoomMemberRole {
        self.suggestedRoleForPowerLevel.asModel
    }
}

extension MatrixRustSDK.RoomMemberRole {
    var asModel: Models.RoomMemberRole {
        switch self {
        case .creator:
            return .creator
        case .administrator:
            return .administrator
        case .moderator:
            return .moderator
        case .user:
            return .user
        }
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

extension MatrixRustSDK.TimelineItem: @retroactive Hashable, @retroactive Identifiable {
    public var id: String {
        self.uniqueId().id
    }
    
    public static func == (lhs: MatrixRustSDK.TimelineItem, rhs: MatrixRustSDK.TimelineItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension MatrixRustSDK.Reaction: @retroactive Identifiable {
    public var id: String {
        self.key
    }
}

extension MatrixRustSDK.Reaction: Models.Reaction {
    public typealias SenderData = MatrixRustSDK.ReactionSenderData
}

extension MatrixRustSDK.ReactionSenderData: Models.ReactionSenderData {
    public var date: Date {
        timestamp.date
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

extension MatrixRustSDK.ProfileDetails {
    var asModel: Models.ProfileDetails {
        switch self {
        case .unavailable:
            return .unavailable
        case .pending:
            return .pending
        case .ready(let displayName, let displayNameAmbiguous, let avatarUrl):
            return .ready(displayName: displayName, displayNameAmbiguous: displayNameAmbiguous, avatarUrl: avatarUrl)
        case .error(let message):
            return .error(message: message)
        }
    }
}

extension MatrixRustSDK.EventTimelineItem: Models.EventTimelineItem {
    public var senderProfileDetails: Models.ProfileDetails {
        self.senderProfile.asModel
    }
    
    public var date: Date {
        timestamp.date
    }
}

extension MatrixRustSDK.SpaceRoom: @retroactive Identifiable {
    public var id: String {
        self.roomId
    }
}
