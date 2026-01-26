//
//  DailyScheduleService.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 22.01.2026.
//

import Foundation

/// Computes the next auto start/stop dates for a given DailySchedule.
/// Pure logic: uses only Date/Calendar/TimeZone and schedule model.
public struct DailyScheduleService: Sendable {

    public init() {}

    public func nextStart(after now: Date, schedule: DailySchedule) -> Date? {
        guard schedule.isActionable else { return nil }
        guard schedule.startTime != schedule.stopTime else { return nil } // zero-length window is undefined

        let tz = schedule.timeZoneMode.resolve()
        let calendar = makeCalendar(timeZone: tz)

        return nextOccurrence(
            after: now,
            time: schedule.startTime,
            weekdays: schedule.weekdays,
            calendar: calendar,
            dstPolicy: schedule.dstPolicy
        )
    }

    public func nextStop(after now: Date, schedule: DailySchedule) -> Date? {
        guard schedule.isActionable else { return nil }
        guard schedule.startTime != schedule.stopTime else { return nil }

        let tz = schedule.timeZoneMode.resolve()
        let calendar = makeCalendar(timeZone: tz)

        let stopWeekdays: Set<Weekday> = schedule.crossesMidnight
            ? Set(schedule.weekdays.map { nextWeekday($0) })
            : schedule.weekdays

        return nextOccurrence(
            after: now,
            time: schedule.stopTime,
            weekdays: stopWeekdays,
            calendar: calendar,
            dstPolicy: schedule.dstPolicy
        )
    }

    public func nextEvent(after now: Date, schedule: DailySchedule) -> ScheduleEvent? {
        let start = nextStart(after: now, schedule: schedule)
        let stop = nextStop(after: now, schedule: schedule)

        switch (start, stop) {
        case (nil, nil):
            return nil
        case (let s?, nil):
            return ScheduleEvent(type: .start, fireDate: s)
        case (nil, let t?):
            return ScheduleEvent(type: .stop, fireDate: t)
        case (let s?, let t?):
            if s <= t {
                return ScheduleEvent(type: .start, fireDate: s)
            } else {
                return ScheduleEvent(type: .stop, fireDate: t)
            }
        }
    }
}

// MARK: - Public types

public struct ScheduleEvent: Hashable, Sendable {
    public enum EventType: Hashable, Sendable {
        case start
        case stop
    }

    public let type: EventType
    public let fireDate: Date

    public init(type: EventType, fireDate: Date) {
        self.type = type
        self.fireDate = fireDate
    }
}

// MARK: - Internals

private extension DailyScheduleService {

    func makeCalendar(timeZone: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.timeZone = timeZone
        return cal
    }

    func nextWeekday(_ day: Weekday) -> Weekday {
        let next = day.rawValue == 7 ? 1 : day.rawValue + 1
        return Weekday(rawValue: next)!
    }

    func matchingPolicy(for dstPolicy: DailySchedule.DSTPolicy) -> Calendar.MatchingPolicy {
        switch dstPolicy.missingTime {
        case .strict:
            return .strict
        case .nextTime:
            return .nextTime
        }
    }

    func repeatedTimePolicy(for dstPolicy: DailySchedule.DSTPolicy) -> Calendar.RepeatedTimePolicy {
        switch dstPolicy.repeatedTime {
        case .first:
            return .first
        case .last:
            return .last
        }
    }

    func nextOccurrence(
        after now: Date,
        time: LocalTime,
        weekdays: Set<Weekday>,
        calendar: Calendar,
        dstPolicy: DailySchedule.DSTPolicy
    ) -> Date? {
        guard !weekdays.isEmpty else { return nil }

        let matching = matchingPolicy(for: dstPolicy)
        let repeated = repeatedTimePolicy(for: dstPolicy)

        // Calendar.nextDate(after:) is strictly "after", not ">= now".
        // We subtract 1 second to allow returning an event at the same wall-clock time.
        let base = now.addingTimeInterval(-1)

        var best: Date?

        for weekday in weekdays {
            var dc = DateComponents()
            dc.weekday = weekday.calendarWeekday // Calendar: Sun=1...Sat=7
            dc.hour = time.hour
            dc.minute = time.minute
            dc.second = 0

            if let candidate = calendar.nextDate(
                after: base,
                matching: dc,
                matchingPolicy: matching,
                repeatedTimePolicy: repeated,
                direction: .forward
            ) {
                if best == nil || candidate < best! {
                    best = candidate
                }
            }
        }

        return best
    }
}
