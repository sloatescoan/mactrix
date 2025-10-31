//
//  MactrixApp.swift
//  Mactrix
//
//  Created by Viktor Strate Kløvedal on 30/10/2025.
//

import SwiftUI

let applicationID = "dk.qpqp.mactrix"

@main
struct MactrixApp: App {
    
    @State var appState = AppState()
    @State private var showWelcomeSheet: Bool = false
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .task { await attemptLoadUserSession() }
                .sheet(isPresented: $showWelcomeSheet, onDismiss: {
                    Task {
                        try await Task.sleep(for: .milliseconds(100))
                        if let matrixClient = appState.matrixClient {
                            onMatrixLoaded(matrixClient: matrixClient)
                        } else {
                            NSApp.terminate(nil)
                        }
                    }
                }) {
                    WelcomeSheetView()
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .environment(appState)
        
        Settings {
            SettingsView()
        }
    }
    
    func attemptLoadUserSession() async {
        do {
            if let matrixClient = try await MatrixClient.attemptRestore() {
                appState.matrixClient = matrixClient
            }
        } catch {
            print(error)
        }
        
        showWelcomeSheet = appState.matrixClient == nil
        if let matrixClient = appState.matrixClient {
            onMatrixLoaded(matrixClient: matrixClient)
        }
    }
    
    func onMatrixLoaded(matrixClient: MatrixClient) {
        Task {
            print("Matrix sync starting")
            try await matrixClient.startSync()
            print("Matrix sync done")
        }
    }
}
