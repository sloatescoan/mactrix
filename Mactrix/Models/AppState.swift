//
//  AppState.swift
//  Mactrix
//
//  Created by Viktor Strate Kløvedal on 31/10/2025.
//

import Foundation

@MainActor
@Observable class AppState {
    var matrixClient: MatrixClient? = nil
}
