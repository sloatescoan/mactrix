import SwiftUI
import MatrixRustSDK

struct ChatInput: View {
    
    @State private var chatInput: String = ""
    
    var body: some View {
        VStack {
            //TextEditor(text: $chatInput)
            TextField("Message room", text: $chatInput, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(nil)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .padding(10)
                //.padding(.horizontal, 5)
        }
        .font(.system(size: 14))
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(4)
        .lineSpacing(2)
        .frame(minHeight: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        //.shadow(color: .black.opacity(0.1), radius: 4)
        .padding([.horizontal, .bottom], 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ChatMessage: View {
    
    let event: EventTimelineItem
    let msg: MsgLikeContent
    
    var name: String {
        if case let .ready(displayName, _, _) = event.senderProfile, let displayName = displayName {
            return displayName
        }
        return event.sender
    }
    
    var message: String {
        "Hello"
    }
    
    var timestamp: Date {
        Date(timeIntervalSince1970: Double(event.timestamp))
    }
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    @State private var hoverText: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Circle()
                            .frame(width: 32, height: 32)
                        
                    }.frame(width: 64)
                    
                    Text(name)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: 0) {
                    HStack {
                        Text(timeFormat.string(from: timestamp))
                            .foregroundStyle(.gray)
                            .font(.system(.footnote))
                            .padding(.trailing, 5)
                            .padding(.top, 3)
                    }
                    .frame(width: 64 - 10)
                    .opacity(hoverText ? 1 : 0)
                    Text(message).textSelection(.enabled)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.tertiary)
                        .opacity(hoverText ? 1 : 0)
                )
                .padding(.horizontal, 10)
            }
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                }.buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "arrowshape.turn.up.left")
                }.buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "ellipsis.message")
                }.buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    .shadow(color: .black.opacity(0.1), radius: 4)
            )
            .padding(.trailing, 20)
            .padding(.top, 18)
            .opacity(hoverText ? 1 : 0)
            
        }
        .padding(.top, 5)
        .onHover { hover in
            hoverText = hover
        }
    }
}

struct StateEvent: View {
    
    let event: EventTimelineItem
    let stateKey: String
    let state: OtherState
    
    var stateMessage: String {
        switch state {
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
        case .roomName(name: let name):
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
        case .roomTopic(topic: let topic):
            "changed room topic to '\(topic ?? "none")'"
        case .spaceChild:
            "changed space child"
        case .spaceParent:
            "changed space parent"
        case .custom(eventType: let eventType):
            "changed custom state '\(eventType)'"
        }
    }
    
    var body: some View {
        HStack {
            (Text(event.sender).bold() + Text(" changed " + stateMessage))
                .italic()
            Spacer()
        }
        .padding(.horizontal, 10)
    }
}

struct GenericEvent: View {
    let name: String
    
    var body: some View {
        Text(name)
            .frame(maxWidth: .infinity)
    }
}

struct TimelineItemView: View {
    
    let item: TimelineItem
    
    var body: some View {
        if let event = item.asEvent() {
            switch event.content {
            case .msgLike(content: let content):
                ChatMessage(event: event, msg: content)
            case .callInvite:
                GenericEvent(name: "Call invite")
            case .rtcNotification:
                GenericEvent(name: "Rtc notification")
            case .roomMembership(userId: _, userDisplayName: _, change: _, reason: _):
                GenericEvent(name: "Room membership")
            case .profileChange(displayName: _, prevDisplayName: _, avatarUrl: _, prevAvatarUrl: _):
                GenericEvent(name: "Profile change")
            case let .state(stateKey: stateKey, content: content):
                StateEvent(event: event, stateKey: stateKey, state: content)
            case .failedToParseMessageLike(eventType: _, error: let error):
                GenericEvent(name: "Failed to parse message like: \(error)")
            case .failedToParseState(eventType: _, stateKey: _, error: let error):
                GenericEvent(name: "Failed to parse state: \(error)")
            }
        }
    }
}

struct ChatView: View {
    @Environment(AppState.self) private var appState
    
    let room: Room
    @State private var timeline: RoomTimeline? = nil
    
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView([.vertical]) {
                if let timelineItems = timeline?.timelineItems {
                    ForEach(timelineItems) { item in
                        TimelineItemView(item: item)
                    }
                } else {
                    ProgressView()
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity)
                }
            }
            .defaultScrollAnchor(.bottom)
            ChatInput()
                .padding(.top, 20)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .task(id: room) {
            do {
                self.timeline = try await RoomTimeline(room: room)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
