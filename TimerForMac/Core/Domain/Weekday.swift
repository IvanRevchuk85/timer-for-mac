//
//  Weekday.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 21.01.2026.
//

import Foundation

/// Represents a weekday using a stable ISO numbering:
/// Monday = 1, ... Sunday = 7.
public enum Weekday: Int, CaseIterable, Codable, Hashable, Sendable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7

    /// Converts ISO weekday (Mon=1...Sun=7) to Calendar weekday (Sun=1...Sat=7).
    public var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }

    /// Creates Weekday from Calendar weekday (Sun=1...Sat=7).
    public init?(calendarWeekday: Int) {
        switch calendarWeekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: return nil
        }
    }

    /// Returns the weekday for the given date using the provided calendar/time zone.
    /// The mapping is stable and does not depend on locale.
    public static func from(date: Date, calendar: Calendar) -> Weekday? {
        let value = calendar.component(.weekday, from: date) // Sun=1...Sat=7
        return Weekday(calendarWeekday: value)
    }
}
