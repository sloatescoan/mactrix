import SwiftUI
import MatrixRustSDK
import UI

struct SpaceDisclosureGroup: View {
    @Environment(AppState.self) var appState
    
    @State var space: SidebarSpaceRoom
    
    @State private var isExpanded: Bool = false
    
    var spaceRow: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            switch space.children {
            case .loading:
                ProgressView("Loading rooms")
            case .loaded(let children):
                if children.paginationState == .loading {
                    ProgressView("Loading rooms")
                } else {
                    ForEach(children.rooms) { room in
                        SpaceDisclosureGroup(space: room)
                    }
                }
            case .error(let error):
                Text("Error: \(error.localizedDescription)")
                    .foregroundStyle(Color.red)
                    .textSelection(.enabled)
            }
        } label: {
            roomRow
        }
        .task(id: isExpanded) {
            print("space expanded \(isExpanded) \(space.spaceRoom.id)")
            if isExpanded {
                await space.loadChildren()
            }
        }
    }
    
    var roomRow: some View {
        UI.RoomRow(title: space.spaceRoom.displayName, avatarUrl: space.spaceRoom.avatarUrl, imageLoader: appState.matrixClient, placeholderImageName: "network")
    }
    
    var body: some View {
        if space.spaceRoom.roomType == .space {
            spaceRow
        } else {
            roomRow
        }
    }
}

struct SidebarView: View {
    @Environment(AppState.self) var appState
    
    var directs: [SidebarRoom] {
        (appState.matrixClient?.rooms ?? [])
            .filter { $0.roomInfo?.isDirect == true }
    }
    
    var rooms: [SidebarRoom] {
        (appState.matrixClient?.rooms ?? [])
            .filter { !$0.isSpace() && $0.roomInfo?.isDirect != true }
    }
    
    var spaces: [SidebarSpaceRoom] {
        appState.matrixClient?.spaceService.spaceRooms ?? []
    }
    
    @Binding var selectedRoomId: String?
    
    var body: some View {
        List(selection: $selectedRoomId) {
            Section("Directs") {
                ForEach(directs) { room in
                    UI.RoomRow(title: room.displayName() ?? "Unknown user", avatarUrl: room.avatarUrl(), imageLoader: appState.matrixClient, placeholderImageName: "person.fill")
                }
            }
            
            Section("Rooms") {
                ForEach(rooms) { room in
                    UI.RoomRow(title: room.displayName() ?? "Unknown Room", avatarUrl: room.avatarUrl(), imageLoader: appState.matrixClient)
                }
            }
            
            Section("Spaces") {
                ForEach(spaces) { space in
                    SpaceDisclosureGroup(space: space)
                }
            }
        }
    }
}

#Preview {
    SidebarView(selectedRoomId: .constant(nil))
}
