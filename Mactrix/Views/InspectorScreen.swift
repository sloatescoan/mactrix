import SwiftUI
import MatrixRustSDK
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
            case .joinedRoom(let room):
                UI.RoomInspectorView(room: room, members: room.fetchedMembers, roomInfo: room.roomInfo, imageLoader: appState.matrixClient, inspectorVisible: $windowState.inspectorVisible)
            case .previewRoom(let room):
                Text("Preview room: \(room.info().name ?? "unknown name")")
            case .none, .newRoom:
                Text("No room selected")
            }
        }
    }
    
    var body: some View {
        content
            .toolbar {
                Spacer()
                Button {
                    windowState.inspectorVisible.toggle()
                } label: {
                    Label("Toggle Inspector", systemImage: "info.circle")
                }
            }
    }
    
}
