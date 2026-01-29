//
//  AppStorageKeys.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

// MARK: - AppStorageKeys
enum AppStorageKeys {
    // MARK: - UserDefaults Keys
    static let lastUsedPlanVersion = "lastUsedPlanVersion"

    static let timerTargetMinutes = "timerTargetMinutes"
    static let uiMinimalMode = "uiMinimalMode"
    static let uiPreventSleep = "uiPreventSleep"

    static let dailySchedule = "dailySchedule"
    static let selectedDayPlanID = "selectedDayPlanID"
    static let notificationSettings = "notificationSettings"
}
