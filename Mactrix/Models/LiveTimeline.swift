import Foundation
import MatrixRustSDK

@MainActor
@Observable public final class LiveTimeline {
    public let timeline: Timeline
    var timelineHandle: TaskHandle?
    var paginateHandle: TaskHandle?

    public private(set) var timelineItems: [TimelineItem] = []
    public private(set) var paginating: RoomPaginationStatus = .idle(hitTimelineStart: false)
    public private(set) var hitTimelineStart: Bool = false

    public init(room: MatrixRustSDK.Room) async throws {
        let config = TimelineConfiguration(
            focus: .live(hideThreadedEvents: true),
            filter: .all,
            internalIdPrefix: nil,
            dateDividerMode: .daily,
            trackReadReceipts: true,
            reportUtds: false
        )
        timeline = try await room.timelineWithConfiguration(configuration: config)

        // Listen to timeline item updates.
        timelineHandle = await timeline.addListener(listener: self)

        // Listen to paginate loading status updates.
        paginateHandle = try await timeline.subscribeToBackPaginationStatus(listener: self)
    }

    public func fetchOlderMessages() async throws {
        guard paginating == .idle(hitTimelineStart: false) else { return }

        _ = try await timeline.paginateBackwards(numEvents: 200)
    }
}

extension LiveTimeline: @MainActor TimelineListener {
    public func onUpdate(diff: [TimelineDiff]) {
        for update in diff {
            switch update {
            case let .append(values):
                timelineItems.append(contentsOf: values)
            case .clear:
                timelineItems.removeAll()
            case let .pushFront(room):
                timelineItems.insert(room, at: 0)
            case let .pushBack(room):
                timelineItems.append(room)
            case .popFront:
                timelineItems.removeFirst()
            case .popBack:
                timelineItems.removeLast()
            case let .insert(index, room):
                timelineItems.insert(room, at: Int(index))
            case let .set(index, room):
                timelineItems[Int(index)] = room
            case let .remove(index):
                timelineItems.remove(at: Int(index))
            case let .truncate(length):
                timelineItems.removeSubrange(Int(length) ..< timelineItems.count)
            case let .reset(values: values):
                timelineItems = values
            }
        }
    }
}

extension LiveTimeline: @MainActor PaginationStatusListener {
    public func onUpdate(status: MatrixRustSDK.RoomPaginationStatus) {
        paginating = status
    }
}
