import SwiftUI
import MatrixRustSDK

struct SidebarChannelView: View {
    @Environment(AppState.self) var appState
    
    @State private var selectedChannel: String? = nil
    
    var rooms: [Room] { appState.matrixClient?.rooms ?? [] }
    
    var body: some View {
        List(rooms, selection: $selectedChannel) { channel in
            HStack(alignment: .center) {
                RoomIcon()
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading) {
                    Spacer()
                    Text(channel.displayName() ?? "Unknown Room")
                    Spacer()
                    Divider()
                }
                
                Spacer()
            }
            .frame(height: 48)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.sidebar)
        .padding(.top, 10)
        .background()
    }
}

#Preview {
    SidebarChannelView()
}
