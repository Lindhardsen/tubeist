//
//  WatchConnectivityClient.swift
//  TubeistWatch Watch App
//
//  Watch-side counterpart to WatchSessionManager.swift on the iPhone.
//  Receives WatchStateSnapshot pushes and sends WatchCommand messages,
//  surfacing failures so the UI can show them rather than failing silently.
//

import Foundation
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityClient: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityClient()

    private nonisolated static let payloadKey = "payload"

    private(set) var snapshot: WatchStateSnapshot = .idle
    private(set) var isReachable = false
    /// Set on a failed command; the view clears it after showing an alert.
    var lastErrorMessage: String?

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sendStart() {
        send(.start)
    }

    func sendStop() {
        send(.stop)
    }

    func sendHighlight() {
        send(.saveHighlight)
    }

    private func send(_ command: WatchCommand) {
        guard WCSession.default.isReachable else {
            lastErrorMessage = "iPhone not reachable"
            return
        }
        // WatchCommand has no associated data, so it travels as a plain
        // string under its own key — PropertyListEncoder refuses to encode
        // a bare top-level enum, since a plist's root must be a container.
        let message = [WatchCommand.key: command.rawValue]
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handle(reply: reply)
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.lastErrorMessage = error.localizedDescription
            }
        })
    }

    private func handle(reply: [String: Any]) {
        guard let data = reply[Self.payloadKey] as? Data,
              let decoded = try? PropertyListDecoder().decode(WatchCommandReply.self, from: data) else {
            lastErrorMessage = "Unexpected reply from iPhone"
            return
        }
        if !decoded.success {
            lastErrorMessage = decoded.message ?? "The action failed"
        }
    }

    // MARK: - WCSessionDelegate
    // Apple calls these on a background thread; none are MainActor-isolated.

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            LOG("Watch session activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            WatchConnectivityClient.shared.isReachable = reachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[Self.payloadKey] as? Data,
              let decoded = try? PropertyListDecoder().decode(WatchStateSnapshot.self, from: data) else {
            return
        }
        Task { @MainActor in
            WatchConnectivityClient.shared.snapshot = decoded
        }
    }
}

/// watchOS has no shared LOG() helper from the iPhone target; a minimal
/// stand-in keeps WatchConnectivityClient's logging calls self-contained.
private nonisolated func LOG(_ message: String) {
    print("[TubeistWatch] \(message)")
}
