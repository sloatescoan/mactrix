import Foundation
import MatrixRustSDK
import KeychainAccess

struct UserSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let userID: String
    let deviceID: String
    let homeserverURL: String
    let oidcData: String?
    let storeID: String
    
    init(session: Session, storeID: String) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.userID = session.userId
        self.deviceID = session.deviceId
        self.homeserverURL = session.homeserverUrl
        self.oidcData = session.oidcData
        self.storeID = storeID
    }
    
    var session: Session {
        Session(accessToken: accessToken,
                refreshToken: refreshToken,
                userId: userID,
                deviceId: deviceID,
                homeserverUrl: homeserverURL,
                oidcData: oidcData,
                slidingSyncVersion: .native)
        
    }
    
    fileprivate static var keychainKey: String { "UserSession" }
    
    func saveUserToKeychain() throws {
        let keychainData = try JSONEncoder().encode(self)
        let keychain = Keychain(service: applicationID)
        try keychain.set(keychainData, key: Self.keychainKey)
    }
    
    static func loadUserFromKeychain() throws -> Self? {
        let keychain = Keychain(service: applicationID)
        guard let keychainData = try keychain.getData(keychainKey) else { return nil }
        return try JSONDecoder().decode(Self.self, from: keychainData)
    }
}

@Observable class MatrixClient {
    let storeID: String
    let client: Client
    
    var rooms: [Room] = []
    
    init(storeID: String, client: Client) {
        self.storeID = storeID
        self.client = client
    }
    
    func userSession() throws -> UserSession {
        return UserSession(session: try client.session(), storeID: storeID)
    }
    
    static func login(homeServer: String, username: String, password: String) async throws -> MatrixClient {
        let storeID = UUID().uuidString
        
        // Create a client for a particular homeserver.
        // Note that we can pass a server name (the second part of a Matrix user ID) instead of the direct URL.
        // This allows the SDK to discover the homeserver's well-known configuration for Sliding Sync support.
        let client = try await ClientBuilder()
            .serverNameOrHomeserverUrl(serverNameOrUrl: homeServer)
            .sessionPaths(dataPath: URL.sessionData(for: storeID).path(percentEncoded: false),
                          cachePath: URL.sessionCaches(for: storeID).path(percentEncoded: false))
            .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
            .build()
        
        // Login using password authentication.
        try await client.login(username: username, password: password, initialDeviceName: "Mactrix", deviceId: nil)
        
        let matrixClient = MatrixClient(storeID: storeID, client: client)
        
        let userSession = try matrixClient.userSession()
        try userSession.saveUserToKeychain()
        
        return matrixClient
    }
    
    static func attemptRestore() async throws -> MatrixClient? {
        guard let userSession = try UserSession.loadUserFromKeychain() else { return nil }
        
        let session = userSession.session
        let storeID = userSession.storeID
        
        // Build a client for the homeserver.
        let client = try await ClientBuilder()
            .sessionPaths(dataPath: URL.sessionData(for: storeID).path(percentEncoded: false),
                          cachePath: URL.sessionCaches(for: storeID).path(percentEncoded: false))
            .homeserverUrl(url: session.homeserverUrl)
            .build()
        
        // Restore the client using the session.
        try await client.restoreSession(session: session)
        
        return MatrixClient(storeID: storeID, client: client)
    }
    
    var syncService: SyncService!
    var roomListService: RoomListService!
    var roomListEntriesHandle: RoomListEntriesWithDynamicAdaptersResult!
    
    func startSync() async throws {
        syncService = try await client.syncService().finish()
        roomListService = syncService.roomListService()
        roomListEntriesHandle = try await roomListService.allRooms().entriesWithDynamicAdapters(pageSize: 100, listener: self)
        let _ = roomListEntriesHandle.controller().setFilter(kind: .all(filters: []))
        
        // Start the sync loop.
        await syncService.start()
    }
}

extension MatrixClient: RoomListEntriesListener {
    func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) {
        for update in roomEntriesUpdate {
            print("Update rooms: \(update)")
            switch update {
            case .append(let values):
                rooms.append(contentsOf: values)
            case .clear:
                rooms.removeAll()
            case .pushFront(let room):
                rooms.insert(room, at: 0)
            case .pushBack(let room):
                rooms.append(room)
            case .popFront:
                rooms.removeFirst()
            case .popBack:
                rooms.removeLast()
            case .insert(let index, let room):
                rooms.insert(room, at: Int(index))
            case .set(let index, let room):
                rooms[Int(index)] = room
            case .remove(let index):
                rooms.remove(at: Int(index))
            case .truncate(let length):
                rooms.removeSubrange(Int(length)..<rooms.count)
            case .reset(values: let values):
                rooms = values
            }
        }
        
        print(rooms.map { $0.displayName() ?? "unknown" })
    }
}

fileprivate extension URL {
    static func sessionData(for sessionID: String) -> URL {
        applicationSupportDirectory
            .appending(component: applicationID)
            .appending(component: sessionID)
    }
    
    static func sessionCaches(for sessionID: String) -> URL {
        cachesDirectory
            .appending(component: applicationID)
            .appending(component: sessionID)
    }
}

extension MatrixRustSDK.Room: @retroactive Identifiable {
    public var id: String {
        self.id()
    }
}

extension MatrixRustSDK.Room: @retroactive Hashable {
    public static func == (lhs: MatrixRustSDK.Room, rhs: MatrixRustSDK.Room) -> Bool {
        return lhs.id() == rhs.id()
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.id())
    }
}
