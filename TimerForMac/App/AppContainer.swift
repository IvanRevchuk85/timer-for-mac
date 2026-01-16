//
//  AppContainer.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import SwiftUI

final class AppContainer {
    // MARK: - Core Services

    private let timerEngine: TimerEngineProtocol
    private let userDefaultsStore: UserDefaultsStoring
    private let settingsStore: SettingsStore

    init() {
        self.timerEngine = TimerEngine()

        let defaults = UserDefaultsStore()
        self.userDefaultsStore = defaults
        self.settingsStore = UserDefaultsSettingsStore(
            store: defaults,
            defaultTimerTargetMinutes: 25
        )
    }

    // MARK: - Feature Builders

    @MainActor
    func makeTimerRootView() -> some View {
        let viewModel = TimerViewModel(timerEngine: timerEngine, settings: settingsStore)
        return TimerView(viewModel: viewModel)
    }
}
