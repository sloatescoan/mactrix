//
//  MatrixClient+Timeline.swift
//  Mactrix
//
//  Created by Viktor Strate Kløvedal on 31/10/2025.
//

import Foundation
import MatrixRustSDK

@Observable class RoomTimeline {
    let timeline: Timeline
    fileprivate var timelineHandle: TaskHandle!
    
    var timelineItems: [TimelineItem] = []
    
    init(room: Room) async throws {
        timeline = try await room.timeline()
        
        // Listen to timeline item updates.
        timelineHandle = await timeline.addListener(listener: self)
    }
}

extension RoomTimeline: TimelineListener {
    func onUpdate(diff: [TimelineDiff]) {
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
