import MatrixRustSDK
import SwiftUI
import UI

struct InspectorScreen: View {
    @Environment(AppState.self) var appState
    @Environment(WindowState.self) var windowState

    @ViewBuilder
    var content: some View {
        @Bindable var windowState = windowState

        if windowState.searchFocused {
            SearchInspectorView()
        } else {
            switch windowState.selectedScreen {
            case let .joinedRoom(room, timeline: timeline):
                if let thread = timeline.focusedThreadTimeline {
                    VStack(spacing: 0) {
                        UI.ThreadTimelineHeader {
                            withAnimation {
                                windowState.inspectorVisible = false
                            }
                            Task {
                                try? await Task.sleep(for: .milliseconds(500))
                                timeline.focusedThreadTimeline = nil
                            }
                        }
                        ChatView(room: room, timeline: thread)
                    }
                    .inspectorColumnWidth(min: 200, ideal: 400, max: 800)
                } else {
                    UI.RoomInspectorView(room: room, members: room.fetchedMembers, roomInfo: room.roomInfo, imageLoader: appState.matrixClient, inspectorVisible: $windowState.inspectorVisible)
                }
            case let .previewRoom(room):
                Text("Preview room: \(room.info().name ?? "unknown name")")
            case .none, .newRoom:
                Text("No room selected")
            }
        }
    }

    var body: some View {
        @Bindable var windowState = windowState

        content
            .toolbar {
                Button {
                    windowState.toggleInspector()
                } label: {
                    Label("Toggle Inspector", systemImage: "info.circle")
                }
                .help("Toggle Inspector")
            }
    }
}
