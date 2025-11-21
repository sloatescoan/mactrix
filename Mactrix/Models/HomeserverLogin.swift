import AuthenticationServices
import Foundation
import MatrixRustSDK
import SwiftUI

struct HomeserverLogin {
    let storeID: String
    let unauthenticatedClient: ClientProtocol
    let loginDetails: HomeserverLoginDetailsProtocol

    init(storeID: String, unauthenticatedClient: ClientProtocol, loginDetails: HomeserverLoginDetailsProtocol) {
        self.storeID = storeID
        self.unauthenticatedClient = unauthenticatedClient
        self.loginDetails = loginDetails
    }

    @MainActor
    func loginPassword(homeServer _: String, username: String, password: String) async throws -> MatrixClient {
        // Login using password authentication.
        try await unauthenticatedClient.login(username: username, password: password, initialDeviceName: "Mactrix", deviceId: nil)
        return try onSuccessfullLogin()
    }

    private var oidcConfiguration: OidcConfiguration {
        // redirect uri must be reverse domain of client uri
        OidcConfiguration(clientName: "Mactrix", redirectUri: "com.github:/", clientUri: "https://github.com/viktorstrate/mactrix", logoUri: nil, tosUri: nil, policyUri: nil, staticRegistrations: [:])
    }

    @MainActor
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

    @MainActor
    fileprivate func onSuccessfullLogin() throws -> MatrixClient {
        let matrixClient = MatrixClient(storeID: storeID, client: unauthenticatedClient)

        let userSession = try matrixClient.userSession()
        try userSession.saveUserToKeychain()

        return matrixClient
    }
}
