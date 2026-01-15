//
//  TimerEngine.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation

protocol TimerEngineProtocol: Sendable {
    var stream: AsyncStream<TimerSnapshot> { get }
    func start(target: TimeInterval?) async
    func pause() async
    func resume() async
    func stop() async
}

actor TimerEngine: TimerEngineProtocol {
    private let reducer = TimerReducer()

    private var snapshot = TimerSnapshot(status: .idle, elapsed: 0, target: nil)
    private var continuation: AsyncStream<TimerSnapshot>.Continuation?

    private var tickTask: Task<Void, Never>?
    private var lastUptime: TimeInterval?

    nonisolated var stream: AsyncStream<TimerSnapshot> {
        AsyncStream { continuation in
            Task { await self.attach(continuation: continuation) }
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

    // MARK: - Private

    private func attach(continuation: AsyncStream<TimerSnapshot>.Continuation) {
        self.continuation = continuation
        continuation.yield(snapshot)
    }

    private func apply(_ action: TimerAction) {
        snapshot = reducer.reduce(state: snapshot, action: action)
        continuation?.yield(snapshot)

        if snapshot.status == .finished {
            stopTicking()
        }
    }

    private func startTickingIfNeeded() {
        guard tickTask == nil else { return }
        guard snapshot.status == .running else { return }

        lastUptime = ProcessInfo.processInfo.systemUptime

        tickTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)

                await self.tickOnce()
            }
        }
    }

    private func tickOnce() {
        let now = ProcessInfo.processInfo.systemUptime
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
