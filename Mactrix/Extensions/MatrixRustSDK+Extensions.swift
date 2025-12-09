import Foundation
import MatrixRustSDK
import Models

extension MatrixRustSDK.RoomMember: Models.UserProfile {}

extension MatrixRustSDK.RoomMember: @retroactive Identifiable, Models.RoomMember {
    public var id: String {
        userId
    }

    public var roleForPowerLevel: Models.RoomMemberRole {
        suggestedRoleForPowerLevel.asModel
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
        return hasher.combine(id())
    }
}

extension MatrixRustSDK.Room: @retroactive Identifiable {
    public var id: String {
        self.id()
    }
}

extension MatrixRustSDK.RoomInfo: Models.RoomInfo {}

extension MatrixRustSDK.TimelineItem: @retroactive Hashable, @retroactive Identifiable {
    public var id: String {
        uniqueId().id
    }

    public static func == (lhs: MatrixRustSDK.TimelineItem, rhs: MatrixRustSDK.TimelineItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension MatrixRustSDK.Reaction: @retroactive Identifiable {
    public var id: String {
        key
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

public extension MatrixRustSDK.Timestamp {
    var date: Date {
        Date(timeIntervalSince1970: Double(self) / 1000)
    }
}

extension MatrixRustSDK.VirtualTimelineItem {
    var asModel: Models.VirtualTimelineItem {
        switch self {
        case let .dateDivider(ts: ts):
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
        case let .ready(displayName, displayNameAmbiguous, avatarUrl):
            return .ready(displayName: displayName, displayNameAmbiguous: displayNameAmbiguous, avatarUrl: avatarUrl)
        case let .error(message):
            return .error(message: message)
        }
    }
}

extension MatrixRustSDK.EventTimelineItem: Models.EventTimelineItem {
    public var senderProfileDetails: Models.ProfileDetails {
        senderProfile.asModel
    }

    public var date: Date {
        timestamp.date
    }
}

extension MatrixRustSDK.MessageLikeEventType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .callAnswer:
            "call answer"
        case .callCandidates:
            "call candidates"
        case .callHangup:
            "call hangup"
        case .callInvite:
            "call invite"
        case .rtcNotification:
            "rtc notification"
        case .keyVerificationAccept:
            "key verification accept"
        case .keyVerificationCancel:
            "key verification cancel"
        case .keyVerificationDone:
            "key verification done"
        case .keyVerificationKey:
            "key verification key"
        case .keyVerificationMac:
            "key verification mac"
        case .keyVerificationReady:
            "key verification ready"
        case .keyVerificationStart:
            "key verification start"
        case .pollEnd:
            "poll end"
        case .pollResponse:
            "poll reponse"
        case .pollStart:
            "poll start"
        case .reaction:
            "reaction"
        case .roomEncrypted:
            "room encrypted"
        case .roomMessage:
            "room message"
        case .roomRedaction:
            "room redaction"
        case .sticker:
            "sticker"
        case .unstablePollEnd:
            "unstable poll end"
        case .unstablePollResponse:
            "unstable poll response"
        case .unstablePollStart:
            "unstable poll start"
        case let .other(other):
            other
        }
    }
}

extension MatrixRustSDK.OtherState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .policyRuleRoom:
            "changed policy rules for room"
        case .policyRuleServer:
            "changed policy rules for server"
        case .policyRuleUser:
            "changed policy rule for user"
        case .roomAliases:
            "changed room aliases"
        case .roomAvatar(url: _):
            "changed room avatar"
        case .roomCanonicalAlias:
            "changed room canonical alias"
        case .roomCreate:
            "created room"
        case .roomEncryption:
            "changed room encryption"
        case .roomGuestAccess:
            "changed room guest access"
        case .roomHistoryVisibility:
            "change room history visibility"
        case .roomJoinRules:
            "changed room join rules"
        case let .roomName(name: name):
            "changed room name to '\(name ?? "empty")'"
        case .roomPinnedEvents(change: _):
            "changed room pinned events"
        case .roomPowerLevels(users: _, previous: _):
            "changed room power levels"
        case .roomServerAcl:
            "changed room server acl"
        case .roomThirdPartyInvite(displayName: _):
            "changed room third party invite"
        case .roomTombstone:
            "room tombstone"
        case let .roomTopic(topic: topic):
            "changed room topic to '\(topic ?? "none")'"
        case .spaceChild:
            "changed space child"
        case .spaceParent:
            "changed space parent"
        case let .custom(eventType: eventType):
            "changed custom state '\(eventType)'"
        }
    }
}

extension MatrixRustSDK.SpaceRoom: @retroactive Identifiable {
    public var id: String {
        roomId
    }
}

extension MatrixRustSDK.EventOrTransactionId: @retroactive Identifiable {
    public var id: String {
        switch self {
        case let .eventId(eventId):
            return eventId
        case let .transactionId(transactionId):
            return transactionId
        }
    }
}

extension MatrixRustSDK.UserProfile: @retroactive Identifiable, Models.UserProfile {
    public var id: String { userId }
}

extension MatrixRustSDK.SessionVerificationEmoji: @retroactive Identifiable {
    public var id: String { description() }
}

extension MatrixRustSDK.SessionVerificationEmoji: Models.SessionVerificationEmoji {
    public var description: String {
        self.description()
    }

    public var symbol: String {
        self.symbol()
    }
}

extension MatrixRustSDK.SessionVerificationData {
    var asModel: Models.SessionVerificationData<MatrixRustSDK.SessionVerificationEmoji> {
        switch self {
        case let .emojis(emojis, indices):
            return .emojis(emojis: emojis, indices: indices)
        case let .decimals(values):
            return .decimals(values: values)
        }
    }
}

extension MatrixRustSDK.RoomPaginationStatus: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .idle(hitTimelineStart):
            "idle, hitTimelineStart=\(hitTimelineStart)"
        case .paginating:
            "paginating"
        }
    }
}

extension MatrixRustSDK.Room: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "room \(id())"
    }
}

extension MatrixRustSDK.RoomPreviewInfo: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "preview room info: \(roomId) \(name ?? "<no name>")"
    }
}

extension MatrixRustSDK.RoomPreviewInfo: Models.RoomPreviewInfo {
    public var userMembership: Models.Membership? {
        switch membership {
        case .joined:
            return .joined
        case .invited:
            return .invited
        case .left:
            return .left
        case .knocked:
            return .knocked
        case .banned:
            return .banned
        case nil:
            return nil
        }
    }

    public var joinRuleInfo: Models.JoinRule? {
        switch joinRule {
        case .invite:
            return .invite
        case .knock:
            return .knock
        case .public:
            return .public
        case nil:
            return nil
        default:
            return .other
        }
    }

    public var roomKind: Models.RoomKind {
        switch roomType {
        case .room:
            return .room
        case .space:
            return .space
        case let .custom(value: value):
            return .custom(value: value)
        }
    }
}

extension MatrixRustSDK.RoomPreview: @retroactive Hashable {
    public static func == (lhs: MatrixRustSDK.RoomPreview, rhs: MatrixRustSDK.RoomPreview) -> Bool {
        lhs.info().roomId == rhs.info().roomId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(info().roomId)
    }
}
