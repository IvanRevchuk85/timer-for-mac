//
//  AppContainer.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation
import SwiftUI
import UserNotifications

final class AppContainer {

    // MARK: - Dependencies

    private let timerEngine: TimerEngineProtocol
    private let settingsStore: SettingsStore
    private let dayPlanRepository: DayPlanRepositoryProtocol
    private let notificationService: NotificationService
    private let foregroundNotificationPresenter = ForegroundNotificationPresenter()

    // MARK: - Coordinators

    private let dailyScheduleService = DailyScheduleService()

    @MainActor private var autoStartStopCoordinator: DailyAutoStartStopCoordinator?
    @MainActor private var mainTimerCoordinator: MainTimerCoordinator?
    @MainActor private var notificationsCoordinator: TimerNotificationsCoordinator?

    @MainActor private var didStartAutoSchedule = false

    // MARK: - Init

    @MainActor
    init() {
        UNUserNotificationCenter.current().delegate = foregroundNotificationPresenter

        self.timerEngine = TimerEngine()

        let defaults = UserDefaultsStore()
        self.settingsStore = UserDefaultsSettingsStore(store: defaults)

        let fileURL = Self.makeDayPlanFileURL()
        self.dayPlanRepository = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )

        self.notificationService = NotificationService()
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

        if mainTimerCoordinator == nil {
            mainTimerCoordinator = MainTimerCoordinator(
                timerViewModel: timerVM,
                dayPlanViewModel: dayPlanVM,
                settings: settingsStore
            )
        }

        if notificationsCoordinator == nil {
            notificationsCoordinator = TimerNotificationsCoordinator(
                timerEngine: timerEngine,
                notificationService: notificationService,
                planProvider: { dayPlanVM.plan },
                settingsProvider: { self.settingsStore.notificationSettings }
            )
            notificationsCoordinator?.start()
        }

        return NavigationStack {
            TimerView(viewModel: timerVM, dayPlanViewModel: dayPlanVM)
        }
    }

    @MainActor
    func makeSettingsView() -> some View {
        let vm = SettingsViewModel(
            settingsStore: settingsStore,
            notificationService: notificationService
        )
        return SettingsView(viewModel: vm)
    }

    // MARK: - AutoSchedule Public API

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

    @MainActor
    func stopAutoSchedule() {
        autoStartStopCoordinator?.stop()
        didStartAutoSchedule = false
    }

    // MARK: - Helpers

    /// Must stay non-isolated to avoid `@MainActor () -> TimeInterval` type leaks into domain VMs.
    private static func elapsedSinceStartOfToday() -> TimeInterval {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        return now.timeIntervalSince(start)
    }

    private static func makeDayPlanFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let baseURL = appSupport ?? FileManager.default.temporaryDirectory

        let folder = baseURL.appendingPathComponent("TimerForMac", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            let tmpFolder = FileManager.default.temporaryDirectory.appendingPathComponent("TimerForMac", isDirectory: true)
            try? FileManager.default.createDirectory(at: tmpFolder, withIntermediateDirectories: true)
            return tmpFolder.appendingPathComponent("day_plan.json")
        }

        return folder.appendingPathComponent("day_plan.json")
    }
}
