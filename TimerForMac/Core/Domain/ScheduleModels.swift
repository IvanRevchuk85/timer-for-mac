//
//  ScheduleModels.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

enum SegmentKind: String, Codable, CaseIterable, Sendable {
    case work
    case breakTime
    case lunch
    case custom
}

struct PlanSegment: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var kind: SegmentKind
    var title: String

    /// Duration in seconds.
    /// RU: Длительность в секундах.
    var duration: TimeInterval

    init(id: UUID = UUID(), kind: SegmentKind, title: String, duration: TimeInterval) {
        self.id = id
        self.kind = kind
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.duration = max(0, duration)
    }

    /// Normalized title fallback if empty.
    /// RU: Заголовок по умолчанию, если пустой.
    var resolvedTitle: String {
        title.isEmpty ? kind.defaultTitle : title
    }
}

struct DayPlan: Codable, Equatable, Sendable {
    var segments: [PlanSegment]

    init(segments: [PlanSegment]) {
        self.segments = segments
    }

    /// Total duration in seconds.
    /// RU: Общая длительность в секундах.
    var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + max(0, $1.duration) }
    }
}

// MARK: - Defaults

private extension SegmentKind {
    var defaultTitle: String {
        switch self {
        case .work: return "Work"
        case .breakTime: return "Break"
        case .lunch: return "Lunch"
        case .custom: return "Custom"
        }
    }
}
