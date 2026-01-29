//
//  NotificationEventDetectorTests.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 29.01.2026.
//

import XCTest
@testable import TimerForMac

final class NotificationEventDetectorTests: XCTestCase {

    // MARK: - isEnabled gate

    func test_detect_whenDisabled_returnsEmpty() {
        let settings = NotificationSettings(
            isEnabled: false,
            notifyOnStart: true,
            notifyOnStop: true,
            notifyOnFinish: true,
            notifyOnSegmentChange: true,
            notifyOnBreak: true,
            notifyOnLunch: true
        )

        let events = NotificationEventDetector.detect(
            previousStatus: .idle,
            currentStatus: .running,
            previousSegment: nil,
            currentSegment: makeWork(index: 0),
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [])
    }

    // MARK: - Timer started

    func test_detect_idleToRunning_emitsTimerStarted_whenToggleOn() {
        let settings = NotificationSettings(
            isEnabled: true,
            notifyOnStart: true,
            notifyOnStop: false,
            notifyOnFinish: false,
            notifyOnSegmentChange: false,
            notifyOnBreak: false,
            notifyOnLunch: false
        )

        let events = NotificationEventDetector.detect(
            previousStatus: .idle,
            currentStatus: .running,
            previousSegment: nil,
            currentSegment: makeWork(index: 0),
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [.timerStarted(total: 1200)])
    }

    func test_detect_idleToRunning_clampsNegativeTotalDuration_toZero() {
        let settings = NotificationSettings(
            isEnabled: true,
            notifyOnStart: true,
            notifyOnStop: false,
            notifyOnFinish: false,
            notifyOnSegmentChange: false,
            notifyOnBreak: false,
            notifyOnLunch: false
        )

        let events = NotificationEventDetector.detect(
            previousStatus: .idle,
            currentStatus: .running,
            previousSegment: nil,
            currentSegment: makeWork(index: 0),
            totalDuration: -10,
            settings: settings
        )

        XCTAssertEqual(events, [.timerStarted(total: 0)])
    }

    // MARK: - Timer stopped

    func test_detect_runningToIdle_emitsTimerStopped_whenToggleOn() {
        let settings = NotificationSettings(isEnabled: true, notifyOnStop: true)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .idle,
            previousSegment: makeWork(index: 0),
            currentSegment: nil,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [.timerStopped])
    }

    func test_detect_pausedToIdle_emitsTimerStopped_whenToggleOn() {
        let settings = NotificationSettings(isEnabled: true, notifyOnStop: true)

        let events = NotificationEventDetector.detect(
            previousStatus: .paused,
            currentStatus: .idle,
            previousSegment: makeWork(index: 0),
            currentSegment: nil,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [.timerStopped])
    }

    // MARK: - Timer finished

    func test_detect_runningToFinished_emitsTimerFinished_whenToggleOn() {
        let settings = NotificationSettings(isEnabled: true, notifyOnFinish: true)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .finished,
            previousSegment: makeWork(index: 0),
            currentSegment: nil,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [.timerFinished])
    }

    func test_detect_finishedToFinished_doesNotEmitTimerFinished_again() {
        let settings = NotificationSettings(isEnabled: true, notifyOnFinish: true)

        let events = NotificationEventDetector.detect(
            previousStatus: .finished,
            currentStatus: .finished,
            previousSegment: nil,
            currentSegment: nil,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [])
    }

    // MARK: - Segment changed

    func test_detect_segmentIndexChanged_emitsSegmentChanged_whenToggleOn() {
        let settings = NotificationSettings(isEnabled: true, notifyOnSegmentChange: true)

        let from = makeWork(index: 0)
        let to = makeWork(index: 1)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .running,
            previousSegment: from,
            currentSegment: to,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [.segmentChanged(from: from, to: to)])
    }

    func test_detect_sameSegmentIndex_emitsNoSegmentEvents() {
        let settings = NotificationSettings(
            isEnabled: true,
            notifyOnSegmentChange: true,
            notifyOnBreak: true,
            notifyOnLunch: true
        )

        let seg0 = makeWork(index: 0)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .running,
            previousSegment: seg0,
            currentSegment: seg0,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [])
    }

    func test_detect_segmentChanged_toBreak_emitsSegmentChanged_andBreakStarted_whenBreakToggleOn() {
        let settings = NotificationSettings(
            isEnabled: true,
            notifyOnSegmentChange: true,
            notifyOnBreak: true,
            notifyOnLunch: false
        )

        let from = makeWork(index: 0)
        let to = makeBreak(index: 1)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .running,
            previousSegment: from,
            currentSegment: to,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [
            .segmentChanged(from: from, to: to),
            .breakStarted(to: to)
        ])
    }

    func test_detect_segmentChanged_toLunch_emitsSegmentChanged_andLunchStarted_whenLunchToggleOn() {
        let settings = NotificationSettings(
            isEnabled: true,
            notifyOnSegmentChange: true,
            notifyOnBreak: false,
            notifyOnLunch: true
        )

        let from = makeWork(index: 0)
        let to = makeLunch(index: 1)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .running,
            previousSegment: from,
            currentSegment: to,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [
            .segmentChanged(from: from, to: to),
            .lunchStarted(to: to)
        ])
    }

    func test_detect_segmentChanged_breakToggleOff_emitsOnlySegmentChanged() {
        let settings = NotificationSettings(
            isEnabled: true,
            notifyOnSegmentChange: true,
            notifyOnBreak: false,
            notifyOnLunch: false
        )

        let from = makeWork(index: 0)
        let to = makeBreak(index: 1)

        let events = NotificationEventDetector.detect(
            previousStatus: .running,
            currentStatus: .running,
            previousSegment: from,
            currentSegment: to,
            totalDuration: 1200,
            settings: settings
        )

        XCTAssertEqual(events, [.segmentChanged(from: from, to: to)])
    }

    // MARK: - Helpers

    private func makeWork(index: Int) -> ActiveSegmentState { makeSegment(index: index, kind: .work, title: "Work") }
    private func makeBreak(index: Int) -> ActiveSegmentState { makeSegment(index: index, kind: .breakTime, title: "Break") }
    private func makeLunch(index: Int) -> ActiveSegmentState { makeSegment(index: index, kind: .lunch, title: "Lunch") }

    private func makeSegment(index: Int, kind: SegmentKind, title: String) -> ActiveSegmentState {
        // ActiveSegmentState is defined in DayPlanProgressCalculator.swift (memberwise init).
        let duration: TimeInterval = 60
        let remaining: TimeInterval = 60

        return ActiveSegmentState(
            index: index,
            kind: kind,
            title: title,
            remaining: remaining,
            duration: duration
        )
    }
}
