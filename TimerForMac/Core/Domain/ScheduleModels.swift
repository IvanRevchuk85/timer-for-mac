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
    var duration: TimeInterval

    init(id: UUID = UUID(), kind: SegmentKind, title: String, duration: TimeInterval) {
        self.id = id
        self.kind = kind
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.duration = max(0, duration)
    }

    /// Normalized title fallback if empty.
    var resolvedTitle: String {
        title.isEmpty ? kind.defaultTitle : title
    }
}

struct DayPlan: Codable, Equatable, Sendable {
    var id: UUID
    var segments: [PlanSegment]

    init(id: UUID = UUID(), segments: [PlanSegment]) {
        self.id = id
        self.segments = segments
    }

    /// Total duration in seconds.
    var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + max(0, $1.duration) }
    }

    // MARK: - Codable migration (backward compatible)

    private enum CodingKeys: String, CodingKey {
        case id
        case segments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.segments = try container.decode([PlanSegment].self, forKey: .segments)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(segments, forKey: .segments)
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
