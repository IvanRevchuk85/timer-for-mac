//
//  ScheduleCalculator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

struct SchedulePosition: Equatable {
    let segmentIndex: Int
    let segment: PlanSegment
    let elapsedInSegment: TimeInterval
    let remainingInSegment: TimeInterval
}

enum ScheduleCalculator {
    // MARK: - Public
    // English: Calculates current segment by elapsed time since plan start.

    static func position(in plan: DayPlan, elapsed: TimeInterval) -> SchedulePosition? {
        guard !plan.segments.isEmpty else { return nil }

        let safeElapsed = max(0, elapsed)

        var cursor: TimeInterval = 0

        for (index, segment) in plan.segments.enumerated() {
            let start = cursor
            let end = cursor + segment.duration

            if safeElapsed < end || (segment.duration == 0 && safeElapsed == start) {
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

        // If elapsed exceeds total duration, we treat plan as finished.
        return nil
    }

    static func isFinished(plan: DayPlan, elapsed: TimeInterval) -> Bool {
        max(0, elapsed) >= plan.totalDuration && plan.totalDuration > 0
    }
}
