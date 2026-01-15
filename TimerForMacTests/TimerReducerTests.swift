//
//  TimerReducerTests.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import XCTest
@testable import TimerForMac

final class TimerReducerTests: XCTestCase {
    func testStartSetsRunningAndResetsElapsed() {
        let reducer = TimerReducer()
        let initial = TimerSnapshot(status: .idle, elapsed: 10, target: nil)

        let next = reducer.reduce(state: initial, action: .start(target: 60))

        XCTAssertEqual(next.status, .running)
        XCTAssertEqual(next.elapsed, 0)
        XCTAssertEqual(next.target, 60)
    }

    func testTickAccumulatesWhileRunning() {
        let reducer = TimerReducer()
        let running = TimerSnapshot(status: .running, elapsed: 5, target: nil)

        let next = reducer.reduce(state: running, action: .tick(delta: 2))

        XCTAssertEqual(next.elapsed, 7)
        XCTAssertEqual(next.status, .running)
    }

    func testTickDoesNothingWhenPaused() {
        let reducer = TimerReducer()
        let paused = TimerSnapshot(status: .paused, elapsed: 5, target: 10)

        let next = reducer.reduce(state: paused, action: .tick(delta: 2))

        XCTAssertEqual(next, paused)
    }

    func testCountdownFinishesAtTarget() {
        let reducer = TimerReducer()
        let running = TimerSnapshot(status: .running, elapsed: 9, target: 10)

        let next = reducer.reduce(state: running, action: .tick(delta: 5))

        XCTAssertEqual(next.status, .finished)
        XCTAssertEqual(next.elapsed, 10)
        XCTAssertEqual(next.remaining, 0)
    }
}
