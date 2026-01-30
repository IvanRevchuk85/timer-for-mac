//
//  TimerRecoveryState.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 30.01.2026.
//

import Foundation

/// A persistable snapshot of timer state used to recover correct elapsed/remaining after app pauses, sleep/wake, or relaunch.
/// RU: Снимок состояния таймера для корректного восстановления elapsed/remaining после сна/перезапуска и т.п.
struct TimerRecoveryState: Codable, Equatable, Sendable {

    // MARK: - Core state

    /// Current timer status.
    /// RU: Текущий статус таймера.
    var status: TimerStatus

    /// Total target duration in seconds (workday plan duration or countdown target).
    /// RU: Целевая длительность таймера (секунды).
    var targetDuration: TimeInterval

    // MARK: - Running span anchors

    /// Wall-clock anchor for the start of the current running span.
    /// RU: Календарная метка старта текущего running-отрезка.
    var startDate: Date?

    /// Monotonic anchor for the start of the current running span.
    /// RU: Монотонная метка старта текущего running-отрезка.
    var startUptime: TimeInterval?

    // MARK: - Accumulated time

    /// Elapsed seconds accumulated before the current running span (e.g., before pause/resume).
    /// RU: Накопленное elapsed до текущего running-отрезка (например, до паузы).
    var accumulatedElapsed: TimeInterval

    // MARK: - Diagnostics / last known (optional but useful)

    /// Last observed wall-clock moment when state was updated.
    /// RU: Последняя календарная точка обновления состояния.
    var lastObservedDate: Date?

    /// Last observed monotonic uptime when state was updated.
    /// RU: Последняя монотонная точка обновления состояния.
    var lastObservedUptime: TimeInterval?

    // MARK: - Defaults

    static let `default` = TimerRecoveryState(
        status: .idle,
        targetDuration: 0,
        startDate: nil,
        startUptime: nil,
        accumulatedElapsed: 0,
        lastObservedDate: nil,
        lastObservedUptime: nil
    )
}
