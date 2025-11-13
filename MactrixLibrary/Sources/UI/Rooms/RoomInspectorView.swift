import SwiftUI
import Models

struct RoomInspectorMemberRow<RoomMember: Models.RoomMember>: View {
    let member: RoomMember
    
    var body: some View {
        Text(member.displayName ?? member.userId)
    }
}

@MainActor
public protocol RoomInspectorActions {
    func syncMembers() async throws
}

struct MockRoomInspectorActions: RoomInspectorActions {
    func syncMembers() async throws {}
}

public struct RoomInspectorView<Room: Models.Room, RoomMember: Models.RoomMember, Actions: RoomInspectorActions>: View {
    let room: Room
    let members: [RoomMember]?
    let actions: Actions
    
    @Binding var inspectorVisible: Bool
    
    public init(room: Room, members: [RoomMember]?, inspectorVisible: Binding<Bool>, actions: Actions) {
        self.room = room
        self.members = members
        self._inspectorVisible = inspectorVisible
        self.actions = actions
    }
    
    @ViewBuilder
    func userSection(title: LocalizedStringResource, allMembers: [RoomMember], withRole role: RoomMemberRole) -> some View {
        let roleMembers = allMembers.filter { $0.roleForPowerLevel == role }
        Section("\(title) (\(roleMembers.count))") {
            ForEach(roleMembers) { member in
                RoomInspectorMemberRow(member: member)
            }
        }
    }
    
    @ViewBuilder
    var usersPlaceholder: some View {
        Group {
            Section("Admins (2)") {
                Text("First admin")
                Text("Second admin")
            }
            
            Section("Users (4)") {
                Text("First user")
                Text("Second user")
                Text("Third user")
                Text("Fourth user")
            }
        }
        .redacted(reason: .placeholder)
    }
    
    public var body: some View {
        List {
            VStack(alignment: .center) {
                Text(room.displayName ?? "Unknown Room").font(.title)
                Text(room.topic ?? "No Topic")
                
                RoomEncryptionBadge(state: room.encryptionState)
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            
            if let members = members {
                userSection(title: "Admins", allMembers: members, withRole: .administrator)
                userSection(title: "Moderators", allMembers: members, withRole: .moderator)
                userSection(title: "Users", allMembers: members, withRole: .user)
            } else {
                usersPlaceholder
                    .task(id: room.id) {
                        do {
                            try await actions.syncMembers()
                        } catch {
                            print("Failed to sync members in inspector: \(error)")
                        }
                    }
            }
        }
        .inspectorColumnWidth(min: 200, ideal: 250, max: 400)
        .toolbar {
            Spacer()
            Button {
                inspectorVisible.toggle()
            } label: {
                Label("Toggle Inspector", systemImage: "info.circle")
            }
        }
    }
}


#Preview {
    RoomInspectorView<MockRoom, MockRoomMember, MockRoomInspectorActions>
        .init(room: MockRoom.previewRoom, members: nil, inspectorVisible: .constant(true), actions: MockRoomInspectorActions())
        .frame(width: 250, height: 500)
}
