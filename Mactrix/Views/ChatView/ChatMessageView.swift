import SwiftUI
import Models
import UI
import MatrixRustSDK

struct ChatMessageView: View, UI.MessageEventActions {
    let timeline: MatrixRustSDK.Timeline?
    let event: MatrixRustSDK.EventTimelineItem
    let msg: MsgLikeContent
    
    var name: String {
        if case let .ready(displayName, _, _) = event.senderProfileDetails, let displayName = displayName {
            return displayName
        }
        return event.sender
    }
    
    func toggleReaction(key: String) {
        Task {
            let _ = try await timeline?.toggleReaction(itemId: event.eventOrTransactionId, key: key)
        }
    }
    
    func reply() {}
    
    func replyInThread() {}
    
    func pin() {
        guard case let .eventId(eventId: eventId) = event.eventOrTransactionId else { return }
        Task {
            try await timeline?.pinEvent(eventId: eventId)
        }
    }
    
    @ViewBuilder
    var message: some View {
        switch msg.kind {
        case .message(content: let content):
            switch content.msgType {
            case .emote(content: let content):
                Text("Emote: \(content.body)").textSelection(.enabled)
            case .image(content: let content):
                MessageImageView(content: content)
            case .audio(content: let content):
                Text("Audio: \(content.caption ?? "no caption") \(content.filename)").textSelection(.enabled)
            case .video(content: let content):
                Text("Video: \(content.caption ?? "no caption") \(content.filename)").textSelection(.enabled)
            case .file(content: let content):
                Text("File: \(content.caption ?? "no caption") \(content.filename)").textSelection(.enabled)
            case .gallery(content: let content):
                Text("Gallery: \(content.body)").textSelection(.enabled)
            case .notice(content: let content):
                Text("Notice: \(content.body)").textSelection(.enabled)
            case .text(content: let content):
                Text(content.body).textSelection(.enabled)
            case .location(content: let content):
                Text("Location: \(content.body) \(content.geoUri)").textSelection(.enabled)
            case .other(msgtype: let msgtype, body: let body):
                Text("Other: \(msgtype) \(body)").textSelection(.enabled)
            }
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
    
    var body: some View {
        UI.MessageEventView(event: event, reactions: msg.reactions, actions: self) {
            message
        }
    }
}
