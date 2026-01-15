//
//  TimerReducer.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation

struct TimerReducer {
    // MARK: - Reduce
    // English: Pure state transition logic, easy to unit test.
    // Russian: Чистая логика переходов состояния, легко тестировать.

    func reduce(state: TimerSnapshot, action: TimerAction) -> TimerSnapshot {
        switch action {
        case let .start(target):
            return TimerSnapshot(status: .running, elapsed: 0, target: target)

        case .pause:
            guard state.status == .running else { return state }
            return TimerSnapshot(status: .paused, elapsed: state.elapsed, target: state.target)

        case .resume:
            guard state.status == .paused else { return state }
            return TimerSnapshot(status: .running, elapsed: state.elapsed, target: state.target)

        case .stop:
            return TimerSnapshot(status: .idle, elapsed: 0, target: nil)

        case let .tick(delta):
            guard state.status == .running else { return state }

            let newElapsed = max(0, state.elapsed + delta)

            if let target = state.target, newElapsed >= target {
                return TimerSnapshot(status: .finished, elapsed: target, target: target)
            }

            return TimerSnapshot(status: .running, elapsed: newElapsed, target: state.target)
        }
    }
}
