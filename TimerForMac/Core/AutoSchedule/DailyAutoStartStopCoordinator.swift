//
//  DailyAutoStartStopCoordinator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 22.01.2026.
//

import Foundation

/// Coordinates daily auto start/stop by scheduling the next event and executing it.
/// This type is UI-free and schedules at most one pending task at a time.
@MainActor
final class DailyAutoStartStopCoordinator {

    // MARK: - Dependencies

    private let timerEngine: TimerEngineProtocol
    private let settings: SettingsStore
    private let scheduleService: DailyScheduleService
    private let clock: () -> Date
    private let sleeper: SleepProviding

    // MARK: - State

    private var task: Task<Void, Never>?
    private var isRunning = false

    /// Helps avoid double-triggering near boundary moments.
    private let fireToleranceSeconds: TimeInterval = 1.0

    // MARK: - Init

    init(
        timerEngine: TimerEngineProtocol,
        settings: SettingsStore,
        scheduleService: DailyScheduleService = DailyScheduleService(),
        clock: @escaping () -> Date = { Date() },
        sleeper: SleepProviding = SystemSleeper()
    ) {
        self.timerEngine = timerEngine
        self.settings = settings
        self.scheduleService = scheduleService
        self.clock = clock
        self.sleeper = sleeper
    }

    // MARK: - Public API

    /// Starts scheduling. Safe to call multiple times.
    func start() {
        guard !isRunning else { return }
        isRunning = true
        reschedule()
    }

    /// Stops scheduling and cancels any pending task.
    func stop() {
        isRunning = false
        cancelTask()
    }

    /// Recomputes the next event and schedules it.
    func reschedule() {
        guard isRunning else { return }

        cancelTask()

        let schedule = settings.dailySchedule
        let now = clock()

        guard let event = scheduleService.nextEvent(after: now, schedule: schedule) else {
            return
        }

        let fireDate = event.fireDate
        let tolerance = fireToleranceSeconds

        task = Task { [weak self] in
            guard let self else { return }

            do {
                try await self.sleeper.sleep(until: fireDate, tolerance: tolerance)
            } catch {
                // Cancellation is expected on reschedule/stop.
                return
            }

            guard self.isRunning else { return }

            await self.handle(event: event)

            // Schedule the next event after executing the current one.
            self.reschedule()
        }
    }

    // MARK: - Internals

    private func cancelTask() {
        task?.cancel()
        task = nil
    }

    private func handle(event: ScheduleEvent) async {
        switch event.type {
        case .start:
            let seconds = max(1, settings.timerTargetMinutes) * 60
            await timerEngine.start(target: TimeInterval(seconds)) // matches TimerEngineProtocol: TimeInterval?
        case .stop:
            await timerEngine.stop()
        }
    }
}

// MARK: - SleepProviding

protocol SleepProviding: Sendable {
    /// Suspends until the specified date (best-effort), with a tolerance window.
    func sleep(until date: Date, tolerance: TimeInterval) async throws
}

struct SystemSleeper: SleepProviding {
    init() {}

    func sleep(until date: Date, tolerance: TimeInterval) async throws {
        // If the target is in the past, return immediately.
        let now = Date()
        let interval = date.timeIntervalSince(now)
        if interval <= 0 { return }

        // Tolerance is handled by coordinator logic (we accept minor drift).
        let ns = UInt64(interval * 1_000_000_000)
        try await Task.sleep(nanoseconds: ns)
    }
}
