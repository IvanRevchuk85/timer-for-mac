//
//  ScheduleModels.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

import Foundation

enum SegmentKind: String, Codable, CaseIterable {
    case work
    case breakTime
    case lunch
    case custom
}

struct PlanSegment: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: SegmentKind
    var title: String
    var duration: TimeInterval

    init(id: UUID = UUID(), kind: SegmentKind, title: String, duration: TimeInterval) {
        self.id = id
        self.kind = kind
        self.title = title
        self.duration = max(0, duration)
    }
}

struct DayPlan: Codable, Equatable {
    var segments: [PlanSegment]

    init(segments: [PlanSegment]) {
        self.segments = segments
    }

    var totalDuration: TimeInterval {
        segments.reduce(0) { $0 + $1.duration }
    }
}
