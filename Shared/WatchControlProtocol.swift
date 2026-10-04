//
//  WatchControlProtocol.swift
//  Tubeist
//
//  The WCSession message vocabulary shared by the iPhone app and
//  TubeistWatch, so both sides agree on command/reply/state shapes without
//  duplicating them. Reuses the Live Activity's own phase/health/highlight
//  enums (StreamActivityAttributes.swift) rather than inventing parallel ones.
//

import Foundation

/// A command the Watch app sends to the iPhone app via
/// WCSession.sendMessage. The iPhone handles each by calling the exact same
/// code path its own UI buttons already use (Streamer.shared, 
/// HighlightRequestBridge) — there is only ever one implementation per
/// action, regardless of which surface triggered it.
enum WatchCommand: String, Codable, Sendable {
    case start
    case stop
    case saveHighlight

    static let key = "command"
}

struct WatchCommandReply: Codable, Sendable {
    var success: Bool
    var message: String?

    static let success = WatchCommandReply(success: true, message: nil)
    static func failure(_ message: String) -> WatchCommandReply {
        WatchCommandReply(success: false, message: message)
    }
}

/// Pushed iPhone -> Watch via WCSession.updateApplicationContext, mirroring
/// the same state StreamActivityCoordinator already turns into the Live
/// Activity's ContentState.
struct WatchStateSnapshot: Codable, Sendable, Equatable {
    var phase: StreamActivityPhase
    var startedAt: Date?
    var health: StreamActivityHealth
    var healthTracked: Bool
    var batteryPercent: Int?
    var canSaveHighlight: Bool
    var highlightStatus: HighlightStatus?
    /// nil when no scoreboard server is configured in Settings, or while not
    /// actively streaming (WatchSessionManager only polls it then).
    var scoreboard: WatchScoreSnapshot?

    static let idle = WatchStateSnapshot(
        phase: .ended,
        startedAt: nil,
        health: .unknown,
        healthTracked: false,
        batteryPercent: nil,
        canSaveHighlight: false,
        highlightStatus: nil,
        scoreboard: nil
    )
}

/// Live score, sourced from a self-hosted scoreboard server
/// (github.com/Lindhardsen/scoreboard) via WatchSessionManager's polling.
struct WatchScoreSnapshot: Codable, Sendable, Equatable {
    var teamA: String
    var teamB: String
    var setsA: Int
    var setsB: Int
    var pointsA: Int
    var pointsB: Int
}
