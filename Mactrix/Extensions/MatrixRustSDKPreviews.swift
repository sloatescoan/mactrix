import Foundation
import MatrixRustSDK

extension MsgLikeContent {
    public static var previewTextMessage: MsgLikeContent {
        MsgLikeContent(kind: .message(content: .previewTextMessage), reactions: [.previewReaction], inReplyTo: nil, threadRoot: nil, threadSummary: nil)
    }
}


extension MessageContent {
    public static var previewTextMessage: MessageContent {
        MessageContent(msgType: .text(content: TextMessageContent(body: "Hello world", formatted: nil)), body: "Hello world", isEdited: false, mentions: nil)
    }
}

extension Reaction {
    public static var previewReaction: Reaction {
        Reaction(key: "😊", senders: [ReactionSenderData(senderId: "user1", timestamp: .previewTimestamp)])
    }
}

extension Timestamp {
    public static var previewTimestamp: Timestamp {
        Timestamp(Date.now.timeIntervalSince1970)
    }
}

extension EventTimelineItem {
    public static var previewTextItem: EventTimelineItem {
        EventTimelineItem(isRemote: false, eventOrTransactionId: .eventId(eventId: "123"), sender: "Sender Name", senderProfile: .unavailable, isOwn: true, isEditable: false, content: .msgLike(content: .previewTextMessage), timestamp: .previewTimestamp, localSendState: nil, localCreatedAt: nil, readReceipts: [:], origin: nil, canBeRepliedTo: true, lazyProvider: LazyTimelineItemProvider(noPointer: .init()))
    }
}
