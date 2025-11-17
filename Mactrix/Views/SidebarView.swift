import SwiftUI
import MatrixRustSDK
import UI

struct SpaceDisclosureGroup: View {
    @Environment(AppState.self) var appState
    @Environment(WindowState.self) var windowState
    
    @State var space: SidebarSpaceRoom
    @State private var isExpanded: Bool = false
    
    @Binding var selectedRoomId: String?
    
    var loadingRooms: some View {
        Label {
            Text("Loading rooms")
                .foregroundStyle(.secondary)
        } icon: {
            ProgressView().scaleEffect(0.5)
        }
    }
    
    var spaceRow: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            switch space.children {
            case .loading:
                loadingRooms
            case .loaded(let children):
                if children.paginationState == .loading {
                    loadingRooms
                } else {
                    ForEach(children.rooms) { room in
                        SpaceDisclosureGroup(space: room, selectedRoomId: $selectedRoomId)
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
            if isExpanded {
                await space.loadChildren()
            }
        }
    }
    
    var joinRoom: (() async throws -> Void)? {
        if appState.matrixClient?.rooms.contains(where: { $0.id() == space.id }) == false {
            return {
                print("Joining room: \(space.id)")
                guard let matrixClient = appState.matrixClient else { return }
                let room = try await matrixClient.client.joinRoomById(roomId: space.id)
                windowState.selectedScreen = .joinedRoom(LiveRoom(matrixRoom: room))
            }
        }
        
        return nil
    }
    
    var joinedRoom: SidebarRoom? {
        return appState.matrixClient?.rooms.first(where: { $0.id() == space.id })
    }
    
    @ViewBuilder
    var roomRow: some View {
        if let joinedRoom {
            UI.RoomRow(
                title: space.spaceRoom.displayName,
                avatarUrl: space.spaceRoom.avatarUrl,
                roomInfo: joinedRoom.roomInfo,
                imageLoader: appState.matrixClient,
                joinRoom: nil
            )
            .contextMenu {
                RoomContextMenu(room: joinedRoom, selectedRoomId: $selectedRoomId)
            }
        } else {
            UI.RoomRow(
                title: space.spaceRoom.displayName,
                avatarUrl: space.spaceRoom.avatarUrl,
                roomInfo: nil,
                imageLoader: appState.matrixClient,
                joinRoom: joinRoom
            )
        }
        
    }
    
    var body: some View {
        if space.spaceRoom.roomType == .space {
            spaceRow
        } else {
            roomRow
        }
    }
}

struct RoomContextMenu: View {
    let room: SidebarRoom
    @Binding var selectedRoomId: String?
    
    var body: some View {
        if let roomInfo = room.roomInfo {
            Button {
                Task {
                    do {
                        print("marking room unread/read")
                        try await room.setUnreadFlag(newValue: !roomInfo.isMarkedUnread)
                    } catch {
                        print("failed to mark room unread/read: \(error)")
                    }
                }
            } label: {
                if roomInfo.isMarkedUnread {
                    Text("Mark as Read")
                } else {
                    Text("Mark as Unread")
                }
            }

            
            Button {
                Task {
                    do {
                        print("mark room favourite: \(!roomInfo.isFavourite)")
                        try await room.setIsFavourite(isFavourite: !roomInfo.isFavourite, tagOrder: nil)
                    } catch {
                        print("failed to mark room favourite: \(error)")
                    }
                }
                
            } label: {
                if roomInfo.isFavourite {
                    Label("Unfavorite", systemImage: "heart.slash")
                } else {
                    Label("Favorite", systemImage: "heart")
                }
            }
        }
        
        Button {
            Task {
                do {
                    print("leaving room: \(room.id())")
                    try await room.leave()
                    try await room.forget()
                    
                    if selectedRoomId == room.id() {
                        selectedRoomId = nil
                    }
                } catch {
                    print("failed to leave room: \(error)")
                }
            }
        } label: {
            Label("Leave Room", systemImage: "minus.circle")
        }
    }
}

struct SidebarView: View {
    @Environment(AppState.self) var appState
    @Environment(WindowState.self) var windowState
    
    @State private var searchText: String = ""
    
    var favorites: [SidebarRoom] {
        (appState.matrixClient?.rooms ?? [])
            .filter { $0.roomInfo?.isFavourite == true }
    }
    
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
    
    var syncState: String {
        switch appState.matrixClient?.syncState {
        case .idle:
            "idle"
        case .running:
            "online"
        case .terminated:
            "terminated"
        case .error:
            "error"
        case .offline:
            "offline"
        case nil:
            "logged out"
        }
    }
    
    var body: some View {
        List(selection: $selectedRoomId) {
            
            Text("Sync: \(syncState)")
                .foregroundStyle(.secondary)
            
            if !favorites.isEmpty {
                Section("Favorites") {
                    ForEach(favorites) { room in
                        UI.RoomRow(
                            title: room.displayName() ?? "Unknown room",
                            avatarUrl: room.avatarUrl(),
                            roomInfo: room.roomInfo,
                            imageLoader: appState.matrixClient,
                            joinRoom: nil
                        )
                        .contextMenu {
                            RoomContextMenu(room: room, selectedRoomId: $selectedRoomId)
                        }
                    }
                }
            }
            
            Section("Directs") {
                ForEach(directs) { room in
                    UI.RoomRow(
                        title: room.displayName() ?? "Unknown user",
                        avatarUrl: room.avatarUrl(),
                        roomInfo: room.roomInfo,
                        imageLoader: appState.matrixClient,
                        joinRoom: nil
                    )
                    .contextMenu {
                        RoomContextMenu(room: room, selectedRoomId: $selectedRoomId)
                    }
                }
            }
            
            Section("Rooms") {
                ForEach(rooms) { room in
                    UI.RoomRow(
                        title: room.displayName() ?? "Unknown Room",
                        avatarUrl: room.avatarUrl(),
                        roomInfo: room.roomInfo,
                        imageLoader: appState.matrixClient,
                        joinRoom: nil
                    )
                    .contextMenu {
                        RoomContextMenu(room: room, selectedRoomId: $selectedRoomId)
                    }
                }
            }
            
            Section("Spaces") {
                ForEach(spaces) { space in
                    SpaceDisclosureGroup(space: space, selectedRoomId: $selectedRoomId)
                }
            }
        }
    }
}

#Preview {
    SidebarView(selectedRoomId: .constant(nil))
}
