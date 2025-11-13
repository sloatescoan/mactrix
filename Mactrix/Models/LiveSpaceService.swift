import Foundation
import MatrixRustSDK

@Observable public final class LiveSpaceService {
    public let spaceService: SpaceService
    
    public var spaceRooms: [SidebarSpaceRoom] = []
    
    var listenerTaskHandle: TaskHandle? = nil
    
    public init(spaceService: SpaceService) {
        self.spaceService = spaceService
        
        Task {
            listenerTaskHandle = await spaceService.subscribeToJoinedSpaces(listener: self)
            
            let joinedSpaces = await spaceService.joinedSpaces()
            print("Joined spaces: \(joinedSpaces)")
        }
    }
}

extension LiveSpaceService: SpaceServiceJoinedSpacesListener {
    public func onUpdate(roomUpdates: [MatrixRustSDK.SpaceListUpdate]) {
        for update in roomUpdates {
            switch update {
            case .append(let values):
                spaceRooms.append(contentsOf: values.map { SidebarSpaceRoom(spaceService: self, spaceRoom: $0) })
            case .clear:
                spaceRooms.removeAll()
            case .pushFront(let room):
                spaceRooms.insert(SidebarSpaceRoom(spaceService: self, spaceRoom: room), at: 0)
            case .pushBack(let room):
                spaceRooms.append(SidebarSpaceRoom(spaceService: self, spaceRoom: room))
            case .popFront:
                spaceRooms.removeFirst()
            case .popBack:
                spaceRooms.removeLast()
            case .insert(let index, let room):
                spaceRooms.insert(SidebarSpaceRoom(spaceService: self, spaceRoom: room), at: Int(index))
            case .set(let index, let room):
                spaceRooms[Int(index)] = SidebarSpaceRoom(spaceService: self, spaceRoom: room)
            case .remove(let index):
                spaceRooms.remove(at: Int(index))
            case .truncate(let length):
                spaceRooms.removeSubrange(Int(length)..<spaceRooms.count)
            case .reset(values: let values):
                spaceRooms = values.map { SidebarSpaceRoom(spaceService: self, spaceRoom: $0) }
            }
        }
        
        print("Space list updated: \(spaceRooms.count) \(roomUpdates) \(spaceRooms)")
    }
}
