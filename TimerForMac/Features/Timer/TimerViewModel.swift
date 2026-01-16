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
    @Published private(set) var targetSeconds: TimeInterval = 25 * 60

    private let timerEngine: TimerEngineProtocol
    private let settings: SettingsStore
    private var listenTask: Task<Void, Never>?

    init(timerEngine: TimerEngineProtocol, settings: SettingsStore) {
        self.timerEngine = timerEngine
        self.settings = settings
        self.targetSeconds = TimeInterval(max(1, settings.timerTargetMinutes) * 60)
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

    // MARK: - Private

    private func startListening() {
        listenTask = Task {
            for await value in timerEngine.stream {
                self.snapshot = value
            }
        }
    }
}

