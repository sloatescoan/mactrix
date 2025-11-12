import Foundation
import MatrixRustSDK

@Observable public final class LiveTimeline {
    public let timeline: Timeline
    var timelineHandle: TaskHandle?
    var paginateHandle: TaskHandle?
    
    public private(set) var timelineItems: [TimelineItem] = []
    public private(set) var paginating: RoomPaginationStatus = .idle(hitTimelineStart: false)
    public private(set) var hitTimelineStart: Bool = false
    
    public init(room: MatrixRustSDK.Room) async throws {
        timeline = try await room.timeline()
        
        // Listen to timeline item updates.
        timelineHandle = await timeline.addListener(listener: self)
        
        // Listen to paginate loading status updates.
        paginateHandle = try await timeline.subscribeToBackPaginationStatus(listener: self)
    }
    
    public func fetchOlderMessages() async throws {
        guard paginating == .idle(hitTimelineStart: false) else { return }
        
        let _ = try await timeline.paginateBackwards(numEvents: 100)
    }
}

extension LiveTimeline: TimelineListener {
    public func onUpdate(diff: [TimelineDiff]) {
        for update in diff {
            switch update {
            case .append(let values):
                timelineItems.append(contentsOf: values)
            case .clear:
                timelineItems.removeAll()
            case .pushFront(let room):
                timelineItems.insert(room, at: 0)
            case .pushBack(let room):
                timelineItems.append(room)
            case .popFront:
                timelineItems.removeFirst()
            case .popBack:
                timelineItems.removeLast()
            case .insert(let index, let room):
                timelineItems.insert(room, at: Int(index))
            case .set(let index, let room):
                timelineItems[Int(index)] = room
            case .remove(let index):
                timelineItems.remove(at: Int(index))
            case .truncate(let length):
                timelineItems.removeSubrange(Int(length)..<timelineItems.count)
            case .reset(values: let values):
                timelineItems = values
            }
        }
    }
}

extension LiveTimeline: PaginationStatusListener {
    public func onUpdate(status: MatrixRustSDK.RoomPaginationStatus) {
        self.paginating = status
    }
}
