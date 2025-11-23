import Foundation
import MatrixRustSDK
import SwiftUI

@MainActor
@Observable public final class LiveTimeline {
    let room: MatrixRustSDK.Room
    public let isThreadFocus: Bool
    
    public var timeline: Timeline?
    
    private var timelineHandle: TaskHandle?
    private var paginateHandle: TaskHandle?

    public var scrollPosition = ScrollPosition(idType: TimelineItem.ID.self, edge: .bottom)
    public var errorMessage: String?
    public var focusedTimelineEventId: String?
    public var focusedThreadTimeline: LiveTimeline?
    public var sendReplyTo: MatrixRustSDK.EventTimelineItem? = nil

    public private(set) var timelineItems: [TimelineItem]?
    public private(set) var paginating: RoomPaginationStatus = .idle(hitTimelineStart: false)
    public private(set) var hitTimelineStart: Bool = false

    public init(room: MatrixRustSDK.Room) {
        self.isThreadFocus = false
        self.room = room
        Task {
            do {
                try await configureTimeline()
            } catch {
                print("failed to configure timeline: \(error)")
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public init(room: MatrixRustSDK.Room, focusThread threadId: String) {
        self.isThreadFocus = true
        self.room = room
        Task {
            do {
                try await configureTimeline(threadId: threadId)
            } catch {
                print("failed to configure timeline: \(error)")
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func configureTimeline(threadId: String? = nil) async throws {
        let focus = if let threadId {
            TimelineFocus.thread(rootEventId: threadId)
        } else {
            TimelineFocus.live(hideThreadedEvents: true)
        }

        let config = TimelineConfiguration(
            focus: focus,
            filter: .all,
            internalIdPrefix: nil,
            dateDividerMode: .daily,
            trackReadReceipts: true,
            reportUtds: false
        )
        timeline = try await room.timelineWithConfiguration(configuration: config)

        // Listen to timeline item updates.
        timelineHandle = await timeline?.addListener(listener: self)

        // Only main timelines can subscibe to back pagination status
        if threadId == nil {
            // Listen to paginate loading status updates.
            paginateHandle = try await timeline?.subscribeToBackPaginationStatus(listener: self)
        }
    }

    public func fetchOlderMessages() async throws {
        guard paginating == .idle(hitTimelineStart: false) else { return }

        _ = try await timeline?.paginateBackwards(numEvents: 100)
    }

    public func focusEvent(id eventId: String) {
        print("focus event: \(eventId)")

        if let item = timelineItems?.first(where: { $0.asEvent()?.eventOrTransactionId.id == eventId }) {
            print("scrolling to item \(item.id)")
            focusedTimelineEventId = eventId
            withAnimation {
                scrollPosition.scrollTo(id: item.id)
            }
        } else {
            print("could not find item in timeline")
        }
    }

    public func focusThread(rootEventId: String) {
        print("focus thread: \(rootEventId)")
        focusedThreadTimeline = LiveTimeline(room: room, focusThread: rootEventId)
    }
}

extension LiveTimeline: @MainActor TimelineListener {
    public func onUpdate(diff: [TimelineDiff]) {
        let oldView = scrollPosition.viewID
        print("onUpdate old view \(oldView.debugDescription)")

        for update in diff {
            switch update {
            case let .append(values):
                timelineItems!.append(contentsOf: values)
            case .clear:
                timelineItems!.removeAll()
            case let .pushFront(room):
                timelineItems!.insert(room, at: 0)
            case let .pushBack(room):
                timelineItems!.append(room)
            case .popFront:
                timelineItems!.removeFirst()
            case .popBack:
                timelineItems!.removeLast()
            case let .insert(index, room):
                timelineItems!.insert(room, at: Int(index))
            case let .set(index, room):
                timelineItems![Int(index)] = room
            case let .remove(index):
                timelineItems!.remove(at: Int(index))
            case let .truncate(length):
                timelineItems!.removeSubrange(Int(length) ..< timelineItems!.count)
            case let .reset(values: values):
                timelineItems = values
            }
        }

        if let oldView {
            scrollPosition.scrollTo(id: oldView, anchor: .top)
        }
    }
}

extension LiveTimeline: @MainActor PaginationStatusListener {
    public func onUpdate(status: MatrixRustSDK.RoomPaginationStatus) {
        print("updating timeline paginating: \(status)")
        paginating = status
    }
}
