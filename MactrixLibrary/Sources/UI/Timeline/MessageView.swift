import Models
import SwiftUI

public struct MessageView<Event: EventTimelineItem, MsgContent: MsgLikeContent, Actions: MessageEventActions>: View {
    // let timeline: MatrixRustSDK.Timeline?
    let event: Event
    let msg: MsgContent

    let actions: Actions
    let imageLoader: ImageLoader

    var name: String {
        if case let .ready(displayName, _, _) = event.senderProfileDetails, let displayName = displayName {
            return displayName
        }
        return event.sender
    }

    @ViewBuilder
    var message: some View {
        switch msg.kind {
        case let .message(content: content):
            Text("Message: \(content.body)")
            /*switch content.msgType {
            case let .emote(content: content):
                Text("Emote: \(content.body)").textSelection(.enabled)
            case let .image(content: content):
                MessageImageView(content: content)
            case let .audio(content: content):
                Text("Audio: \(content.caption ?? "no caption") \(content.filename)").textSelection(.enabled)
            case let .video(content: content):
                Text("Video: \(content.caption ?? "no caption") \(content.filename)").textSelection(.enabled)
            case let .file(content: content):
                Text("File: \(content.caption ?? "no caption") \(content.filename)").textSelection(.enabled)
            case let .gallery(content: content):
                Text("Gallery: \(content.body)").textSelection(.enabled)
            case let .notice(content: content):
                Text("Notice: \(content.body)").textSelection(.enabled)
            case let .text(content: content):
                Text(content.body).textSelection(.enabled)
            case let .location(content: content):
                Text("Location: \(content.body) \(content.geoUri)").textSelection(.enabled)
            case let .other(msgtype: msgtype, body: body):
                Text("Other: \(msgtype) \(body)").textSelection(.enabled)
            }*/
        case .sticker(body: let body, info: _, source: _):
            Text("Sticker: \(body)").textSelection(.enabled)
        case .poll(question: let question, kind: _, maxSelections: _, answers: _, votes: _, endTime: _, hasBeenEdited: _):
            Text("Poll: \(question)").textSelection(.enabled)
        case .redacted:
            Text("Message redacted")
                .italic()
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        case .unableToDecrypt(msg: _):
            Text("Unable to decrypt")
                .italic()
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        case .other(eventType: _):
            Text("Custom event").textSelection(.enabled)
        }
    }

    func embeddEventDetails(embeddedEvent: EmbeddedEventDetails<MsgContent>) -> String {
        switch embeddedEvent {
        case .unavailable:
            "embedded event unavailable"
        case .pending:
            "embedded event pending"
        case let .ready(content, _, _, _, _):
            switch content {
            case let .msgLike(content):
                switch content.kind {
                case let .message(content):
                    content.body
                case let .sticker(body, _, _):
                    body
                case let .poll(question, _, _, _, _, _, _):
                    question
                case .redacted:
                    "redacted"
                case .unableToDecrypt:
                    "unable to decrypt"
                case .other:
                    "other event"
                }
            case .callInvite:
                "call invite"
            case .rtcNotification:
                "rtc notification"
            case .roomMembership:
                "room membership"
            case .profileChange:
                "profile change"
            case .state:
                "state change"
            case .failedToParseMessageLike:
                "failed to parse message"
            case .failedToParseState:
                "failed to parse state"
            }
        case let .error(message):
            "error: \(message)"
        }
    }

    public var body: some View {
        MessageEventView(event: event, reactions: msg.reactions, actions: actions, imageLoader: imageLoader) {
            VStack(alignment: .leading, spacing: 20) {
                /*if msg.inReplyTo != nil || msg.threadRoot != nil || msg.threadSummary != nil {
                    VStack(alignment: .leading) {
                        if let replyTo = msg.inReplyTo {
                            Text("Reply to \(replyTo.eventId().prefix(8)): \(embeddEventDetails(embeddedEvent: replyTo.event()))").italic()
                        }

                        if let threadRoot = msg.threadRoot {
                            Text("Thread root: \(threadRoot.prefix(8))").italic()
                        }

                        if let threadSummary = msg.threadSummary {
                            Text("Thread summary (\(threadSummary.numReplies()) messages): \(embeddEventDetails(embeddedEvent: threadSummary.latestEvent()))")
                                .italic()
                        }
                    }
                    .foregroundStyle(.gray)
                }*/

                message
            }
        }
    }
}
