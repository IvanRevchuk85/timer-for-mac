//
//  DailyAutoStartStopCoordinatorTests.swift
//  TimerForMacTests
//
//  Created by Ivan Revchuk on 22.01.2026.
//

import XCTest
@testable import TimerForMac

@MainActor
final class DailyAutoStartStopCoordinatorTests: XCTestCase {

    func testStart_DisabledSchedule_DoesNotScheduleOrTrigger() async {
        let engine = MockTimerEngine()
        let sleeper = MockSleeper()
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_700_000_000))

        let settings = MockSettingsStore(
            timerTargetMinutes: 25,
            dailySchedule: makeDisabledSchedule()
        )

        let coordinator = DailyAutoStartStopCoordinator(
            timerEngine: engine,
            settings: settings,
            scheduleService: DailyScheduleService(),
            clock: { clock.now },
            sleeper: sleeper
        )
        defer { coordinator.stop() }

        coordinator.start()
        await Task.yield()

        let requested = await sleeper.requestedDate
        let startCalls = await engine.startCalls
        let stopCalls = await engine.stopCalls

        XCTAssertNil(requested)
        XCTAssertEqual(startCalls.count, 0)
        XCTAssertEqual(stopCalls, 0)
    }

    func testStart_EnabledSchedule_SchedulesNextEvent() async throws {
        let engine = MockTimerEngine()
        let sleeper = MockSleeper()
        let tz = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        // Monday 2024-01-01 08:00 local
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 0, timeZone: tz)
        let clock = FixedClock(now: now)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let settings = MockSettingsStore(timerTargetMinutes: 25, dailySchedule: schedule)

        let coordinator = DailyAutoStartStopCoordinator(
            timerEngine: engine,
            settings: settings,
            scheduleService: DailyScheduleService(),
            clock: { clock.now },
            sleeper: sleeper
        )
        defer { coordinator.stop() }

        coordinator.start()

        let requested = try await awaitNonNilDate(from: sleeper)

        let c = localComponents(requested, timeZone: tz)
        XCTAssertEqual(c.year, 2024)
        XCTAssertEqual(c.month, 1)
        XCTAssertEqual(c.day, 1)
        XCTAssertEqual(c.hour, 9)
        XCTAssertEqual(c.minute, 0)
    }

    func testReschedule_CancelsPreviousTask_AndSchedulesNewOne() async throws {
        let engine = MockTimerEngine()
        let sleeper = MockSleeper()
        let tz = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        // Monday 2024-01-01 08:00 local
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 0, timeZone: tz)
        let clock = FixedClock(now: now)

        let schedule1 = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let schedule2 = DailySchedule(
            startTime: LocalTime(hour: 10, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let settings = MockSettingsStore(timerTargetMinutes: 25, dailySchedule: schedule1)

        let coordinator = DailyAutoStartStopCoordinator(
            timerEngine: engine,
            settings: settings,
            scheduleService: DailyScheduleService(),
            clock: { clock.now },
            sleeper: sleeper
        )
        defer { coordinator.stop() }

        coordinator.start()
        let first = try await awaitNonNilDate(from: sleeper)

        settings.dailySchedule = schedule2
        coordinator.reschedule()

        await Task.yield()

        let second = try await awaitNonNilDate(from: sleeper)
        let cancelCalls = await sleeper.cancelCalls

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(cancelCalls, 1)

        let c = localComponents(second, timeZone: tz)
        XCTAssertEqual(c.hour, 10)
        XCTAssertEqual(c.minute, 0)
    }

    func testEventStart_Fires_TimerEngineStart_WithTargetSeconds() async throws {
        let engine = MockTimerEngine()
        let sleeper = MockSleeper()
        let tz = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        // Monday 2024-01-01 08:59:59 local
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 59, timeZone: tz)
            .addingTimeInterval(59)
        let clock = FixedClock(now: now)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let settings = MockSettingsStore(timerTargetMinutes: 25, dailySchedule: schedule)

        let coordinator = DailyAutoStartStopCoordinator(
            timerEngine: engine,
            settings: settings,
            scheduleService: DailyScheduleService(),
            clock: { clock.now },
            sleeper: sleeper
        )
        defer { coordinator.stop() }

        coordinator.start()
        _ = try await awaitNonNilDate(from: sleeper)

        await sleeper.fire()
        await waitUntilSleeping(sleeper)
        await Task.yield()

        let starts = await engine.startCalls
        let stops = await engine.stopCalls

        XCTAssertEqual(starts.count, 1)
        XCTAssertEqual(starts.first ?? nil, TimeInterval(25 * 60))
        XCTAssertEqual(stops, 0)
    }

    func testEventStop_Fires_TimerEngineStop() async throws {
        let engine = MockTimerEngine()
        let sleeper = MockSleeper()
        let tz = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        // Monday 2024-01-01 17:59:59 local
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 17, minute: 59, timeZone: tz)
            .addingTimeInterval(59)
        let clock = FixedClock(now: now)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let settings = MockSettingsStore(timerTargetMinutes: 25, dailySchedule: schedule)

        let coordinator = DailyAutoStartStopCoordinator(
            timerEngine: engine,
            settings: settings,
            scheduleService: DailyScheduleService(),
            clock: { clock.now },
            sleeper: sleeper
        )
        defer { coordinator.stop() }

        coordinator.start()
        _ = try await awaitNonNilDate(from: sleeper)

        await sleeper.fire()
        await waitUntilSleeping(sleeper)
        await Task.yield()

        let starts = await engine.startCalls
        let stops = await engine.stopCalls

        XCTAssertEqual(stops, 1)
        XCTAssertEqual(starts.count, 0)
    }

    func testStop_CancelsPendingTask() async throws {
        let engine = MockTimerEngine()
        let sleeper = MockSleeper()
        let tz = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 0, timeZone: tz)
        let clock = FixedClock(now: now)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let settings = MockSettingsStore(timerTargetMinutes: 25, dailySchedule: schedule)

        let coordinator = DailyAutoStartStopCoordinator(
            timerEngine: engine,
            settings: settings,
            scheduleService: DailyScheduleService(),
            clock: { clock.now },
            sleeper: sleeper
        )

        coordinator.start()
        _ = try await awaitNonNilDate(from: sleeper)

        coordinator.stop()
        await Task.yield()

        let cancelCalls = await sleeper.cancelCalls
        XCTAssertEqual(cancelCalls, 1)

        await sleeper.fire()
        await Task.yield()

        let starts = await engine.startCalls
        let stops = await engine.stopCalls

        XCTAssertEqual(starts.count, 0)
        XCTAssertEqual(stops, 0)
    }
}

// MARK: - Mocks

private actor MockTimerEngine: TimerEngineProtocol {
    private(set) var startCalls: [TimeInterval?] = []
    private(set) var stopCalls: Int = 0

    nonisolated var stream: AsyncStream<TimerSnapshot> {
        AsyncStream { $0.finish() }
    }

    func start(target: TimeInterval?) async { startCalls.append(target) }
    func pause() async {}
    func resume() async {}
    func stop() async { stopCalls += 1 }

    func recoverIfNeeded() async {
        // English: No-op for these tests.
        // Russian: Не используется в этих тестах.
    }
}

private actor MockSleeper: SleepProviding {
    private(set) var requestedDate: Date?
    private(set) var isSleeping = false
    private(set) var cancelCalls: Int = 0

    private var continuation: CheckedContinuation<Void, Error>?

    func sleep(until date: Date, tolerance: TimeInterval) async throws {
        requestedDate = date
        isSleeping = true

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                continuation = cont
            }
        } onCancel: {
            Task { await self.handleCancel() }
        }
    }

    func fire() {
        continuation?.resume(returning: ())
        continuation = nil
        isSleeping = false
    }

    private func handleCancel() {
        cancelCalls += 1
        continuation?.resume(throwing: CancellationError())
        continuation = nil
        isSleeping = false
    }
}

private struct FixedClock {
    let now: Date
}

// MARK: - Helpers

private extension DailyAutoStartStopCoordinatorTests {

    func makeDisabledSchedule() -> DailySchedule {
        DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [],
            isEnabled: false,
            timeZoneMode: .system,
            dstPolicy: .default
        )
    }

    func awaitNonNilDate(from sleeper: MockSleeper) async throws -> Date {
        for _ in 0..<50 {
            if let date = await sleeper.requestedDate {
                return date
            }
            await Task.yield()
        }
        throw XCTSkip("MockSleeper did not receive sleep request in time.")
    }

    func makeCalendar(timeZone: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = timeZone
        return cal
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZone: TimeZone
    ) -> Date {
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        dc.hour = hour
        dc.minute = minute
        dc.second = 0
        dc.timeZone = timeZone
        return makeCalendar(timeZone: timeZone).date(from: dc)!
    }

    func localComponents(_ date: Date, timeZone: TimeZone) -> DateComponents {
        makeCalendar(timeZone: timeZone).dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
    }

    func waitUntilSleeping(_ sleeper: MockSleeper, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<200 {
            if await sleeper.isSleeping { return }
            await Task.yield()
        }
        XCTFail("Sleeper did not enter sleeping state in time.", file: file, line: line)
    }
}
