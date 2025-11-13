import SwiftUI
import MatrixRustSDK
import UI

struct MainView: View, UI.RoomInspectorActions {
    @Environment(AppState.self) var appState
    
    @State private var showWelcomeSheet: Bool = false
    @State private var inspectorVisible: Bool = false
    @State private var selectedRoomId: String? = nil
    
    @ViewBuilder var details: some View {
        if let room = appState.matrixClient?.selectedRoom {
            ChatView(room: room).id(room.id)
        } else {
            ContentUnavailableView("Select a room", systemImage: "message.fill")
        }
    }
    
    var body: some View {
        NavigationSplitView(
            sidebar: { SidebarView(selectedRoomId: $selectedRoomId) },
            detail: { details }
        )
        .inspector(isPresented: $inspectorVisible, content: {
            if let room = appState.matrixClient?.selectedRoom {
                UI.RoomInspectorView(room: room, members: room.fetchedMembers, inspectorVisible: $inspectorVisible, actions: self)
            } else {
                Text("No room selected")
            }
        })
        .task { await attemptLoadUserSession() }
        .sheet(isPresented: $showWelcomeSheet, onDismiss: onLoginModalDismiss ) {
            WelcomeSheetView()
        }
        .onChange(of: appState.matrixClient == nil) { _, matrixClientIsNil in
            if matrixClientIsNil {
                showWelcomeSheet = true
            }
        }
        .onChange(of: selectedRoomId) { oldValue, newValue in
            if let roomId = selectedRoomId, let selectedRoom = appState.matrixClient?.rooms.first(where: { $0.id() == roomId }) {
                appState.matrixClient?.selectedRoom = LiveRoom(room: selectedRoom)
            } else {
                appState.matrixClient?.selectedRoom = nil
            }
        }
        .onChange(of: appState.matrixClient?.authenticationFailed) { _, authFailed in
            if authFailed == true {
                print("Logging out since auth failed")
                appState.matrixClient = nil
            }
        }
    }
    
    func attemptLoadUserSession() async {
        do {
            if let matrixClient = try await MatrixClient.attemptRestore() {
                appState.matrixClient = matrixClient
            }
        } catch {
            print("Failed to restore session: \(error)")
        }
        
        showWelcomeSheet = appState.matrixClient == nil
        if let matrixClient = appState.matrixClient {
            onMatrixLoaded(matrixClient: matrixClient)
        }
    }
    
    func onMatrixLoaded(matrixClient: MatrixClient) {
        Task {
            try await matrixClient.startSync()
        }
    }
    
    func onLoginModalDismiss() {
        Task {
            try await Task.sleep(for: .milliseconds(100))
            if let matrixClient = appState.matrixClient {
                onMatrixLoaded(matrixClient: matrixClient)
            } else {
                NSApp.terminate(nil)
            }
        }
    }
    
    func syncMembers() async throws {
        try await appState.matrixClient?.selectedRoom?.syncMembers()
    }
}

#Preview {
    MainView()
}
