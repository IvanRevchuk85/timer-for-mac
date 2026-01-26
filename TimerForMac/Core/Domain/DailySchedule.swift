//
//  DailySchedule.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 21.01.2026.
//

import Foundation

/// Represents a daily auto start/stop schedule.
/// This model is intentionally date-free: it stores time-of-day, weekday selection,
/// and time zone behavior, so the calculation service can reliably compute next events.
public struct DailySchedule: Hashable, Codable, Sendable {
    public var startTime: LocalTime
    public var stopTime: LocalTime
    public var weekdays: Set<Weekday>
    public var isEnabled: Bool
    public var timeZoneMode: TimeZoneMode
    public var dstPolicy: DSTPolicy

    public init(
        startTime: LocalTime,
        stopTime: LocalTime,
        weekdays: Set<Weekday>,
        isEnabled: Bool,
        timeZoneMode: TimeZoneMode = .system,
        dstPolicy: DSTPolicy = .default
    ) {
        self.startTime = startTime
        self.stopTime = stopTime
        self.weekdays = weekdays
        self.isEnabled = isEnabled
        self.timeZoneMode = timeZoneMode
        self.dstPolicy = dstPolicy
    }

    /// Indicates whether the time window crosses midnight.
    /// Example: start=22:00, stop=06:00 -> crosses midnight.
    public var crossesMidnight: Bool {
        startTime > stopTime
    }

    /// Returns `true` if the schedule has enough data to be actionable.
    /// Note: This does not validate business rules like "start != stop" if you decide to enforce it.
    public var isActionable: Bool {
        isEnabled && !weekdays.isEmpty
    }
}

// MARK: - Time zone behavior

public extension DailySchedule {
    /// Defines how the schedule interprets local time zone.
    enum TimeZoneMode: Hashable, Codable, Sendable {
        /// Always use the system's current time zone (updates automatically when the system changes).
        case system

        /// Use a fixed time zone identifier (e.g., "Europe/Kyiv").
        case fixed(identifier: String)

        /// Resolves the effective TimeZone to use at runtime.
        public func resolve() -> TimeZone {
            switch self {
            case .system:
                return .autoupdatingCurrent
            case .fixed(let identifier):
                return TimeZone(identifier: identifier) ?? .autoupdatingCurrent
            }
        }
    }
}

// MARK: - DST policy

public extension DailySchedule {
    /// Defines how to resolve DST-related ambiguities:
    /// - Missing time: a local wall-clock time that does not exist (spring forward).
    /// - Repeated time: a local wall-clock time that happens twice (fall back).
    struct DSTPolicy: Hashable, Codable, Sendable {
        public enum MissingTime: String, Codable, Hashable, Sendable {
            /// Fail scheduling if the local time does not exist.
            case strict
            /// Move forward to the next valid local time.
            case nextTime
        }

        public enum RepeatedTime: String, Codable, Hashable, Sendable {
            /// Choose the first occurrence of the repeated local time.
            case first
            /// Choose the last occurrence of the repeated local time.
            case last
        }

        public var missingTime: MissingTime
        public var repeatedTime: RepeatedTime

        public init(missingTime: MissingTime, repeatedTime: RepeatedTime) {
            self.missingTime = missingTime
            self.repeatedTime = repeatedTime
        }

        public static let `default` = DSTPolicy(missingTime: .nextTime, repeatedTime: .first)
    }
}
