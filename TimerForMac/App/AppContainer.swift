//
//  AppContainer.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import SwiftUI

final class AppContainer {
    private let timerEngine: TimerEngineProtocol
    private let settingsStore: SettingsStore
    private let dayPlanRepository: DayPlanRepositoryProtocol

    init() {
        self.timerEngine = TimerEngine()

        let defaults = UserDefaultsStore()
        self.settingsStore = UserDefaultsSettingsStore(
            store: defaults,
            defaultTimerTargetMinutes: 25
        )

        let fileURL = Self.makeDayPlanFileURL()
        self.dayPlanRepository = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )
    }

    @MainActor
    func makeTimerRootView() -> some View {
        let timerVM = TimerViewModel(timerEngine: timerEngine, settings: settingsStore)

        let dayPlanVM = DayPlanViewModel(
            repository: dayPlanRepository,
            elapsedProvider: Self.elapsedSinceStartOfToday
        )

        return NavigationStack {
            TimerView(viewModel: timerVM, dayPlanViewModel: dayPlanVM)
        }
    }

    private static func elapsedSinceStartOfToday() -> TimeInterval {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        return now.timeIntervalSince(start)
    }

    private static func makeDayPlanFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let baseURL = appSupport ?? FileManager.default.temporaryDirectory

        let folder = baseURL.appendingPathComponent("TimerForMac", isDirectory: true)
        return folder.appendingPathComponent("day_plan.json")
    }
}
