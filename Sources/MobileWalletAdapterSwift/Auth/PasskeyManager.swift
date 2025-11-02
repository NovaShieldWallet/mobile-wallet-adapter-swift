import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Manages passkey registration and authentication for wallet unlock.
/// Passkeys are used ONLY for authentication/unlock, NOT for signing Solana transactions.
@available(iOS 16.0, *)
@available(macOS, unavailable)
public final class PasskeyManager: NSObject {
    private let rpID: String
    private let rpName: String
    
    /// Default session TTL in seconds (120 seconds = 2 minutes)
    public var defaultSessionTTL: TimeInterval = 120
    
    /// Initializes the passkey manager.
    /// - Parameters:
    ///   - rpID: Unique identifier for your wallet app. 
    ///           Recommended: Use `Bundle.main.bundleIdentifier` for simplicity.
    ///           Alternative: Use a domain like `"wallet.example.com"` only if you need web integration.
    ///   - rpName: User-friendly name shown in iOS passkey dialogs (e.g., "My Wallet", "Nova Wallet")
    public init(rpID: String = "local.wallet", rpName: String = "Wallet") {
        self.rpID = rpID
        self.rpName = rpName
        super.init()
    }
    
    /// Registers a new passkey for the wallet account.
    /// - Parameter username: The username (typically the wallet's public key or a user identifier)
    public func register(username: String) async throws {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        
        let challenge = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let userID = Data(username.utf8)
        
        let registrationRequest = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: username,
            userID: userID
        )
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AuthorizationDelegate { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            
            authorizationController.performRequests()
        }
    }
    
    /// Authenticates using an existing passkey and unlocks the session.
    /// - Parameter sessionLock: The session lock to unlock upon successful authentication
    public func authenticate(sessionLock: SessionLock) async throws {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        
        let challenge = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        let assertionRequest = provider.createCredentialAssertionRequest(challenge: challenge)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [assertionRequest])
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let delegate = AuthorizationDelegate { result in
                switch result {
                case .success:
                    // Unlock session on successful authentication
                    sessionLock.unlockFor(seconds: self.defaultSessionTTL)
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            
            authorizationController.performRequests()
        }
    }
}

// MARK: - AuthorizationDelegate

@available(iOS 16.0, *)
@available(macOS, unavailable)
private class AuthorizationDelegate: NSObject {
    private let completion: (Result<Void, Error>) -> Void
    
    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }
    
    func handleSuccess() {
        completion(.success(()))
    }
    
    func handleError(_ error: Error) {
        if #available(iOS 16.0, *) {
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    completion(.failure(PasskeyError.userCanceled))
                case .failed:
                    completion(.failure(PasskeyError.authenticationFailed))
                case .invalidResponse:
                    completion(.failure(PasskeyError.invalidResponse))
                default:
                    completion(.failure(PasskeyError.unknown(authError)))
                }
            } else {
                completion(.failure(PasskeyError.unknown(error)))
            }
        } else {
            completion(.failure(PasskeyError.unknown(error)))
        }
    }
    
    func getPresentationAnchor() -> ASPresentationAnchor {
        // Return the main window
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        #endif
        // Fallback - create a basic window (shouldn't happen in normal usage)
        #if canImport(UIKit)
        return UIWindow(frame: CGRect.zero)
        #else
        fatalError("No presentation anchor available")
        #endif
    }
}

@available(iOS 16.0, *)
@available(macOS, unavailable)
extension AuthorizationDelegate: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleSuccess()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleError(error)
    }
}

@available(iOS 16.0, *)
@available(macOS, unavailable)
extension AuthorizationDelegate: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return getPresentationAnchor()
    }
}

// MARK: - PasskeyError

public enum PasskeyError: Error {
    case userCanceled
    case authenticationFailed
    case invalidResponse
    case unknown(Error)
    
    public var localizedDescription: String {
        switch self {
        case .userCanceled:
            return "Passkey authentication was canceled"
        case .authenticationFailed:
            return "Passkey authentication failed"
        case .invalidResponse:
            return "Invalid passkey response"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif

#if !canImport(UIKit)
import AppKit
typealias UIApplication = NSApplication
typealias UIWindow = NSWindow
typealias UIWindowScene = NSWindow
#endif

