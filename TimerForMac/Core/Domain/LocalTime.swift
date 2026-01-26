//
//  LocalTime.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 21.01.2026.
//

import Foundation

/// Represents a local time without a date or time zone (hour and minute).
/// Used for daily schedules where only time-of-day matters.
public struct LocalTime: Hashable, Codable, Comparable, Sendable {
    public let hour: Int
    public let minute: Int

    /// Creates a LocalTime if the provided values are valid.
    /// Valid ranges: hour ∈ 0...23, minute ∈ 0...59.
    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// Total minutes since midnight (00:00).
    public var totalMinutes: Int {
        hour * 60 + minute
    }

    /// Total seconds since midnight (00:00).
    public var secondsFromMidnight: Int {
        totalMinutes * 60
    }

    /// DateComponents representation (hour/minute only).
    /// Note: no date fields are set intentionally.
    public var dateComponents: DateComponents {
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        return dc
    }

    /// Formats time as "HH:mm".
    public var hhmm: String {
        String(format: "%02d:%02d", hour, minute)
    }

    public static func < (lhs: LocalTime, rhs: LocalTime) -> Bool {
        lhs.totalMinutes < rhs.totalMinutes
    }
}
