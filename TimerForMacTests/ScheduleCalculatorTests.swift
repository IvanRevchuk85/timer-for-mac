//
//  ShceduleCalculatorTests.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import XCTest
@testable import TimerForMac

final class ScheduleCalculatorTests: XCTestCase {
    func testPositionReturnsNilForEmptyPlan() {
        let plan = DayPlan(segments: [])
        XCTAssertNil(ScheduleCalculator.position(in: plan, elapsed: 0))
    }

    func testPositionFindsFirstSegment() {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
            PlanSegment(kind: .breakTime, title: "Break", duration: 30)
        ])

        let pos = ScheduleCalculator.position(in: plan, elapsed: 10)
        XCTAssertEqual(pos?.segmentIndex, 0)
        XCTAssertEqual(pos?.segment.kind, .work)
        XCTAssertEqual(pos?.elapsedInSegment, 10)
        XCTAssertEqual(pos?.remainingInSegment, 50)
    }

    func testPositionFindsSecondSegmentAtBoundary() {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
            PlanSegment(kind: .breakTime, title: "Break", duration: 30)
        ])

        let pos = ScheduleCalculator.position(in: plan, elapsed: 60)
        XCTAssertEqual(pos?.segmentIndex, 1)
        XCTAssertEqual(pos?.segment.kind, .breakTime)
        XCTAssertEqual(pos?.elapsedInSegment, 0)
        XCTAssertEqual(pos?.remainingInSegment, 30)
    }

    func testPositionReturnsNilAfterPlanEnds() {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
            PlanSegment(kind: .breakTime, title: "Break", duration: 30)
        ])

        XCTAssertNil(ScheduleCalculator.position(in: plan, elapsed: 90))
        XCTAssertNil(ScheduleCalculator.position(in: plan, elapsed: 999))
    }

    func testNegativeElapsedIsClampedToZero() {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60)
        ])

        let pos = ScheduleCalculator.position(in: plan, elapsed: -10)
        XCTAssertEqual(pos?.segmentIndex, 0)
        XCTAssertEqual(pos?.elapsedInSegment, 0)
        XCTAssertEqual(pos?.remainingInSegment, 60)
    }

    func testIsFinished() {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60)
        ])

        XCTAssertFalse(ScheduleCalculator.isFinished(plan: plan, elapsed: 59))
        XCTAssertTrue(ScheduleCalculator.isFinished(plan: plan, elapsed: 60))
        XCTAssertTrue(ScheduleCalculator.isFinished(plan: plan, elapsed: 100))
    }
}
