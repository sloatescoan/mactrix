import SwiftUI
import MatrixRustSDK

struct WelcomeSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var homeserverField: String = ""
    @State private var usernameField: String = ""
    @State private var passwordField: String = ""
    
    @State private var loading: Bool = true
    @State private var showError: Error? = nil
    
    var body: some View {
        VStack {
            Text("Welcome to Mactrix")
                .font(.headline)
                .padding(.bottom)
            
            Form {
                TextField("Homeserver", text: $homeserverField)
                    .disabled(loading)
                TextField("Username", text: $usernameField)
                    .disabled(loading)
                SecureField("Password", text: $passwordField)
                    .disabled(loading)
                
                HStack {
                    Button("Sign in") {
                        Task {
                            loading = true
                            
                            do {
                                let client = try await MatrixClient.login(homeServer: homeserverField, username: usernameField, password: passwordField)
                                appState.matrixClient = client
                            } catch {
                                showError = error
                            }
                            
                            loading = false
                            dismiss()
                        }
                    }
                    .disabled(loading)
                    Button("Register account") {}
                        .buttonStyle(.link)
                        .disabled(loading)
                    ProgressView()
                        .scaleEffect(0.5)
                        .opacity(loading ? 1 : 0)
                }
            }
            .frame(maxWidth: 300)
            
            if let showError = showError {
                Text(showError.localizedDescription)
                    .foregroundStyle(Color.red)
                    .textSelection(.enabled)
            }
            
        }
        .padding()
    }
    
    
}

#Preview {
    WelcomeSheetView()
        .environment(AppState())
}
