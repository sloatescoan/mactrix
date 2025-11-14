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
    
    
    var body: some Scene {
        WindowGroup(id: "main") {
            MainView()
        }
        .windowToolbarStyle(.unifiedCompact)
        .environment(appState)
        .commands {
            AppCommands()
        }
        
        Settings {
            SettingsView()
        }
        .environment(appState)
    }
    
    
}
