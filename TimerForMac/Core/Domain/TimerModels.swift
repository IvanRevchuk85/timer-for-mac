//
//  TimerModels.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation

enum TimerStatus: Equatable {
    case idle
    case running
    case paused
    case finished
}

struct TimerSnapshot: Equatable {
    let status: TimerStatus
    let elapsed: TimeInterval
    let target: TimeInterval?

    var remaining: TimeInterval? {
        guard let target else { return nil }
        return max(0, target - elapsed)
    }
}

enum TimerAction: Equatable {
    case start(target: TimeInterval?)
    case pause
    case resume
    case stop
    case tick(delta: TimeInterval)
}
