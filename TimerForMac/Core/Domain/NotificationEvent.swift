//
//  NotificationEvent.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation

enum NotificationEvent: Equatable, Sendable {
    case timerStarted(total: TimeInterval)
    case timerFinished
    case timerStopped

    case segmentChanged(from: ActiveSegmentState?, to: ActiveSegmentState)

    case breakStarted(to: ActiveSegmentState)
    case lunchStarted(to: ActiveSegmentState)
}
