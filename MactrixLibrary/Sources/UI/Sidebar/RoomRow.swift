import SwiftUI

public struct RoomRow: View {
    let title: String
    let avatarUrl: String?
    let placeholderImageName: String
    let imageLoader: ImageLoader?
    
    public init(title: String, avatarUrl: String?, imageLoader: ImageLoader?, placeholderImageName: String = "number") {
        self.title = title
        self.avatarUrl = avatarUrl
        self.imageLoader = imageLoader
        self.placeholderImageName = placeholderImageName
    }
    
    public var body: some View {
        Label(
            title: { Text(title) },
            icon: {
                UI.AvatarImage(avatarUrl: avatarUrl, imageLoader: imageLoader) {
                    Image(systemName: placeholderImageName)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        )
        .listItemTint(.gray)
    }
}

#Preview {
    List {
        Section("Rooms") {
            RoomRow(title: "Room row 1", avatarUrl: nil, imageLoader: nil, placeholderImageName: "number")
            RoomRow(title: "Room row 2", avatarUrl: nil, imageLoader: nil, placeholderImageName: "number")
            RoomRow(title: "Room row 3", avatarUrl: nil, imageLoader: nil, placeholderImageName: "number")
        }
    }
    .listStyle(.sidebar)
    .frame(width: 200)
}
