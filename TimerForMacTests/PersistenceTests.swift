//
//  PersistenceTests.swift
//  TimerForMacTests
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import XCTest
@testable import TimerForMac

final class PersistenceTests: XCTestCase {

    // MARK: - UserDefaultsStore

    func testUserDefaultsStore_ObjectForKey_NilWhenMissing_NotNilWhenSet() {
        let suiteName = "TimerForMacTests.UserDefaults.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)
        let key = "test.exists"

        XCTAssertNil(store.object(forKey: key))

        store.set(false, forKey: key)
        XCTAssertNotNil(store.object(forKey: key))

        store.removeObject(forKey: key)
        XCTAssertNil(store.object(forKey: key))
    }

    func testUserDefaultsStore_SetAndReadInteger() {
        let suiteName = "TimerForMacTests.UserDefaults.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)

        store.set(42, forKey: "test.int")
        XCTAssertEqual(store.integer(forKey: "test.int"), 42)
    }

    func testUserDefaultsStore_SetAndReadBool() {
        let suiteName = "TimerForMacTests.UserDefaults.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)

        store.set(true, forKey: "test.bool")
        XCTAssertTrue(store.bool(forKey: "test.bool"))

        store.set(false, forKey: "test.bool")
        XCTAssertFalse(store.bool(forKey: "test.bool"))
    }

    // MARK: - UserDefaultsSettingsStore

    func testSettingsStore_DefaultsWhenKeysMissing() {
        let suiteName = "TimerForMacTests.Settings.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)
        let settings = UserDefaultsSettingsStore(
            store: store,
            defaultTimerTargetMinutes: 60,
            defaultMinimalMode: false,
            defaultPreventSleep: false
        )

        XCTAssertEqual(settings.timerTargetMinutes, 60)
        XCTAssertFalse(settings.isMinimalModeEnabled)
        XCTAssertFalse(settings.isPreventSleepEnabled)
    }

    func testSettingsStore_BoolFalseIsNotTreatedAsMissing() {
        // Key point: default is TRUE, but stored value is FALSE.
        // If existence-check is wrong, it would incorrectly return default TRUE.
        let suiteName = "TimerForMacTests.Settings.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)

        // Store explicit false values
        store.set(false, forKey: AppStorageKeys.uiMinimalMode)
        store.set(false, forKey: AppStorageKeys.uiPreventSleep)

        let settings = UserDefaultsSettingsStore(
            store: store,
            defaultTimerTargetMinutes: 60,
            defaultMinimalMode: true,
            defaultPreventSleep: true
        )

        XCTAssertFalse(settings.isMinimalModeEnabled)
        XCTAssertFalse(settings.isPreventSleepEnabled)
    }

    func testSettingsStore_PersistsValuesAcrossInstances() {
        let suiteName = "TimerForMacTests.Settings.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        do {
            let store = UserDefaultsStore(defaults: defaults)
            let settings = UserDefaultsSettingsStore(store: store, defaultTimerTargetMinutes: 60)

            settings.timerTargetMinutes = 25
            settings.isMinimalModeEnabled = true
            settings.isPreventSleepEnabled = true
        }

        do {
            let store2 = UserDefaultsStore(defaults: defaults)
            let settings2 = UserDefaultsSettingsStore(store: store2, defaultTimerTargetMinutes: 60)

            XCTAssertEqual(settings2.timerTargetMinutes, 25)
            XCTAssertTrue(settings2.isMinimalModeEnabled)
            XCTAssertTrue(settings2.isPreventSleepEnabled)
        }
    }

    // MARK: - DayPlanRepository

    func testDayPlanRepository_WhenFileMissing_ReturnsDefaultPlan() {
        let tmp = FileManager.default.temporaryDirectory
        let fileURL = tmp.appendingPathComponent("TimerForMacTests-\(UUID().uuidString).json")

        // Ensure missing
        try? FileManager.default.removeItem(at: fileURL)

        let repo = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )

        let loaded = repo.load()
        XCTAssertEqual(loaded.segments.count, 0)
    }

    func testDayPlanRepository_SaveAndLoad_Roundtrip() {
        let tmp = FileManager.default.temporaryDirectory
        let fileURL = tmp.appendingPathComponent("TimerForMacTests-\(UUID().uuidString).json")

        defer { try? FileManager.default.removeItem(at: fileURL) }

        let repo = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )

        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
            PlanSegment(kind: .lunch, title: "Lunch", duration: 30)
        ])

        repo.save(plan)
        let loaded = repo.load()

        XCTAssertEqual(loaded, plan)
    }
}
