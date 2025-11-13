import Foundation
import MatrixRustSDK

@Observable
final class LiveSpaceRoomList {
    
    let spaceService: LiveSpaceService
    let spaceRoomList: SpaceRoomList
    
    var space: SpaceRoom? = nil
    var rooms: [SidebarSpaceRoom] = []
    var paginationState: SpaceRoomListPaginationState = .loading
    
    fileprivate var spaceListenerHandle: TaskHandle? = nil
    fileprivate var roomsListenerHandle: TaskHandle? = nil
    fileprivate var paginateListenerHandle: TaskHandle? = nil
    
    public init(spaceService: LiveSpaceService, spaceRoomList: SpaceRoomList) {
        self.spaceService = spaceService
        self.spaceRoomList = spaceRoomList
        startListening()
        loadChildRooms()
    }
    
    fileprivate func startListening() {
        spaceListenerHandle = spaceRoomList.subscribeToSpaceUpdates(listener: self)
        roomsListenerHandle = spaceRoomList.subscribeToRoomUpdate(listener: self)
        paginateListenerHandle = spaceRoomList.subscribeToPaginationStateUpdates(listener: self)
    }
    
    func loadChildRooms() {
        Task {
            do {
                try await spaceRoomList.paginate()
            } catch {
                print("Failed to paginate space list: \(error)")
            }
        }
    }
}

extension LiveSpaceRoomList: SpaceRoomListSpaceListener, SpaceRoomListEntriesListener, SpaceRoomListPaginationStateListener {
    func onUpdate(paginationState: MatrixRustSDK.SpaceRoomListPaginationState) {
        self.paginationState = paginationState
    }
    
    func onUpdate(space: MatrixRustSDK.SpaceRoom?) {
        self.space = space
    }
    
    func onUpdate(rooms roomUpdates: [MatrixRustSDK.SpaceListUpdate]) {
        for update in roomUpdates {
            switch update {
            case .append(let values):
                rooms.append(contentsOf: values.map { SidebarSpaceRoom(spaceService: spaceService, spaceRoom: $0) })
            case .clear:
                rooms.removeAll()
            case .pushFront(let room):
                rooms.insert(SidebarSpaceRoom(spaceService: spaceService, spaceRoom: room), at: 0)
            case .pushBack(let room):
                rooms.append(SidebarSpaceRoom(spaceService: spaceService, spaceRoom: room))
            case .popFront:
                rooms.removeFirst()
            case .popBack:
                rooms.removeLast()
            case .insert(let index, let room):
                rooms.insert(SidebarSpaceRoom(spaceService: spaceService, spaceRoom: room), at: Int(index))
            case .set(let index, let room):
                rooms[Int(index)] = SidebarSpaceRoom(spaceService: spaceService, spaceRoom: room)
            case .remove(let index):
                rooms.remove(at: Int(index))
            case .truncate(let length):
                rooms.removeSubrange(Int(length)..<rooms.count)
            case .reset(values: let values):
                rooms = values.map { SidebarSpaceRoom(spaceService: spaceService, spaceRoom: $0) }
            }
        }
    }
}
