//
//  DayPlanEditorViewModel.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 20.01.2026.
//

import Foundation
import Combine

@MainActor
final class DayPlanEditorViewModel: ObservableObject {

    // MARK: - Types

    struct DraftSegment: Identifiable, Equatable, Sendable {
        let id: UUID
        var kind: SegmentKind
        var title: String
        var minutes: Int

        init(id: UUID = UUID(), kind: SegmentKind, title: String, minutes: Int) {
            self.id = id
            self.kind = kind
            self.title = title
            self.minutes = Swift.max(0, minutes)
        }
    }

    enum ValidationError: Equatable, Sendable {
        case emptyPlan
        case totalDurationIsZero
    }

    // MARK: - Constants

    /// Maximum allowed duration per segment in minutes.
    nonisolated private static let maxMinutesPerSegment = 12 * 60

    // MARK: - State

    @Published private(set) var segments: [DraftSegment]
    @Published private(set) var errors: [ValidationError] = []
    @Published private(set) var saveErrorMessage: String?

    // MARK: - Dependencies

    private let repository: DayPlanRepositoryProtocol

    // MARK: - Init

    init(plan: DayPlan, repository: DayPlanRepositoryProtocol) {
        self.repository = repository
        self.segments = Self.toDraftSegments(plan: plan)
        self.errors = Self.validate(segments: self.segments)
    }

    // MARK: - Public API

    func addSegment(kind: SegmentKind) {
        segments.append(
            DraftSegment(
                kind: kind,
                title: Self.defaultTitle(for: kind),
                minutes: Self.defaultMinutes(for: kind)
            )
        )
        revalidate()
    }

    func removeSegment(id: UUID) {
        segments.removeAll { $0.id == id }
        revalidate()
    }

    func removeSegments(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard segments.indices.contains(index) else { continue }
            segments.remove(at: index)
        }
        revalidate()
    }

    func moveSegments(from source: IndexSet, to destination: Int) {
        segments = segments.moving(from: source, to: destination)
        revalidate()
    }

    func updateKind(id: UUID, kind: SegmentKind) {
        guard let idx = segments.firstIndex(where: { $0.id == id }) else { return }

        segments[idx].kind = kind

        let trimmed = segments[idx].title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            segments[idx].title = Self.defaultTitle(for: kind)
        }

        revalidate()
    }

    func updateTitle(id: UUID, title: String) {
        guard let idx = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[idx].title = title
        revalidate()
    }

    func updateMinutes(id: UUID, minutes: Int) {
        guard let idx = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[idx].minutes = Self.clampMinutes(minutes)
        revalidate()
    }

    var isValid: Bool { errors.isEmpty }

    func buildPlan() -> DayPlan {
        let normalized = Self.normalized(segments: segments)

        return DayPlan(
            segments: normalized.map { draft in
                PlanSegment(
                    id: draft.id,
                    kind: draft.kind,
                    title: draft.title,
                    duration: TimeInterval(draft.minutes * 60)
                )
            }
        )
    }

    @discardableResult
    func saveIfValid(completion: @escaping (Bool) -> Void) -> Bool {
        saveErrorMessage = nil
        revalidate()
        guard errors.isEmpty else {
            completion(false)
            return false
        }

        segments = Self.normalized(segments: segments)
        revalidate()
        guard errors.isEmpty else {
            completion(false)
            return false
        }

        repository.save(buildPlan()) { [weak self] result in
            guard let self else {
                completion(false)
                return
            }

            switch result {
            case .success:
                completion(true)
            case .failure:
                self.saveErrorMessage = "Failed to save the plan."
                completion(false)
            }
        }

        return true
    }

    func applyWorkingDayTemplate() {
        segments = [
            .init(kind: .work, title: "Work", minutes: 50),
            .init(kind: .breakTime, title: "Break", minutes: 10),
            .init(kind: .work, title: "Work", minutes: 50),
            .init(kind: .lunch, title: "Lunch", minutes: 30),
            .init(kind: .work, title: "Work", minutes: 50),
            .init(kind: .breakTime, title: "Break", minutes: 10),
            .init(kind: .work, title: "Work", minutes: 50),
        ]
        revalidate()
    }

    // MARK: - Validation

    private func revalidate() {
        errors = Self.validate(segments: segments)
    }

    nonisolated static func validate(segments: [DraftSegment]) -> [ValidationError] {
        if segments.isEmpty {
            return [.emptyPlan]
        }

        let totalMinutes = segments.reduce(0) { $0 + Swift.max(0, $1.minutes) }
        if totalMinutes == 0 {
            return [.totalDurationIsZero]
        }

        return []
    }

    // MARK: - Normalization

    nonisolated private static func normalized(segments: [DraftSegment]) -> [DraftSegment] {
        segments.map { s in
            var copy = s
            copy.minutes = clampMinutes(copy.minutes)

            let trimmed = copy.title.trimmingCharacters(in: .whitespacesAndNewlines)
            copy.title = trimmed.isEmpty ? defaultTitle(for: copy.kind) : trimmed

            return copy
        }
    }

    nonisolated private static func clampMinutes(_ minutes: Int) -> Int {
        min(max(0, minutes), maxMinutesPerSegment)
    }

    // MARK: - Mapping

    nonisolated private static func toDraftSegments(plan: DayPlan) -> [DraftSegment] {
        plan.segments.map { segment in
            DraftSegment(
                id: segment.id,
                kind: segment.kind,
                title: segment.title,
                minutes: Int(segment.duration / 60)
            )
        }
    }

    // MARK: - Defaults

    nonisolated private static func defaultTitle(for kind: SegmentKind) -> String {
        switch kind {
        case .work: return "Work"
        case .breakTime: return "Break"
        case .lunch: return "Lunch"
        case .custom: return "Custom"
        }
    }

    nonisolated private static func defaultMinutes(for kind: SegmentKind) -> Int {
        switch kind {
        case .work: return 50
        case .breakTime: return 10
        case .lunch: return 30
        case .custom: return 15
        }
    }
}
