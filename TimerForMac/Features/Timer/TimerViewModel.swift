//
//  TimerViewModel.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation
import Combine

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var snapshot = TimerSnapshot(status: .idle, elapsed: 0, target: nil)
    @Published private(set) var targetSeconds: TimeInterval

    private let timerEngine: TimerEngineProtocol
    private let settings: SettingsStore
    private var listenTask: Task<Void, Never>?

    init(timerEngine: TimerEngineProtocol, settings: SettingsStore) {
        self.timerEngine = timerEngine
        self.settings = settings

        let initialMinutes = max(1, settings.timerTargetMinutes)
        self.targetSeconds = TimeInterval(initialMinutes * 60)

        startListening()
    }

    deinit {
        listenTask?.cancel()
    }

    // MARK: - Intent

    func onStart() {
        let target = targetSeconds
        Task { await timerEngine.start(target: target) }
    }

    func onPause() {
        Task { await timerEngine.pause() }
    }

    func onResume() {
        Task { await timerEngine.resume() }
    }

    func onStop() {
        Task { await timerEngine.stop() }
    }

    func setTargetMinutes(_ minutes: Int) {
        let safe = max(1, minutes)
        settings.timerTargetMinutes = safe
        targetSeconds = TimeInterval(safe * 60)
    }

    var isEditingTargetAllowed: Bool {
        snapshot.status == .idle || snapshot.status == .finished
    }

    // MARK: - Day Plan configuration

    func configureTargetFromDayPlanIfPossible(_ plan: DayPlan) {
        guard isEditingTargetAllowed else { return }

        let total = max(0, plan.totalDuration)
        if total > 0 {
            targetSeconds = total
        } else {
            let fallbackMinutes = max(1, settings.timerTargetMinutes)
            targetSeconds = TimeInterval(fallbackMinutes * 60)
        }
    }

    // MARK: - Private

    private func startListening() {
        listenTask?.cancel()

        listenTask = Task {
            for await value in timerEngine.stream {
                self.snapshot = value
            }
        }
    }
}
