//
//  NotificationSettingsView.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 29.01.2026.
//

import SwiftUI

struct NotificationSettingsView: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section("Notifications") {
            Toggle("Enable notifications", isOn: enableBinding)

            if let error = viewModel.notificationPermissionError {
                Text(error)
                    .font(.footnote)
            }

            Toggle("Notify on start", isOn: binding(\.notifyOnStart))
                .disabled(viewModel.notificationSettings.isEnabled == false)

            Toggle("Notify on stop", isOn: binding(\.notifyOnStop))
                .disabled(viewModel.notificationSettings.isEnabled == false)

            Toggle("Notify on finish", isOn: binding(\.notifyOnFinish))
                .disabled(viewModel.notificationSettings.isEnabled == false)

            Toggle("Notify on segment change", isOn: binding(\.notifyOnSegmentChange))
                .disabled(viewModel.notificationSettings.isEnabled == false)

            Toggle("Notify on break", isOn: binding(\.notifyOnBreak))
                .disabled(viewModel.notificationSettings.isEnabled == false)

            Toggle("Notify on lunch", isOn: binding(\.notifyOnLunch))
                .disabled(viewModel.notificationSettings.isEnabled == false)
        }
    }

    // MARK: - Bindings

    private var enableBinding: Binding<Bool> {
        Binding(
            get: { viewModel.notificationSettings.isEnabled },
            set: { viewModel.setNotificationsEnabled($0) }
        )
    }

    private func binding(_ keyPath: WritableKeyPath<NotificationSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { viewModel.notificationSettings[keyPath: keyPath] },
            set: { newValue in
                viewModel.notificationSettings[keyPath: keyPath] = newValue
                viewModel.persist()
            }
        )
    }
}
