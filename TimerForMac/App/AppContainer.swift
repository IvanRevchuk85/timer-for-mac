//
//  AppContainer.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation
import SwiftUI

final class AppContainer {

    // MARK: - Dependencies

    private let timerEngine: TimerEngineProtocol
    private let settingsStore: SettingsStore
    private let dayPlanRepository: DayPlanRepositoryProtocol

    // MARK: - Coordinators

    private let dailyScheduleService = DailyScheduleService()

    // Coordinator is created on MainActor (because it is @MainActor in your implementation).
    @MainActor private var autoStartStopCoordinator: DailyAutoStartStopCoordinator?

    // Keeps main bindings alive (Day Plan -> Timer).
    @MainActor private var mainTimerCoordinator: MainTimerCoordinator?

    // Guards against multiple starts when SwiftUI recreates views / tasks.
    @MainActor private var didStartAutoSchedule = false

    // MARK: - Init

    init() {
        self.timerEngine = TimerEngine()

        let defaults = UserDefaultsStore()
        self.settingsStore = UserDefaultsSettingsStore(store: defaults)

        let fileURL = Self.makeDayPlanFileURL()
        self.dayPlanRepository = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )
    }

    // MARK: - Composition Root

    @MainActor
    func makeTimerRootView() -> some View {
        let timerVM = TimerViewModel(timerEngine: timerEngine, settings: settingsStore)

        let dayPlanVM = DayPlanViewModel(
            repository: dayPlanRepository,
            elapsedProvider: Self.elapsedSinceStartOfToday,
            settings: settingsStore
        )

        // Keep coordinator alive for the lifetime of the app container.
        if mainTimerCoordinator == nil {
            mainTimerCoordinator = MainTimerCoordinator(
                timerViewModel: timerVM,
                dayPlanViewModel: dayPlanVM,
                settings: settingsStore
            )
        }

        return NavigationStack {
            TimerView(viewModel: timerVM, dayPlanViewModel: dayPlanVM)
        }
    }

    // MARK: - AutoSchedule Public API

    /// Starts daily auto start/stop exactly once for the app lifetime.
    @MainActor
    func startAutoScheduleIfNeeded() {
        guard didStartAutoSchedule == false else { return }
        didStartAutoSchedule = true

        if autoStartStopCoordinator == nil {
            autoStartStopCoordinator = DailyAutoStartStopCoordinator(
                timerEngine: timerEngine,
                settings: settingsStore,
                scheduleService: dailyScheduleService
            )
        }

        autoStartStopCoordinator?.start()
    }

    /// Optional: lets you manually stop auto schedule (useful for future lifecycle hooks / tests).
    @MainActor
    func stopAutoSchedule() {
        autoStartStopCoordinator?.stop()
        didStartAutoSchedule = false
    }

    // MARK: - Helpers

    private static func elapsedSinceStartOfToday() -> TimeInterval {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        return now.timeIntervalSince(start)
    }

    private static func makeDayPlanFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let baseURL = appSupport ?? FileManager.default.temporaryDirectory

        let folder = baseURL.appendingPathComponent("TimerForMac", isDirectory: true)

        // Ensure directory exists to avoid file write failures.
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            // Fallback to temp if AppSupport is not writable for any reason.
            let tmpFolder = FileManager.default.temporaryDirectory.appendingPathComponent("TimerForMac", isDirectory: true)
            try? FileManager.default.createDirectory(at: tmpFolder, withIntermediateDirectories: true)
            return tmpFolder.appendingPathComponent("day_plan.json")
        }

        return folder.appendingPathComponent("day_plan.json")
    }
}
