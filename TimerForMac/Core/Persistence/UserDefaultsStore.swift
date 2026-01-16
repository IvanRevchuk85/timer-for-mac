//
//  UserDefaultsStore.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

// MARK: - UserDefaultsStoring
protocol UserDefaultsStoring {
    // Read
    func integer(forKey key: String) -> Int
    func bool(forKey key: String) -> Bool
    func object(forKey key: String) -> Any?

    // Write
    func set(_ value: Int, forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func removeObject(forKey key: String)
}

// MARK: - UserDefaultsStore
final class UserDefaultsStore: UserDefaultsStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func integer(forKey key: String) -> Int { defaults.integer(forKey: key) }
    func bool(forKey key: String) -> Bool { defaults.bool(forKey: key) }
    func object(forKey key: String) -> Any? { defaults.object(forKey: key) }

    func set(_ value: Int, forKey key: String) { defaults.set(value, forKey: key) }
    func set(_ value: Bool, forKey key: String) { defaults.set(value, forKey: key) }
    func removeObject(forKey key: String) { defaults.removeObject(forKey: key) }
}
