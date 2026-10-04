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
    /// nil until the scoreboard-server integration (a later phase) populates
    /// it; the Watch UI is built against this shape now regardless.
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

/// Reserved shape for the live score, sourced from
/// github.com/Lindhardsen/scoreboard in a follow-up phase. Defined now so
/// the Watch UI has a stable, real shape to render against.
struct WatchScoreSnapshot: Codable, Sendable, Equatable {
    var teamA: String
    var teamB: String
    var setsA: Int
    var setsB: Int
    var pointsA: Int
    var pointsB: Int
}
