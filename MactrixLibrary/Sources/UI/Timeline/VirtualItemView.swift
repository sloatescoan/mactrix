import SwiftUI
import Models

public struct VirtualItemView: View {
    let item: VirtualTimelineItem
    
    public init(item: VirtualTimelineItem) {
        self.item = item
    }
    
    public var body: some View {
        switch item {
        case .dateDivider(let date):
            Text("Date: \(date.formatted())")
        case .readMarker:
            Text("Read Marker")
        case .timelineStart:
            Text("Start of conversation")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VirtualItemView(item: .timelineStart)
        VirtualItemView(item: .dateDivider(date: Date()))
        VirtualItemView(item: .readMarker)
    }.padding()
}
