//
//  DailyScheduleServiceTests.swift
//  TimerForMacTests
//
//  Created by Ivan Revchuk on 22.01.2026.
//

import XCTest
@testable import TimerForMac

final class DailyScheduleServiceTests: XCTestCase {

    private let service = DailyScheduleService()

    // MARK: - Basics

    func testNextStart_Disabled_ReturnsNil() {
        let tz = TimeZone(identifier: "America/New_York")!
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            isEnabled: false,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        XCTAssertNil(service.nextStart(after: now, schedule: schedule))
        XCTAssertNil(service.nextStop(after: now, schedule: schedule))
        XCTAssertNil(service.nextEvent(after: now, schedule: schedule))
    }

    func testNextStart_EnabledButWeekdaysEmpty_ReturnsNil() {
        let tz = TimeZone(identifier: "America/New_York")!
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        XCTAssertNil(service.nextStart(after: now, schedule: schedule))
        XCTAssertNil(service.nextStop(after: now, schedule: schedule))
        XCTAssertNil(service.nextEvent(after: now, schedule: schedule))
    }

    // MARK: - Weekday / day change

    func testNextStart_SameDay_WhenInFutureAndWeekdayMatches() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // 2024-01-01 is Monday
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 8, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let next = try XCTUnwrap(service.nextStart(after: now, schedule: schedule))
        let c = localComponents(next, timeZone: tz)

        XCTAssertEqual(c.year, 2024)
        XCTAssertEqual(c.month, 1)
        XCTAssertEqual(c.day, 1)
        XCTAssertEqual(c.hour, 9)
        XCTAssertEqual(c.minute, 0)
        XCTAssertEqual(Weekday(calendarWeekday: c.weekday!), .monday)
    }

    func testNextStart_NextWeek_WhenAlreadyPassedToday() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // Monday 2024-01-01 10:00, start is 09:00 -> should be next Monday (2024-01-08 09:00)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let next = try XCTUnwrap(service.nextStart(after: now, schedule: schedule))
        let c = localComponents(next, timeZone: tz)

        XCTAssertEqual(c.year, 2024)
        XCTAssertEqual(c.month, 1)
        XCTAssertEqual(c.day, 8)
        XCTAssertEqual(c.hour, 9)
        XCTAssertEqual(c.minute, 0)
        XCTAssertEqual(Weekday(calendarWeekday: c.weekday!), .monday)
    }

    // MARK: - Cross-midnight window

    func testNextStop_CrossesMidnight_StopIsNextDay() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // Monday 2024-01-01 21:00
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 21, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 22, minute: 0)!,
            stopTime: LocalTime(hour: 6, minute: 0)!,
            weekdays: [.monday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        let nextStart = try XCTUnwrap(service.nextStart(after: now, schedule: schedule))
        let startC = localComponents(nextStart, timeZone: tz)
        XCTAssertEqual(startC.year, 2024)
        XCTAssertEqual(startC.month, 1)
        XCTAssertEqual(startC.day, 1)
        XCTAssertEqual(startC.hour, 22)
        XCTAssertEqual(startC.minute, 0)
        XCTAssertEqual(Weekday(calendarWeekday: startC.weekday!), .monday)

        let nextStop = try XCTUnwrap(service.nextStop(after: now, schedule: schedule))
        let stopC = localComponents(nextStop, timeZone: tz)
        // stop should be Tuesday 06:00
        XCTAssertEqual(stopC.year, 2024)
        XCTAssertEqual(stopC.month, 1)
        XCTAssertEqual(stopC.day, 2)
        XCTAssertEqual(stopC.hour, 6)
        XCTAssertEqual(stopC.minute, 0)
        XCTAssertEqual(Weekday(calendarWeekday: stopC.weekday!), .tuesday)
    }

    // MARK: - DST missing time (spring forward)

    func testNextStart_DSTMissingTime_NextTimePolicy_ShiftsForward() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // US DST in 2024: 2024-03-10 jumps 02:00 -> 03:00
        let now = makeDate(year: 2024, month: 3, day: 10, hour: 0, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 2, minute: 0)!,
            stopTime: LocalTime(hour: 6, minute: 0)!,
            weekdays: [.sunday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .init(missingTime: .nextTime, repeatedTime: .first)
        )

        let next = try XCTUnwrap(service.nextStart(after: now, schedule: schedule))
        let c = localComponents(next, timeZone: tz)

        XCTAssertEqual(c.year, 2024)
        XCTAssertEqual(c.month, 3)
        XCTAssertEqual(c.day, 10)
        // 02:00 does not exist -> should move to 03:00
        XCTAssertEqual(c.hour, 3)
        XCTAssertEqual(c.minute, 0)
        XCTAssertEqual(Weekday(calendarWeekday: c.weekday!), .sunday)
    }

    func testNextStart_DSTMissingTime_StrictPolicy_SkipsToNextValidWeek() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // Same DST day
        let now = makeDate(year: 2024, month: 3, day: 10, hour: 0, minute: 0, timeZone: tz)

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 2, minute: 0)!,
            stopTime: LocalTime(hour: 6, minute: 0)!,
            weekdays: [.sunday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .init(missingTime: .strict, repeatedTime: .first)
        )

        let next = try XCTUnwrap(service.nextStart(after: now, schedule: schedule))
        let c = localComponents(next, timeZone: tz)

        // The next exact 02:00 Sunday in 2024 is 2024-03-17 02:00
        XCTAssertEqual(c.year, 2024)
        XCTAssertEqual(c.month, 3)
        XCTAssertEqual(c.day, 17)
        XCTAssertEqual(c.hour, 2)
        XCTAssertEqual(c.minute, 0)
        XCTAssertEqual(Weekday(calendarWeekday: c.weekday!), .sunday)
    }

    // MARK: - DST repeated time (fall back)

    func testNextStart_DSTRepeatedTime_FirstVsLast_DiffersByOneHour() throws {
        let tz = TimeZone(identifier: "America/New_York")!
        // US DST in 2024: 2024-11-03 repeats 01:00 hour
        let now = makeDate(year: 2024, month: 11, day: 3, hour: 0, minute: 0, timeZone: tz)

        let common = DailySchedule(
            startTime: LocalTime(hour: 1, minute: 30)!,
            stopTime: LocalTime(hour: 6, minute: 0)!,
            weekdays: [.sunday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: tz.identifier),
            dstPolicy: .default
        )

        var firstPolicy = common
        firstPolicy.dstPolicy = .init(missingTime: .nextTime, repeatedTime: .first)

        var lastPolicy = common
        lastPolicy.dstPolicy = .init(missingTime: .nextTime, repeatedTime: .last)

        let first = try XCTUnwrap(service.nextStart(after: now, schedule: firstPolicy))
        let last = try XCTUnwrap(service.nextStart(after: now, schedule: lastPolicy))

        // Same local wall-clock time, but different actual instants (usually 1 hour apart).
        XCTAssertLessThan(first, last)
        XCTAssertEqual(last.timeIntervalSince(first), 3600, accuracy: 0.5)

        let c1 = localComponents(first, timeZone: tz)
        let c2 = localComponents(last, timeZone: tz)

        XCTAssertEqual(c1.year, 2024)
        XCTAssertEqual(c1.month, 11)
        XCTAssertEqual(c1.day, 3)
        XCTAssertEqual(c1.hour, 1)
        XCTAssertEqual(c1.minute, 30)

        XCTAssertEqual(c2.year, 2024)
        XCTAssertEqual(c2.month, 11)
        XCTAssertEqual(c2.day, 3)
        XCTAssertEqual(c2.hour, 1)
        XCTAssertEqual(c2.minute, 30)
    }
}

// MARK: - Helpers

private extension DailyScheduleServiceTests {

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

        let cal = makeCalendar(timeZone: timeZone)
        return cal.date(from: dc)!
    }

    func localComponents(_ date: Date, timeZone: TimeZone) -> DateComponents {
        let cal = makeCalendar(timeZone: timeZone)
        return cal.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: date)
    }
}
