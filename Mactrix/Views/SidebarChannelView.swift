import SwiftUI
import MatrixRustSDK

struct SidebarChannelView: View {
    @Environment(AppState.self) var appState
    
    var rooms: [Room] { appState.matrixClient?.rooms ?? [] }
    
    var body: some View {
        List(rooms) { room in
            NavigationLink(destination: { ChatView(room: room) }) {
                HStack(alignment: .center) {
                    RoomIcon()
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading) {
                        Spacer()
                        Text(room.displayName() ?? "Unknown Room")
                        Spacer()
                        //Divider()
                    }
                    
                    Spacer()
                }
                .frame(height: 48)
                .listRowSeparator(.visible)
                //.listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listStyle(.sidebar)
        //.safeAreaPadding(.top, 10)
        //.background()
    }
}

#Preview {
    SidebarChannelView()
}
