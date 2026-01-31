//
//  TimerRecoveryCalculator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 30.01.2026.
//

import Foundation

/// Pure recovery math for deriving correct elapsed/remaining from a persisted TimerRecoveryState.
/// RU: Чистая математика восстановления elapsed/remaining из сохраненного TimerRecoveryState.
enum TimerRecoveryCalculator {

    /// Recovery policy for choosing a delta source when both uptime and date are available.
    /// RU: Политика выбора источника delta, когда доступны и uptime, и date.
    struct Policy: Sendable, Equatable {
        /// If deltas differ by less than this tolerance, uptime delta is preferred.
        /// RU: Если дельты отличаются меньше порога — предпочитаем uptime.
        var deltaTolerance: TimeInterval

        /// Maximum allowed forward wall-clock skew relative to uptime before we treat wall-clock as suspicious.
        /// RU: Максимально допустимый "скачок" date вперёд относительно uptime, после чего date считаем подозрительным.
        var maxForwardDateSkew: TimeInterval

        static let `default` = Policy(deltaTolerance: 2, maxForwardDateSkew: 12 * 60 * 60)
    }

    /// Result of recovery: updated state + derived values.
    /// RU: Результат восстановления: обновлённое состояние + производные значения.
    struct Output: Sendable, Equatable {
        var state: TimerRecoveryState
        var elapsed: TimeInterval
        var remaining: TimeInterval
    }

    /// Recalculates elapsed/remaining using the given "now" values.
    /// RU: Пересчитывает elapsed/remaining по переданным now.
    static func recover(
        state: TimerRecoveryState,
        nowDate: Date,
        nowUptime: TimeInterval,
        policy: Policy = .default
    ) -> Output {
        var newState = state

        let clampedTarget = max(0, state.targetDuration)
        let baseElapsed = max(0, state.accumulatedElapsed)

        let runningDelta = runningElapsedDeltaIfNeeded(
            state: state,
            nowDate: nowDate,
            nowUptime: nowUptime,
            policy: policy
        )

        let rawElapsed = baseElapsed + runningDelta
        let elapsed = min(max(0, rawElapsed), clampedTarget)
        let remaining = max(0, clampedTarget - elapsed)

        // Transition to finished when running reaches target.
        if state.status == .running, clampedTarget > 0, elapsed >= clampedTarget {
            newState.status = .finished

        // English: Freeze the state at the target to make future recovery idempotent.
        // Russian: "Замораживаем" состояние на target, чтобы дальнейший recover был идемпотентным.
        newState.accumulatedElapsed = clampedTarget
        newState.startDate = nil
        newState.startUptime = nil
        }

        // Update last observed markers for future diagnostics.
        newState.lastObservedDate = nowDate
        newState.lastObservedUptime = nowUptime
        
        return Output(state: newState, elapsed: elapsed, remaining: remaining)
    }

    // MARK: - Internals

    private static func runningElapsedDeltaIfNeeded(
        state: TimerRecoveryState,
        nowDate: Date,
        nowUptime: TimeInterval,
        policy: Policy
    ) -> TimeInterval {
        guard state.status == .running else { return 0 }

        let uptimeDelta = safeUptimeDelta(startUptime: state.startUptime, nowUptime: nowUptime)
        let dateDelta = safeDateDelta(startDate: state.startDate, nowDate: nowDate)

        switch (uptimeDelta, dateDelta) {
        case (nil, nil):
            return 0

        case (let u?, nil):
            return u

        case (nil, let d?):
            return d

        case (let u?, let d?):
            // If close enough — prefer uptime (monotonic, immune to wall-clock edits).
            if abs(d - u) <= policy.deltaTolerance {
                return u
            }

            // If wall-clock is far ahead of uptime, it may be a manual time change.
            // In that case, prefer uptime.
            if d - u > policy.maxForwardDateSkew {
                return u
            }

            // Otherwise prefer date: captures gaps where ticks were not delivered (e.g., sleep/wake behaviors).
            return d
        }
    }

    private static func safeUptimeDelta(startUptime: TimeInterval?, nowUptime: TimeInterval) -> TimeInterval? {
        guard let startUptime else { return nil }
        let delta = nowUptime - startUptime
        return delta.isFinite ? max(0, delta) : nil
    }

    private static func safeDateDelta(startDate: Date?, nowDate: Date) -> TimeInterval? {
        guard let startDate else { return nil }
        let delta = nowDate.timeIntervalSince(startDate)
        return delta.isFinite ? max(0, delta) : nil
    }
}
