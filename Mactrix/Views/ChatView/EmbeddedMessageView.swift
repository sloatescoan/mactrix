import MatrixRustSDK
import SwiftUI
import UI

struct EmbeddedMessageView: View {
    let embeddedEvent: MatrixRustSDK.EmbeddedEventDetails
    let action: () -> Void

    var body: some View {
        switch embeddedEvent {
        case .unavailable, .pending:
            UI.MessageReplyView(
                username: "loading@username.org",
                message: "Phasellus sit amet purus ac enim semper convallis. Nullam a gravida libero.",
                action: action
            )
            .redacted(reason: .placeholder)
        case let .ready(content, sender, _, _, _):
            switch content {
            case let .msgLike(content):
                switch content.kind {
                case let .message(content):
                    UI.MessageReplyView(username: sender, message: content.body, action: action)
                case let .sticker(body, _, _):
                    UI.MessageReplyView(username: sender, message: body, action: action)
                case let .poll(question, _, _, _, _, _, _):
                    UI.MessageReplyView(username: sender, message: question, action: action)
                case .redacted:
                    UI.MessageReplyView(username: sender, message: "redacted", action: action)
                case .unableToDecrypt:
                    UI.MessageReplyView(username: sender, message: "unable to decrypt", action: action)
                case .other:
                    UI.MessageReplyView(username: sender, message: "other event", action: action)
                }
            case .callInvite:
                UI.MessageReplyView(username: sender, message: "call invite", action: action)
            case .rtcNotification:
                UI.MessageReplyView(username: sender, message: "rtc notification", action: action)
            case .roomMembership:
                UI.MessageReplyView(username: sender, message: "room membership", action: action)
            case .profileChange:
                UI.MessageReplyView(username: sender, message: "profile change", action: action)
            case .state:
                UI.MessageReplyView(username: sender, message: "state change", action: action)
            case .failedToParseMessageLike:
                UI.MessageReplyView(username: sender, message: "failed to parse message", action: action)
            case .failedToParseState:
                UI.MessageReplyView(username: sender, message: "failed to parse state", action: action)
            }
        case let .error(message):
            Text("error: \(message)")
        }
    }
}
