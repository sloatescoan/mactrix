import SwiftUI
import Models

public struct RoomInspectorView<R: Room>: View {
    let room: R
    @Binding var inspectorVisible: Bool
    
    public init(room: R, inspectorVisible: Binding<Bool>) {
        self.room = room
        self._inspectorVisible = inspectorVisible
    }
    
    public var body: some View {
        VStack {
            Text(room.displayName ?? "Unknown Room").font(.title)
            Text(room.topic ?? "No Topic")
            
            RoomEncryptionBadge(state: room.encryptionState)
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
    RoomInspectorView(room: MockRoom.previewRoom, inspectorVisible: .constant(true))
        .frame(width: 200, height: 300)
}
