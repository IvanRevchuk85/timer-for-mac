//
//  TimerRecoveryCalculatorTests.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 30.01.2026.
//

import XCTest
@testable import TimerForMac

final class TimerRecoveryCalculatorTests: XCTestCase {

    func testRecover_Running_UsesUptimeWhenCloseToDate() {
        let target: TimeInterval = 120

        let startDate = Date(timeIntervalSince1970: 1_000)
        let nowDate = startDate.addingTimeInterval(10)

        let startUptime: TimeInterval = 100
        let nowUptime: TimeInterval = 110

        let state = TimerRecoveryState(
            status: .running,
            targetDuration: target,
            startDate: startDate,
            startUptime: startUptime,
            accumulatedElapsed: 0,
            lastObservedDate: nil,
            lastObservedUptime: nil
        )

        let output = TimerRecoveryCalculator.recover(state: state, nowDate: nowDate, nowUptime: nowUptime)

        XCTAssertEqual(output.elapsed, 10, accuracy: 0.0001)
        XCTAssertEqual(output.remaining, 110, accuracy: 0.0001)
        XCTAssertEqual(output.state.status, .running)
    }

    func testRecover_Running_FinishesWhenElapsedReachesTarget() {
        let target: TimeInterval = 30

        let startDate = Date(timeIntervalSince1970: 1_000)
        let nowDate = startDate.addingTimeInterval(40)

        let startUptime: TimeInterval = 100
        let nowUptime: TimeInterval = 140

        let state = TimerRecoveryState(
            status: .running,
            targetDuration: target,
            startDate: startDate,
            startUptime: startUptime,
            accumulatedElapsed: 0,
            lastObservedDate: nil,
            lastObservedUptime: nil
        )

        let output = TimerRecoveryCalculator.recover(state: state, nowDate: nowDate, nowUptime: nowUptime)

        XCTAssertEqual(output.elapsed, 30, accuracy: 0.0001)
        XCTAssertEqual(output.remaining, 0, accuracy: 0.0001)
        XCTAssertEqual(output.state.status, .finished)
        XCTAssertEqual(output.state.accumulatedElapsed, 30, accuracy: 0.0001)
        XCTAssertNil(output.state.startDate)
        XCTAssertNil(output.state.startUptime)
    }

    func testRecover_Paused_DoesNotAdvanceElapsed() {
        let target: TimeInterval = 120

        let state = TimerRecoveryState(
            status: .paused,
            targetDuration: target,
            startDate: Date(timeIntervalSince1970: 1_000),
            startUptime: 100,
            accumulatedElapsed: 25,
            lastObservedDate: nil,
            lastObservedUptime: nil
        )

        let output = TimerRecoveryCalculator.recover(
            state: state,
            nowDate: Date(timeIntervalSince1970: 2_000),
            nowUptime: 1_000
        )

        XCTAssertEqual(output.elapsed, 25, accuracy: 0.0001)
        XCTAssertEqual(output.remaining, 95, accuracy: 0.0001)
        XCTAssertEqual(output.state.status, .paused)
    }

    func testRecover_Running_PrefersUptimeWhenDateSkewIsSuspicious() {
        // Policy: if wall-clock is far ahead of uptime, prefer uptime.
        let policy = TimerRecoveryCalculator.Policy(deltaTolerance: 2, maxForwardDateSkew: 60)

        let target: TimeInterval = 10_000

        let startDate = Date(timeIntervalSince1970: 1_000)
        let nowDate = startDate.addingTimeInterval(10_000) // huge date delta (simulating manual change)

        let startUptime: TimeInterval = 100
        let nowUptime: TimeInterval = 110 // only 10s uptime delta

        let state = TimerRecoveryState(
            status: .running,
            targetDuration: target,
            startDate: startDate,
            startUptime: startUptime,
            accumulatedElapsed: 0,
            lastObservedDate: nil,
            lastObservedUptime: nil
        )

        let output = TimerRecoveryCalculator.recover(
            state: state,
            nowDate: nowDate,
            nowUptime: nowUptime,
            policy: policy
        )

        XCTAssertEqual(output.elapsed, 10, accuracy: 0.0001)
    }
}
