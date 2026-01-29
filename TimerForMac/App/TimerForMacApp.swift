//
//  TimerForMacApp.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import SwiftUI

@main
struct TimerForMacApp: App {

    // MARK: - Dependencies

    private let container = AppContainer()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            container.makeTimerRootView()
                .task {
                    await MainActor.run {
                        container.startAutoScheduleIfNeeded()
                    }
                }
        }

        Settings {
            container.makeSettingsView()
        }
    }
}
