//
//  NotificationEventDetector.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation

enum NotificationEventDetector {

    /// Detects notification-worthy events based on timer status transitions and active segment changes.
    /// - Parameters:
    ///   - previousStatus: Previous timer status.
    ///   - currentStatus: Current timer status.
    ///   - previousSegment: Previously active segment (computed).
    ///   - currentSegment: Currently active segment (computed).
    ///   - totalDuration: Total timer duration for "start" message (seconds).
    ///   - settings: User notification toggles.
    /// - Returns: A list of events to post (usually empty or 1 item).
    static func detect(
        previousStatus: TimerStatus,
        currentStatus: TimerStatus,
        previousSegment: ActiveSegmentState?,
        currentSegment: ActiveSegmentState?,
        totalDuration: TimeInterval,
        settings: NotificationSettings
    ) -> [NotificationEvent] {
        guard settings.isEnabled else { return [] }

        var events: [NotificationEvent] = []

        // Timer started.
                if settings.notifyOnStart,
                   previousStatus == .idle,
                   currentStatus == .running {
                    events.append(.timerStarted(total: max(0, totalDuration)))
                }

                // Timer stopped (explicit stop -> back to idle).
                if settings.notifyOnStop,
                   (previousStatus == .running || previousStatus == .paused),
                   currentStatus == .idle {
                    events.append(.timerStopped)
                }

                // Timer finished.
                if settings.notifyOnFinish,
                   previousStatus != .finished,
                   currentStatus == .finished {
                    events.append(.timerFinished)
                }

                // Segment changed.
                if settings.notifyOnSegmentChange,
                   let to = currentSegment,
                   previousSegment?.index != to.index {
                    events.append(.segmentChanged(from: previousSegment, to: to))

                    if settings.notifyOnBreak, to.kind == .breakTime {
                        events.append(.breakStarted(to: to))
                    }

                    if settings.notifyOnLunch, to.kind == .lunch {
                        events.append(.lunchStarted(to: to))
                    }
                }

                return events
            }
        }
