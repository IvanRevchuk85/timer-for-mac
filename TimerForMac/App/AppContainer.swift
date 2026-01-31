//
//  AppContainer.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class AppContainer {

    // MARK: - Dependencies

    private let timerEngine: TimerEngineProtocol
    private let settingsStore: SettingsStore
    private let dayPlanRepository: DayPlanRepositoryProtocol
    private let notificationService: NotificationService
    private let foregroundNotificationPresenter = ForegroundNotificationPresenter()

    // MARK: - Coordinators

    private let dailyScheduleService = DailyScheduleService()

    private var autoStartStopCoordinator: DailyAutoStartStopCoordinator?
    private var mainTimerCoordinator: MainTimerCoordinator?
    private var notificationsCoordinator: TimerNotificationsCoordinator?
    private var recoveryCoordinator: TimerRecoveryCoordinator?

    private var didStartAutoSchedule = false

    // MARK: - Init

    init() {
        UNUserNotificationCenter.current().delegate = foregroundNotificationPresenter

        // English: Settings must be created before the engine to enable persistence + recovery.
        // Russian: Settings нужно создать до engine, чтобы работали персист и восстановление.
        let defaults = UserDefaultsStore()
        let settingsStore = UserDefaultsSettingsStore(store: defaults)
        self.settingsStore = settingsStore

        self.timerEngine = TimerEngine(settings: settingsStore)

        let fileURL = Self.makeDayPlanFileURL()
        self.dayPlanRepository = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )

        self.notificationService = NotificationService()

        // English: Start lifecycle recovery triggers (launch / wake / active).
        // Russian: Запускаем триггеры восстановления (launch / wake / active).
        let recovery = TimerRecoveryCoordinator(timerEngine: timerEngine)
        self.recoveryCoordinator = recovery
        recovery.start()
    }

    // MARK: - Composition Root

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

    func makeSettingsView() -> some View {
        let vm = SettingsViewModel(
            settingsStore: settingsStore,
            notificationService: notificationService
        )
        return SettingsView(viewModel: vm)
    }

    // MARK: - AutoSchedule Public API

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

    func stopAutoSchedule() {
        autoStartStopCoordinator?.stop()
        didStartAutoSchedule = false
    }

    // MARK: - Helpers

    /// English: Must stay non-isolated to avoid `@MainActor () -> TimeInterval` type leaks into domain VMs.
    /// Russian: Должна быть nonisolated, чтобы тип `@MainActor () -> TimeInterval` не протекал в доменные VM.
    nonisolated private static func elapsedSinceStartOfToday() -> TimeInterval {
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
