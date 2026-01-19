//
//  DayPlanViewModel.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 16.01.2026.
//

import Foundation
import Combine

// MARK: - DayPlanViewModel
@MainActor
final class DayPlanViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var plan: DayPlan
    @Published private(set) var currentPosition: SchedulePosition?

    // MARK: - Dependencies
    private let repository: DayPlanRepositoryProtocol
    private let elapsedProvider: @Sendable () -> TimeInterval

    // MARK: - Init
    init(
        repository: DayPlanRepositoryProtocol,
        elapsedProvider: @escaping @Sendable () -> TimeInterval
    ) {
        self.repository = repository
        self.elapsedProvider = elapsedProvider

        let loaded = repository.load()
        self.plan = loaded
        self.currentPosition = Self.makePosition(plan: loaded, elapsed: elapsedProvider)
    }

    // MARK: - Public API
    func refresh() {
        let loaded = repository.load()
        plan = loaded
        currentPosition = Self.makePosition(plan: loaded, elapsed: elapsedProvider)
    }

    func updatePosition() {
        currentPosition = Self.makePosition(plan: plan, elapsed: elapsedProvider)
    }

    // MARK: - Helpers
    private static func makePosition(
        plan: DayPlan,
        elapsed: @Sendable () -> TimeInterval
    ) -> SchedulePosition? {
        let safeElapsed = max(0, elapsed())
        return ScheduleCalculator.position(in: plan, elapsed: safeElapsed)
    }
}
