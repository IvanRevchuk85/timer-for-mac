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

    init(
        store: UserDefaultsStoring,
        defaultTimerTargetMinutes: Int = 60,
        defaultMinimalMode: Bool = false,
        defaultPreventSleep: Bool = false,
        defaultDailySchedule: DailySchedule = UserDefaultsSettingsStore.makeDefaultDailySchedule()
    ) {
        self.store = store
        self.defaultTimerTargetMinutes = defaultTimerTargetMinutes
        self.defaultMinimalMode = defaultMinimalMode
        self.defaultPreventSleep = defaultPreventSleep
        self.defaultDailySchedule = defaultDailySchedule
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
                // If stored data is corrupted or schema changed, fall back safely.
                return defaultDailySchedule
            }
        }
        set {
            do {
                let data = try jsonEncoder.encode(newValue)
                store.set(data, forKey: AppStorageKeys.dailySchedule)
            } catch {
                // Do not write corrupted/partial data.
                // Intentionally ignore, keeping the previous stored value.
            }
        }
    }

    // MARK: Helpers

    private func hasValue(forKey key: String) -> Bool {
        // `object(forKey:)` distinguishes "missing" from stored `false`.
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
