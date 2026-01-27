//
//  DayPlanViewModel.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 16.01.2026.
//

import Foundation
import Combine

@MainActor
final class DayPlanViewModel: ObservableObject {
    @Published private(set) var plan: DayPlan = DayPlan(segments: [])
    @Published private(set) var currentPosition: SchedulePosition?

    private let repository: DayPlanRepositoryProtocol
    private let elapsedProvider: @Sendable () -> TimeInterval
    private let settings: SettingsStore

    init(
        repository: DayPlanRepositoryProtocol,
        elapsedProvider: @escaping @Sendable () -> TimeInterval,
        settings: SettingsStore
    ) {
        self.repository = repository
        self.elapsedProvider = elapsedProvider
        self.settings = settings
        refresh()
    }

    func refresh() {
        repository.load { [weak self] loaded in
            guard let self else { return }
            self.plan = loaded

            if self.settings.selectedDayPlanID == nil {
                self.settings.selectedDayPlanID = loaded.id
            }

            self.updatePosition()
        }
    }

    func updatePosition() {
        let elapsed = Swift.max(0, elapsedProvider())
        let newPosition = ScheduleCalculator.position(in: plan, elapsed: elapsed)

        if newPosition != currentPosition {
            currentPosition = newPosition
        }
    }

    func makeEditorViewModel() -> DayPlanEditorViewModel {
        DayPlanEditorViewModel(plan: plan, repository: repository)
    }
}
