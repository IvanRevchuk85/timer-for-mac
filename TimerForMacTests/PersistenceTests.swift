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

    func testUserDefaultsStore_SetAndReadData() {
        let suiteName = "TimerForMacTests.UserDefaults.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)

        let data = Data([0x01, 0x02, 0x03])
        store.set(data, forKey: "test.data")

        XCTAssertEqual(store.data(forKey: "test.data"), data)
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

        XCTAssertFalse(settings.dailySchedule.isEnabled)
        XCTAssertTrue(settings.dailySchedule.weekdays.isEmpty)
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

    func testSettingsStore_DailySchedule_DefaultWhenMissing() {
        let suiteName = "TimerForMacTests.Settings.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(defaults: defaults)

        let defaultSchedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [],
            isEnabled: false,
            timeZoneMode: .system,
            dstPolicy: .default
        )

        let settings = UserDefaultsSettingsStore(
            store: store,
            defaultTimerTargetMinutes: 60,
            defaultMinimalMode: false,
            defaultPreventSleep: false,
            defaultDailySchedule: defaultSchedule
        )

        XCTAssertEqual(settings.dailySchedule, defaultSchedule)
    }

    func testSettingsStore_DailySchedule_PersistsAcrossInstances() {
        let suiteName = "TimerForMacTests.Settings.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let defaultSchedule = DailySchedule(
            startTime: LocalTime(hour: 9, minute: 0)!,
            stopTime: LocalTime(hour: 18, minute: 0)!,
            weekdays: [],
            isEnabled: false,
            timeZoneMode: .system,
            dstPolicy: .default
        )

        let schedule = DailySchedule(
            startTime: LocalTime(hour: 8, minute: 30)!,
            stopTime: LocalTime(hour: 17, minute: 15)!,
            weekdays: [.monday, .wednesday, .friday],
            isEnabled: true,
            timeZoneMode: .fixed(identifier: "Europe/Kyiv"),
            dstPolicy: .init(missingTime: .nextTime, repeatedTime: .last)
        )

        do {
            let store1 = UserDefaultsStore(defaults: defaults)
            let settings1 = UserDefaultsSettingsStore(
                store: store1,
                defaultTimerTargetMinutes: 60,
                defaultDailySchedule: defaultSchedule
            )

            settings1.dailySchedule = schedule
        }

        do {
            let store2 = UserDefaultsStore(defaults: defaults)
            let settings2 = UserDefaultsSettingsStore(
                store: store2,
                defaultTimerTargetMinutes: 60,
                defaultDailySchedule: defaultSchedule
            )

            XCTAssertEqual(settings2.dailySchedule, schedule)
        }
    }

    // MARK: - DayPlanRepository

    func testDayPlanRepository_WhenFileMissing_ReturnsDefaultPlan() {
        let tmp = FileManager.default.temporaryDirectory
        let fileURL = tmp.appendingPathComponent("TimerForMacTests-\(UUID().uuidString).json")

        // Ensure missing
        try? FileManager.default.removeItem(at: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let repo = DayPlanRepository(
            fileStore: JSONFileStore(),
            fileURL: fileURL,
            defaultPlanProvider: { DayPlan(segments: []) }
        )

        let exp = expectation(description: "Load returns default plan when file is missing")

        repo.load { loaded in
            XCTAssertEqual(loaded.segments.count, 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
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

        let exp = expectation(description: "Save then load returns the same plan")

        repo.save(plan) { result in
            switch result {
            case .success:
                repo.load { loaded in
                    XCTAssertEqual(loaded, plan)
                    exp.fulfill()
                }
            case .failure(let error):
                XCTFail("Save failed: \(error)")
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
}
