//
//  ScheduleCalculator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

struct SchedulePosition: Equatable, Sendable {
    let segmentIndex: Int
    let segment: PlanSegment
    let elapsedInSegment: TimeInterval
    let remainingInSegment: TimeInterval
}

enum ScheduleCalculator {
    /// Calculates current segment by elapsed time since plan start.
    static func position(in plan: DayPlan, elapsed: TimeInterval) -> SchedulePosition? {
        guard !plan.segments.isEmpty else { return nil }

        let safeElapsed = max(0, elapsed)

        // If total duration is zero, there is no meaningful "current" segment.
        guard plan.totalDuration > 0 else { return nil }

        var cursor: TimeInterval = 0

        for (index, segment) in plan.segments.enumerated() {
            // Skip zero-duration segments to avoid returning "empty" current state.
            if segment.duration <= 0 {
                continue
            }

            let start = cursor
            let end = cursor + segment.duration

            // Boundary rule:
            // - [start, end) belongs to current segment
            // - elapsed == end belongs to the next segment
            if safeElapsed < end {
                let elapsedInSegment = max(0, safeElapsed - start)
                let remainingInSegment = max(0, segment.duration - elapsedInSegment)

                return SchedulePosition(
                    segmentIndex: index,
                    segment: segment,
                    elapsedInSegment: elapsedInSegment,
                    remainingInSegment: remainingInSegment
                )
            }

            cursor = end
        }

        // If elapsed exceeds total duration, the plan is finished.
        return nil
    }

    static func isFinished(plan: DayPlan, elapsed: TimeInterval) -> Bool {
        let safeElapsed = max(0, elapsed)
        return plan.totalDuration > 0 && safeElapsed >= plan.totalDuration
    }
}
