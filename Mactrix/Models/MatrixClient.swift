import Foundation
import MatrixRustSDK
import KeychainAccess
import AuthenticationServices
import SwiftUI
import UI

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
        #if DEBUG
        if true {
            return try JSONDecoder().decode(Self.self, from: DevSecrets.matrixSession.data(using: .utf8)!)
        }
        #endif
        let keychain = Keychain(service: applicationID)
        guard let keychainData = try keychain.getData(keychainKey) else { return nil }
        return try JSONDecoder().decode(Self.self, from: keychainData)
    }
}

struct HomeserverLogin {
    let storeID: String
    let unauthenticatedClient: ClientProtocol
    let loginDetails: HomeserverLoginDetailsProtocol
    
    init(storeID: String, unauthenticatedClient: ClientProtocol, loginDetails: HomeserverLoginDetailsProtocol) {
        self.storeID = storeID
        self.unauthenticatedClient = unauthenticatedClient
        self.loginDetails = loginDetails
    }
    
    func loginPassword(homeServer: String, username: String, password: String) async throws -> MatrixClient {
        // Login using password authentication.
        try await unauthenticatedClient.login(username: username, password: password, initialDeviceName: "Mactrix", deviceId: nil)
        return try onSuccessfullLogin()
    }
    
    private var oidcConfiguration: OidcConfiguration {
        // redirect uri must be reverse domain of client uri
        OidcConfiguration(clientName: "Mactrix", redirectUri: "com.github:/", clientUri: "https://github.com/viktorstrate/mactrix", logoUri: nil, tosUri: nil, policyUri: nil, staticRegistrations: [:])
    }
    
    func loginOidc(webAuthSession: WebAuthenticationSession) async throws -> MatrixClient {
        print("login oidc begin")
        let authInfo = try await unauthenticatedClient.urlForOidc(oidcConfiguration: oidcConfiguration, prompt: .login, loginHint: nil, deviceId: nil, additionalScopes: nil)
        let url = URL(string: authInfo.loginUrl())!
        
        print("Auth url: \(url)")
        
        let callbackUrl = try await webAuthSession.authenticate(using: url, callback: .customScheme("com.github"), additionalHeaderFields: [:])
        
        print("after sign in")
        
        try await unauthenticatedClient.loginWithOidcCallback(callbackUrl: callbackUrl.absoluteString)
        
        return try onSuccessfullLogin()
    }
    
    fileprivate func onSuccessfullLogin() throws -> MatrixClient {
        let matrixClient = MatrixClient(storeID: storeID, client: unauthenticatedClient)
        
        let userSession = try matrixClient.userSession()
        try userSession.saveUserToKeychain()
        
        return matrixClient
    }
}

@Observable class MatrixClient {
    let storeID: String
    let client: ClientProtocol
    
    var rooms: [SidebarRoom] = []
    
    var selectedRoom: LiveRoom? = nil
    
    private var clientDelegateHandle: TaskHandle? = nil
    var authenticationFailed: Bool = false
    
    init(storeID: String, client: ClientProtocol) {
        self.storeID = storeID
        self.client = client
        
        clientDelegateHandle = try? self.client.setDelegate(delegate: self)
    }
    
    static var previewMock: MatrixClient {
        MatrixClient(storeID: UUID().uuidString, client: MatrixClientMock())
    }
    
    func userSession() throws -> UserSession {
        return UserSession(session: try client.session(), storeID: storeID)
    }
    
    static func loginDetails(homeServer: String) async throws -> HomeserverLogin {
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
        
        let details = await client.homeserverLoginDetails()
        return HomeserverLogin(storeID: storeID, unauthenticatedClient: client, loginDetails: details)
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
        
        let matrixClient = MatrixClient(storeID: storeID, client: client)
        
        // Restore the client using the session.
        try await matrixClient.client.restoreSession(session: session)
        
        return matrixClient
    }
    
    func reset() async throws {
        try? await client.logout()
        try? FileManager.default.removeItem(at: .sessionData(for: self.storeID))
        try? FileManager.default.removeItem(at: .sessionCaches(for: self.storeID))
        let keychain = Keychain(service: applicationID)
        try keychain.removeAll()
    }
    
    var syncService: SyncService?
    var roomListService: RoomListService?
    var roomListEntriesHandle: RoomListEntriesWithDynamicAdaptersResult?
    
    func startSync() async throws {
        syncService = try await client.syncService().finish()
        roomListService = syncService?.roomListService()
        roomListEntriesHandle = try await roomListService?.allRooms().entriesWithDynamicAdapters(pageSize: 100, listener: self)
        let _ = roomListEntriesHandle?.controller().setFilter(kind: .all(filters: []))
        
        // Start the sync loop.
        await syncService?.start()
        print("Matrix sync started")
    }
    
    func clearCache() async throws {
        try await self.client.clearCaches(syncService: syncService)
    }
}

extension MatrixClient: MatrixRustSDK.ClientDelegate {
    func didReceiveAuthError(isSoftLogout: Bool) {
        
        print("did receive auth error: soft logout \(isSoftLogout)")
        if !isSoftLogout {
            self.authenticationFailed = true
        }
    }
}

extension MatrixClient: UI.ImageLoader {
    func loadImage(matrixUrl: String) async throws -> Image? {
        let imageData = try await self.client.getMediaContent(mediaSource: .fromUrl(url: matrixUrl))
        return try await Image(importing: imageData, contentType: nil)
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
