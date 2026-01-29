//
//  UserDefaultsSettingsStore.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 16.01.2026.
//

import Foundation

// MARK: - SettingsStore

protocol SettingsStore: AnyObject {
    var timerTargetMinutes: Int { get set }
    var isMinimalModeEnabled: Bool { get set }
    var isPreventSleepEnabled: Bool { get set }

    var dailySchedule: DailySchedule { get set }

    var selectedDayPlanID: UUID? { get set }
    var notificationSettings: NotificationSettings { get set }
}

// MARK: - UserDefaultsSettingsStore

final class UserDefaultsSettingsStore: SettingsStore {
    private let store: UserDefaultsStoring

    private let defaultTimerTargetMinutes: Int
    private let defaultMinimalMode: Bool
    private let defaultPreventSleep: Bool
    private let defaultDailySchedule: DailySchedule

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let defaultNotificationSettings: NotificationSettings

    init(
        store: UserDefaultsStoring,
        defaultTimerTargetMinutes: Int = 60,
        defaultMinimalMode: Bool = false,
        defaultPreventSleep: Bool = false,
        defaultDailySchedule: DailySchedule = UserDefaultsSettingsStore.makeDefaultDailySchedule(),
        defaultNotificationSettings: NotificationSettings = .default
    ) {
        self.store = store
        self.defaultTimerTargetMinutes = defaultTimerTargetMinutes
        self.defaultMinimalMode = defaultMinimalMode
        self.defaultPreventSleep = defaultPreventSleep
        self.defaultDailySchedule = defaultDailySchedule
        self.defaultNotificationSettings = defaultNotificationSettings
    }

    // MARK: Timer

    var timerTargetMinutes: Int {
        get {
            let value = store.integer(forKey: AppStorageKeys.timerTargetMinutes)
            return value > 0 ? value : defaultTimerTargetMinutes
        }
        set {
            store.set(max(1, newValue), forKey: AppStorageKeys.timerTargetMinutes)
        }
    }

    // MARK: Selected Day Plan

    var selectedDayPlanID: UUID? {
        get {
            guard let raw = store.string(forKey: AppStorageKeys.selectedDayPlanID),
                  let id = UUID(uuidString: raw) else {
                return nil
            }
            return id
        }
        set {
            if let newValue {
                store.set(newValue.uuidString, forKey: AppStorageKeys.selectedDayPlanID)
            } else {
                store.removeObject(forKey: AppStorageKeys.selectedDayPlanID)
            }
        }
    }

    // MARK: UI

    var isMinimalModeEnabled: Bool {
        get {
            if hasValue(forKey: AppStorageKeys.uiMinimalMode) {
                return store.bool(forKey: AppStorageKeys.uiMinimalMode)
            }
            return defaultMinimalMode
        }
        set {
            store.set(newValue, forKey: AppStorageKeys.uiMinimalMode)
        }
    }

    var isPreventSleepEnabled: Bool {
        get {
            if hasValue(forKey: AppStorageKeys.uiPreventSleep) {
                return store.bool(forKey: AppStorageKeys.uiPreventSleep)
            }
            return defaultPreventSleep
        }
        set {
            store.set(newValue, forKey: AppStorageKeys.uiPreventSleep)
        }
    }

    // MARK: Daily schedule

    var dailySchedule: DailySchedule {
        get {
            guard let data = store.data(forKey: AppStorageKeys.dailySchedule) else {
                return defaultDailySchedule
            }

            do {
                return try jsonDecoder.decode(DailySchedule.self, from: data)
            } catch {
                return defaultDailySchedule
            }
        }
        set {
            do {
                let data = try jsonEncoder.encode(newValue)
                store.set(data, forKey: AppStorageKeys.dailySchedule)
            } catch {
                // Intentionally ignore, keeping the previous stored value.
            }
        }
    }
    
    // MARK: Notifications
    
    var notificationSettings: NotificationSettings {
        get {
            guard let data = store.data(forKey: AppStorageKeys.notificationSettings) else {
                return defaultNotificationSettings
            }

            do {
                return try jsonDecoder.decode(NotificationSettings.self, from: data)
            } catch {
                return defaultNotificationSettings
            }
        }
        set {
            do {
                let data = try jsonEncoder.encode(newValue)
                store.set(data, forKey: AppStorageKeys.notificationSettings)
            } catch {
                // Intentionally ignore, keeping the previous stored value.
            }
        }
    }


    // MARK: Helpers

    private func hasValue(forKey key: String) -> Bool {
        store.object(forKey: key) != nil
    }

    private static func makeDefaultDailySchedule() -> DailySchedule {
        let start = LocalTime(hour: 9, minute: 0) ?? LocalTime(hour: 0, minute: 0)!
        let stop = LocalTime(hour: 18, minute: 0) ?? LocalTime(hour: 0, minute: 0)!

        return DailySchedule(
            startTime: start,
            stopTime: stop,
            weekdays: [],
            isEnabled: false,
            timeZoneMode: .system,
            dstPolicy: .default
        )
    }
}
