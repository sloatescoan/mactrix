import SwiftUI
import MatrixRustSDK
import UI

struct MainView: View {
    @Environment(AppState.self) var appState
    
    @State private var windowState = WindowState()
    
    @State private var showWelcomeSheet: Bool = false
    
    @SceneStorage("MainView.selectedRoomId")
    private var selectedRoomId: String?
    
    @ViewBuilder var details: some View {
        switch windowState.selectedScreen {
        case .joinedRoom(let room):
            ChatView(room: room).id(room.id)
        case .previewRoom(let room):
            Text("Room Preview: \(room.info().name ?? "unknown name")")
            if let topic = room.info().topic {
                Text("Topic: \(topic)")
            }
        case .newRoom:
            UI.CreateRoomScreen(onSubmit: { params in
                guard let matrixClient = appState.matrixClient else { return }
                let newRoom = try await matrixClient.client.createRoom(request: params.asMatrixRequest)
                selectedRoomId = newRoom
            })
        case .none:
            ContentUnavailableView("Select a room", systemImage: "message.fill")
        }
    }
    
    var body: some View {
        NavigationSplitView(
            sidebar: { SidebarView(selectedRoomId: $selectedRoomId) },
            detail: { details }
        )
        .environment(windowState)
        .inspector(isPresented: windowState.inspectorOrSearchActive, content: {
            InspectorScreen()
                .environment(windowState)
        })
        .task { await attemptLoadUserSession() }
        .sheet(isPresented: $showWelcomeSheet, onDismiss: onLoginModalDismiss ) {
            WelcomeSheetView()
        }
        .onChange(of: appState.matrixClient == nil) { _, matrixClientIsNil in
            if matrixClientIsNil {
                print("Matrix client is nil, present welcome sheet")
                showWelcomeSheet = true
            }
        }
        .task(id: selectedRoomId) {
            await onRoomSelected()
        }
        .onChange(of: appState.matrixClient?.authenticationFailed) { _, authFailed in
            if authFailed == true {
                print("Logging out since auth failed")
                appState.matrixClient = nil
            }
        }
        .searchable(text: $windowState.searchQuery, tokens: $windowState.searchTokens, isPresented: $windowState.searchFocused, placement: .automatic, prompt: "Search") { token in
            switch token {
            case .users:
                Text("Users")
            case .rooms:
                Text("Public Rooms")
            case .spaces:
                Text("Public Spaces")
            case .messages:
                Text("Messages")
            }
        }
        .searchSuggestions {
            if windowState.searchTokens.isEmpty {
                Label("Users", systemImage: "person").searchCompletion(SearchToken.users)
                Label("Public Rooms", systemImage: "number").searchCompletion(SearchToken.rooms)
                Label("Public Spaces", systemImage: "network").searchCompletion(SearchToken.spaces)
                Label("Messages", systemImage: "magnifyingglass.circle").searchCompletion(SearchToken.messages)
            }
        }
    }
    
    func attemptLoadUserSession() async {
        guard appState.matrixClient == nil else { return }
        
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
            
            // check if a room is selected and load it
            await onRoomSelected()
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
    
    func onRoomSelected() async {
        guard let matrixClient = appState.matrixClient else { return }
        
        do {
            print("Selected room: \(selectedRoomId.debugDescription)")
            
            if let roomId = selectedRoomId {
                if let selectedRoom = try matrixClient.client.getRoom(roomId: roomId) {
                    self.windowState.selectedScreen = .joinedRoom(LiveRoom(matrixRoom: selectedRoom))
                } else {
                    let roomPreview = try await matrixClient.client.getRoomPreviewFromRoomId(roomId: roomId, viaServers: ["matrix.org"])
                    
                    print("Selected room preview: \(roomPreview.info())")
                    self.windowState.selectedScreen = .previewRoom(roomPreview)
                }
            } else {
                self.windowState.selectedScreen = .none
            }
        } catch {
            print("Failed to get room \(error)")
        }
    }
}

#Preview {
    MainView()
}
