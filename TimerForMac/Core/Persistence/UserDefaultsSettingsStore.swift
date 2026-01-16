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
}

// MARK: - UserDefaultsSettingsStore
final class UserDefaultsSettingsStore: SettingsStore {
    private let store: UserDefaultsStoring
    
    private let defaultTimerTargetMinutes: Int
    private let defaultMinimalMode: Bool
    private let defaultPreventSleep: Bool
    
    init(
        store: UserDefaultsStoring,
        defaultTimerTargetMinutes: Int = 60,
        defaultMinimalMode: Bool = false,
        defaultPreventSleep: Bool = false
    ) {
        self.store = store
        self.defaultTimerTargetMinutes = defaultTimerTargetMinutes
        self.defaultMinimalMode = defaultMinimalMode
        self.defaultPreventSleep = defaultPreventSleep
    }
    
    var timerTargetMinutes: Int {
        get {
            let value = store.integer(forKey: AppStorageKeys.timerTargetMinutes)
            return value > 0 ? value : defaultTimerTargetMinutes
        }
        set {
            store.set(max(1, newValue), forKey: AppStorageKeys.timerTargetMinutes)
        }
    }
    
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
    
    private func hasValue(forKey key: String) -> Bool {
        // `object(forKey:)` distinguishes "missing" from stored `false`.
        store.object(forKey: key) != nil
    }
}

