import SwiftUI
import MatrixRustSDK
import UI

struct SearchInspectorView: View {
    @Environment(AppState.self) var appState
    @Environment(WindowState.self) var windowState
    
    @State var searchedUsers: [UserProfile] = []
    @State var searching: Bool = false
    
    @ViewBuilder
    var searchUsers: some View {
        List {
            Section("User search results") {
                if searching {
                    Group {
                        Text("First user")
                        Text("Second user")
                        Text("Third user")
                    }.redacted(reason: .placeholder)
                } else {
                    ForEach(searchedUsers) { user in
                        UI.UserProfileRow(userProfile: user, imageLoader: appState.matrixClient)
                    }
                }
            }
        }
        .task(id: windowState.searchQuery) {
            do {
                guard let matrixClient = appState.matrixClient else { return }
                guard !windowState.searchQuery.isEmpty else {
                    searchedUsers = []
                    return
                }
                
                searching = true
                defer { searching = false }
                
                try await Task.sleep(for: .milliseconds(500))
                
                let results = try await matrixClient.client.searchUsers(searchTerm: windowState.searchQuery, limit: 100)
                
                searchedUsers = results.results
            } catch is CancellationError {
                /* search cancelled */
            } catch {
                print("user search failed: \(error)")
            }
        }
    }
    
    @ViewBuilder
    var viewSelector: some View {
        if windowState.searchTokens.contains(.messages) {
            Text("Search messages")
        } else if windowState.searchTokens.contains(.rooms) {
            Text("Search rooms")
        } else if windowState.searchTokens.contains(.spaces) {
            Text("Search spaces")
        } else if windowState.searchTokens.contains(.users) {
            searchUsers
        } else {
            Text("Select a search term")
        }
    }
    
    var body: some View {
        viewSelector
            .inspectorColumnWidth(min: 300, ideal: 300, max: 400)
    }
}
