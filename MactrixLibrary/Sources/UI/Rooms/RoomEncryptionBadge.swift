import SwiftUI
import Models

public struct RoomEncryptionBadge: View {
    let state: EncryptionState
    
    public init(state: EncryptionState) {
        self.state = state
    }
    
    struct Badge {
        let label: String
        let icon: String
        let color: Color
    }
    
    var badge: Badge {
        switch state {
        case .encrypted:
            return Badge(label: "Encrypted", icon: "lock.fill", color: .green)
        case .notEncrypted:
            return Badge(label: "Not encrypted", icon: "lock.open.fill", color: .gray)
        case .unknown:
            return Badge(label: "Unknown", icon: "questionmark", color: .gray)
        }
    }
    
    public var body: some View {
        Label(badge.label, systemImage: badge.icon)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .foregroundStyle(badge.color.mix(with: .black, by: 0.1))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(badge.color.quaternary)
                    .stroke(badge.color)
            )
            .padding()
    }
}

#Preview {
    RoomEncryptionBadge(state: .encrypted)
    RoomEncryptionBadge(state: .notEncrypted)
    RoomEncryptionBadge(state: .unknown)
}
