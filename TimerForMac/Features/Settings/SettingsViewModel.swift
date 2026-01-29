//
//  SettingsViewModel.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 29.01.2026.
//

import Foundation
import Combine // Required for ObservableObject / @Published

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published

    @Published var notificationSettings: NotificationSettings
    @Published var notificationPermissionError: String?

    // MARK: - Dependencies

    private let settingsStore: SettingsStore
    private let notificationService: NotificationService

    // MARK: - Init

    init(settingsStore: SettingsStore, notificationService: NotificationService) {
        self.settingsStore = settingsStore
        self.notificationService = notificationService
        self.notificationSettings = settingsStore.notificationSettings
    }

    // MARK: - Intent

    func setNotificationsEnabled(_ isEnabled: Bool) {
        notificationPermissionError = nil

        if isEnabled == false {
            notificationSettings.isEnabled = false
            persist()
            return
        }

        // Important: keep UI state mutations on MainActor
        Task { @MainActor in
            let granted = await notificationService.requestPermissionsIfNeeded()

            if granted {
                notificationSettings.isEnabled = true
                notificationPermissionError = nil
            } else {
                notificationSettings.isEnabled = false
                notificationPermissionError = "Notification permission denied. Enable it in System Settings."
            }

            persist()
        }
    }

    func persist() {
        settingsStore.notificationSettings = notificationSettings
    }
}
