import Foundation

/// Manages session-based unlock state for wallet operations.
/// Passkey authentication unlocks the session for a configurable duration.
public final class SessionLock {
    private var unlockUntil: Date?
    private let lockQueue = DispatchQueue(label: "com.wallet.sessionlock")
    
    public init() {}
    
    /// Returns true if the session is currently unlocked.
    public var isUnlocked: Bool {
        lockQueue.sync {
            guard let until = unlockUntil else {
                return false
            }
            return Date() < until
        }
    }
    
    /// Unlocks the session for the specified duration.
    public func unlockFor(seconds: TimeInterval) {
        lockQueue.sync {
            unlockUntil = Date().addingTimeInterval(seconds)
        }
    }
    
    /// Immediately locks the session.
    public func lock() {
        lockQueue.sync {
            unlockUntil = nil
        }
    }
    
    /// Requires the session to be unlocked; throws if locked.
    public func requireUnlock() throws {
        guard isUnlocked else {
            throw SessionLockError.locked
        }
    }
    
    /// Gets the remaining unlock duration in seconds, or nil if locked.
    public var remainingUnlockTime: TimeInterval? {
        lockQueue.sync {
            guard let until = unlockUntil else {
                return nil
            }
            let remaining = until.timeIntervalSinceNow
            return remaining > 0 ? remaining : nil
        }
    }
}

// MARK: - SessionLockError

public enum SessionLockError: Error {
    case locked
}

