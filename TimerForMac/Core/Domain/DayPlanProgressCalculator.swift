//
//  DayPlanProgressCalculator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation

struct ActiveSegmentState: Equatable, Sendable {
    let index: Int
    let kind: SegmentKind
    let title: String
    let remaining: TimeInterval
    let duration: TimeInterval
}

enum DayPlanProgressCalculator {
    /// Returns active segment state based on the plan total duration and total remaining time.
    static func activeSegment(plan: DayPlan, totalRemaining: TimeInterval) -> ActiveSegmentState? {
        let total = max(0, plan.totalDuration)
        guard total > 0 else { return nil }

        let clampedRemaining = min(max(0, totalRemaining), total)
        let elapsed = total - clampedRemaining

        var cursor: TimeInterval = 0

        for (idx, seg) in plan.segments.enumerated() {
            let dur = max(0, seg.duration)
            let next = cursor + dur

            if elapsed < next {
                let elapsedInSegment = elapsed - cursor
                let remainingInSegment = max(0, dur - elapsedInSegment)

                return ActiveSegmentState(
                    index: idx,
                    kind: seg.kind,
                    title: seg.resolvedTitle,
                    remaining: remainingInSegment,
                    duration: dur
                )
            }

            cursor = next
        }

        // If elapsed reaches or exceeds total (edge case), treat as last segment finished.
        return nil
    }
}
