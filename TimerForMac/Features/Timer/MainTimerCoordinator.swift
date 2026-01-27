//
//  MainTimerCoordinator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation
import Combine

@MainActor
final class MainTimerCoordinator {
    private let timerViewModel: TimerViewModel
    private let dayPlanViewModel: DayPlanViewModel
    private let settings: SettingsStore

    private var cancellables = Set<AnyCancellable>()

    init(timerViewModel: TimerViewModel, dayPlanViewModel: DayPlanViewModel, settings: SettingsStore) {
        self.timerViewModel = timerViewModel
        self.dayPlanViewModel = dayPlanViewModel
        self.settings = settings

        bind()
    }

    func startSelectedDayPlan() {
        let plan = dayPlanViewModel.plan

        if settings.selectedDayPlanID == nil {
            settings.selectedDayPlanID = plan.id
        }

        timerViewModel.configureTargetFromDayPlanIfPossible(plan)
        timerViewModel.onStart()
    }

    private func bind() {
        dayPlanViewModel.$plan
            .removeDuplicates()
            .sink { [weak self] plan in
                guard let self else { return }

                if self.settings.selectedDayPlanID == nil {
                    self.settings.selectedDayPlanID = plan.id
                }

                self.timerViewModel.configureTargetFromDayPlanIfPossible(plan)
            }
            .store(in: &cancellables)
    }
}
