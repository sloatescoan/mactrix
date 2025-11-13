import SwiftUI
import MatrixRustSDK
import UI

struct AvatarImage: View {
    @Environment(AppState.self) private var appState
    
    let avatarUrl: String?
    let placeholder: (() -> AnyView)?
    
    init(avatarUrl: String?, placeholder: (() -> AnyView)? = nil) {
        self.avatarUrl = avatarUrl
        self.placeholder = placeholder
    }
    
    @State private var avatar: Image? = nil
    
    @ViewBuilder
    var imageOrPlaceholder: some View {
        if let avatar = avatar {
            avatar.resizable()
        } else {
            if let placeholder = placeholder {
                placeholder()
            } else {
                Rectangle().foregroundStyle(Color.gray)
            }
        }
    }
    
    var body: some View {
        imageOrPlaceholder
            .aspectRatio(1.0, contentMode: .fit)
            .task(id: avatarUrl) {
                guard let avatarUrl = avatarUrl else { return }
                guard let imageData = try? await appState.matrixClient?.client.getUrl(url: avatarUrl) else { return }
                avatar = try? await Image(importing: imageData, contentType: nil)
            }
    }
}

struct RoomIcon: View {
    @Environment(AppState.self) var appState
    
    let room: Room
    let placeholderImageName: String
    
    init(room: Room, placeholderImageName: String = "number") {
        self.room = room
        self.placeholderImageName = placeholderImageName
    }
    
    var body: some View {
        UI.AvatarImage(avatarUrl: room.avatarUrl(), imageLoader: appState.matrixClient) {
            Image(systemName: placeholderImageName)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
    
    var spaces: [SidebarRoom] {
        (appState.matrixClient?.rooms ?? [])
            .filter { $0.isSpace() }
    }
    
    @Binding var selectedRoomId: String?
    
    var body: some View {
        List(selection: $selectedRoomId) {
            Section("Directs") {
                ForEach(directs) { room in
                    Label(
                        title: { Text(room.displayName() ?? "Unknown Room") },
                        icon: { RoomIcon(room: room, placeholderImageName: "person.fill") }
                    ).listItemTint(.gray)
                }
            }
            
            Section("Rooms") {
                ForEach(rooms) { room in
                    Label(
                        title: { Text(room.displayName() ?? "Unknown Room") },
                        icon: { RoomIcon(room: room) }
                    ).listItemTint(.gray)
                }
            }
            
            Section("Spaces") {
                ForEach(spaces) { room in
                    Label(
                        title: { Text(room.displayName() ?? "Unknown Space") },
                        icon: { RoomIcon(room: room, placeholderImageName: "network") }
                    ).listItemTint(.gray)
                }
            }
        }
    }
}

#Preview {
    SidebarView(selectedRoomId: .constant(nil))
}
