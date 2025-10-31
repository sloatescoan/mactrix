//
//  SidebarSpacesView.swift
//  Mactrix
//
//  Created by Viktor Strate Kløvedal on 31/10/2025.
//

import SwiftUI
import MatrixRustSDK

struct SpaceIcon: View {
    let room: Room
    let selected: Bool
    
    @Environment(AppState.self) var appState
    
    @State private var icon: Image? = nil
    
    var nameInitials: String {
        guard let name = room.displayName() else { return "" }
        return String(name.prefix(2))
    }
    
    var body: some View {
        ZStack {
            if let icon = icon {
                icon
                    .resizable()
            } else {
                Text(nameInitials)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .background(.red)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.controlAccentColor).opacity(selected ? 1 : 0), lineWidth: 3)
        )
        .task {
            guard let avatarUrlStr = room.avatarUrl() else { return }
            //guard let avatarUrl = URL(string: avatarUrlStr) else { return }
            guard let matrixClient = appState.matrixClient?.client else { return }
            
            do {
                let data = try await matrixClient.getMediaContent(mediaSource: .fromUrl(url: avatarUrlStr))
                icon = try await Image(importing: data, contentType: nil)
            } catch {
                print("Failed to fetch space avatar: \(error)")
            }
        }
    }
}

struct SidebarSpacesView: View {
    
    @Environment(AppState.self) var appState
    
    //let spaces = ["First Space", "Second Space", "Third Space"]
    @State private var selectedSpaceId: String? = nil
    
    var spaces: [Room] {
        let allRooms = appState.matrixClient?.rooms ?? []
        return allRooms.filter { $0.isSpace() }
    }
    
    var body: some View {
        List(spaces, selection: $selectedSpaceId) { room in
            SpaceIcon(room: room, selected: room.id() == selectedSpaceId)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color(NSColor.controlBackgroundColor))
        }
        .listStyle(.plain)
        .padding(.top, 6)
        .frame(width: 56)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay( Divider()
            .frame(maxWidth: 1, maxHeight: .infinity)
            .background(Color(NSColor.separatorColor)), alignment: .trailing)
    }
}

#Preview {
    SidebarSpacesView()
}
