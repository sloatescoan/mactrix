//
//  AppState.swift
//  Mactrix
//
//  Created by Viktor Strate Kløvedal on 31/10/2025.
//

import Foundation
import Models

@MainActor
@Observable class AppState {
    var matrixClient: MatrixClient? = nil
    
    func reset() async throws {
        try await self.matrixClient?.reset()
        matrixClient = nil
    }
    
    static var previewMock: AppState {
        let appState = AppState()
        appState.matrixClient = .previewMock
        
        return appState
    }
}
