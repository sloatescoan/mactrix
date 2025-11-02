import SwiftUI
import MatrixRustSDK

struct TimelineItemView: View {
    
    let event: EventTimelineItem
    
    var body: some View {
        switch event.content {
        case .msgLike(content: let content):
            ChatMessageView(event: event, msg: content)
        case .callInvite:
            GenericEventView(name: "Call invite")
        case .rtcNotification:
            GenericEventView(name: "Rtc notification")
        case .roomMembership(userId: _, userDisplayName: _, change: _, reason: _):
            GenericEventView(name: "Room membership")
        case .profileChange(displayName: _, prevDisplayName: _, avatarUrl: _, prevAvatarUrl: _):
            GenericEventView(name: "Profile change")
        case let .state(stateKey: stateKey, content: content):
            StateEventView(event: event, stateKey: stateKey, state: content)
        case .failedToParseMessageLike(eventType: _, error: let error):
            GenericEventView(name: "Failed to parse message like: \(error)")
        case .failedToParseState(eventType: _, stateKey: _, error: let error):
            GenericEventView(name: "Failed to parse state: \(error)")
        }
    }
}

#Preview {
    TimelineItemView(event: .previewTextItem)
}

struct ChatView: View {
    @Environment(AppState.self) private var appState
    
    let room: Room
    @State private var timeline: RoomTimeline? = nil
    
    @State private var errorMessage: String? = nil
    
    @State private var scrollPosition = ScrollPosition()
    
    var body: some View {
        VStack(spacing: 0) {
            if let timelineItems = timeline?.timelineItems {
                ScrollViewReader { proxy in
                    ScrollView([.vertical]) {
                        VStack {
                                ForEach(timelineItems) { item in
                                    if let event = item.asEvent() {
                                        TimelineItemView(event: event).id(item.id)
                                    }
                                    if let _ = item.asVirtual() {
                                        Text("Virtual item").id(item.id)
                                    }
                                }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition($scrollPosition, anchor: .bottom)
                    .safeAreaPadding(.bottom, 10)
                    .scrollContentBackground(.hidden)
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: timeline?.timelineItems.count) { _, _ in
                        withAnimation {
                            scrollPosition.scrollTo(edge: .bottom)
                        }
                    }
                }
            } else {
                ProgressView()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
            }
            
            ChatInputView(room: room, timeline: timeline?.timeline)
        }
        .task(id: room) {
            do {
                self.timeline = try await RoomTimeline(room: room)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
