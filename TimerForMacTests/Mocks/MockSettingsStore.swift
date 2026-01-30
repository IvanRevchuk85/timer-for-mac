//
//  MockSettingsStore.swift
//  TimerForMacTests
//
//  Created by Ivan Revchuk on 30.01.2026.
//

import Foundation
@testable import TimerForMac

/// English: Test-only SettingsStore mock.
/// Russian: Мок SettingsStore только для тестов.
final class MockSettingsStore: SettingsStore, @unchecked Sendable {

    // MARK: - SettingsStore

    var timerRecoveryState: TimerRecoveryState = .default
    var selectedDayPlanID: UUID?
    var notificationSettings: NotificationSettings = .default

    var timerTargetMinutes: Int = 25
    var isMinimalModeEnabled: Bool = false
    var isPreventSleepEnabled: Bool = false

    var dailySchedule: DailySchedule = DailySchedule(
        startTime: LocalTime(hour: 9, minute: 0)!,
        stopTime: LocalTime(hour: 18, minute: 0)!,
        weekdays: [],
        isEnabled: false,
        timeZoneMode: .system,
        dstPolicy: .default
    )

    // MARK: - Init

    init(
        timerTargetMinutes: Int = 25,
        dailySchedule: DailySchedule? = nil,
        notificationSettings: NotificationSettings = .default
    ) {
        self.timerTargetMinutes = timerTargetMinutes
        if let dailySchedule { self.dailySchedule = dailySchedule }
        self.notificationSettings = notificationSettings
    }
}
