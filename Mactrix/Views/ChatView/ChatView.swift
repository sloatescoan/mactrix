import SwiftUI
import MatrixRustSDK
import Models
import UI

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
    
    let room: MatrixRustSDK.Room
    @State private var timeline: LiveTimeline? = nil
    
    @State private var errorMessage: String? = nil
    
    @State private var scrollPosition: String? = nil
    
    func loadMoreMessages() {
        print("Reached top, fetching more messages...")
        Task {
            try await self.timeline?.fetchOlderMessages()
        }
    }
    
    @ViewBuilder
    var timelineItemsView: some View {
        if let timelineItems = timeline?.timelineItems {
                    LazyVStack {
                            ForEach(timelineItems) { item in
                                if let event = item.asEvent() {
                                    TimelineItemView(event: event)
                                        .id(item.id)
                                }
                                if let virtual = item.asVirtual() {
                                    UI.VirtualItemView(item: virtual.asModel)
                                        .id(item.id)
                                }
                            }
                    }
                    .scrollTargetLayout()
        } else {
            ProgressView()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView([.vertical]) {
                
                if timeline?.paginating == .paginating {
                    ProgressView("Loading more messages")
                }
                
                Text(room.displayName() ?? "Unknown room")
                    .onScrollVisibilityChange { isVisible in
                        if isVisible {
                            loadMoreMessages()
                        }
                    }
                
                timelineItemsView
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity)
                }
                
            }
            .scrollPosition(id: $scrollPosition, anchor: .bottom)
            .safeAreaPadding(.bottom, 10)
            .safeAreaPadding(.top, 20)
            .scrollContentBackground(.hidden)
            .defaultScrollAnchor(.bottom)
            
            ChatInputView(room: room, timeline: timeline?.timeline)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle(room.displayName() ?? "Unknown room")
        .frame(minWidth: 250, minHeight: 200)
        .task(id: room) {
            do {
                self.timeline = try await LiveTimeline(room: room)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
        .onChange(of: self.timeline?.timelineItems) { prev, now in
            if let now = now {
                if let prev = prev {
                    let prevId = prev.last?.id
                    let nowId = now.last?.id
                    if prevId != nowId && now.count > prev.count {
                        Task {
                            await Task.yield()
                            withAnimation {
                                self.scrollPosition = self.timeline?.timelineItems.last?.id
                            }
                        }
                    }
                } else {
                    print("Initial scroll to bottom")
                    Task {
                        // disable animation on first load
                        await Task.yield()
                        self.scrollPosition = self.timeline?.timelineItems.last?.id
                    }
                }
            }
        }
    }
}
