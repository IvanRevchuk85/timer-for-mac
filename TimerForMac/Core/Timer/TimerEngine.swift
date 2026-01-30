//
//  TimerEngine.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation

actor TimerEngine: TimerEngineProtocol {

    // MARK: - Dependencies

    private let reducer = TimerReducer()

    // MARK: - Recovery

    private let settings: SettingsStore
    private let nowDate: @Sendable () -> Date
    private let nowUptime: @Sendable () -> TimeInterval

    // MARK: - State

    private var snapshot = TimerSnapshot(status: .idle, elapsed: 0, target: nil)
    private var continuations: [UUID: AsyncStream<TimerSnapshot>.Continuation] = [:]

    private var tickTask: Task<Void, Never>?
    private var lastUptime: TimeInterval?

    // MARK: - Init

    init(
        settings: SettingsStore,
        nowDate: @escaping @Sendable () -> Date = { Date() },
        nowUptime: @escaping @Sendable () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.settings = settings
        self.nowDate = nowDate
        self.nowUptime = nowUptime
    }

    // MARK: - TimerEngineProtocol

    nonisolated var stream: AsyncStream<TimerSnapshot> {
        AsyncStream { continuation in
            let id = UUID()

            continuation.onTermination = { @Sendable _ in
                Task { await self.detachContinuation(id: id) }
            }

            Task { await self.attachContinuation(id: id, continuation: continuation) }
        }
    }

    func start(target: TimeInterval?) async {
        apply(.start(target: target))
        startTickingIfNeeded()
    }

    func pause() async {
        apply(.pause)
        stopTicking()
    }

    func resume() async {
        apply(.resume)
        startTickingIfNeeded()
    }

    func stop() async {
        apply(.stop)
        stopTicking()
    }

    func recoverIfNeeded() async {
        let state = settings.timerRecoveryState

        // English: Nothing to recover if state is idle or has no target duration.
        // Russian: Нечего восстанавливать, если состояние idle или targetDuration отсутствует.
        guard state.status != .idle, state.targetDuration > 0 else { return }

        let output = TimerRecoveryCalculator.recover(
            state: state,
            nowDate: nowDate(),
            nowUptime: nowUptime()
        )

        let target: TimeInterval? = output.state.targetDuration > 0 ? output.state.targetDuration : nil

        snapshot = TimerSnapshot(
            status: output.state.status,
            elapsed: output.elapsed,
            target: target
        )
        yieldToAll(snapshot)

        // English: Persist normalized state back (includes finished transition and lastObserved* updates).
        // Russian: Сохраняем нормализованное состояние обратно (включая finished и lastObserved*).
        settings.timerRecoveryState = output.state

        // English: Ensure ticker matches recovered status.
        // Russian: Приводим тикер в соответствие со статусом.
        if snapshot.status == .running {
            startTickingIfNeeded()
        } else {
            stopTicking()
        }
    }

    // MARK: - Continuations

    private func attachContinuation(
        id: UUID,
        continuation: AsyncStream<TimerSnapshot>.Continuation
    ) {
        continuations[id] = continuation
        continuation.yield(snapshot)
    }

    private func detachContinuation(id: UUID) {
        continuations[id] = nil
    }

    // MARK: - Reducer / Output

    private func apply(_ action: TimerAction) {
        let previous = snapshot
        snapshot = reducer.reduce(state: snapshot, action: action)
        yieldToAll(snapshot)

        persistRecoveryState(for: action, previous: previous, current: snapshot)

        if snapshot.status == .finished {
            stopTicking()
        }
    }

    private func yieldToAll(_ snapshot: TimerSnapshot) {
        for continuation in continuations.values {
            continuation.yield(snapshot)
        }
    }

    // MARK: - Recovery persistence

    private func persistRecoveryState(for action: TimerAction, previous: TimerSnapshot, current: TimerSnapshot) {
        let date = nowDate()
        let uptime = nowUptime()

        switch action {
        case let .start(target):
            guard let target, target > 0 else {
                // English: Recovery model currently requires a finite target.
                // Russian: Модель восстановления сейчас требует конечный target.
                settings.timerRecoveryState = .default
                return
            }

            settings.timerRecoveryState = TimerRecoveryState(
                status: .running,
                targetDuration: target,
                startDate: date,
                startUptime: uptime,
                accumulatedElapsed: 0,
                lastObservedDate: date,
                lastObservedUptime: uptime
            )

        case .pause:
            guard previous.status == .running else { return }

            var state = settings.timerRecoveryState
            state.status = .paused
            state.accumulatedElapsed = max(0, current.elapsed)
            state.startDate = nil
            state.startUptime = nil
            state.lastObservedDate = date
            state.lastObservedUptime = uptime
            settings.timerRecoveryState = state

        case .resume:
            guard previous.status == .paused else { return }

            var state = settings.timerRecoveryState
            guard state.targetDuration > 0 else { return }

            state.status = .running
            state.startDate = date
            state.startUptime = uptime
            state.accumulatedElapsed = max(0, current.elapsed)
            state.lastObservedDate = date
            state.lastObservedUptime = uptime
            settings.timerRecoveryState = state

        case .stop:
            settings.timerRecoveryState = .default

        case .tick:
            // English: Persist only terminal transition to finished to avoid writing on each tick.
            // Russian: Сохраняем только переход в finished, чтобы не писать состояние на каждом тике.
            guard current.status == .finished else { return }

            var state = settings.timerRecoveryState
            state.status = .finished
            state.accumulatedElapsed = max(0, current.elapsed)
            state.startDate = nil
            state.startUptime = nil
            state.lastObservedDate = date
            state.lastObservedUptime = uptime
            settings.timerRecoveryState = state
        }
        
//        func clampedElapsed(_ elapsed: TimeInterval, target: TimeInterval) -> TimeInterval {
//            guard target > 0 else { return max(0, elapsed) }
//            return min(max(0, elapsed), target)
//        }
    }

    // MARK: - Ticking

    private func startTickingIfNeeded() {
        guard tickTask == nil else { return }
        guard snapshot.status == .running else { return }

        lastUptime = nowUptime()

        tickTask = Task { [weak self] in
            guard let self else { return }

            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: 250_000_000)
                await self.tickOnce()
            }
        }
    }

    private func tickOnce() {
        let now = nowUptime()
        let previous = lastUptime ?? now
        lastUptime = now

        let delta = max(0, now - previous)
        apply(.tick(delta: delta))
    }

    private func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
        lastUptime = nil
    }
}
