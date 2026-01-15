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

    init() {
        self.timerEngine = TimerEngine()
    }

    // MARK: - Feature Builders

    @MainActor
    func makeTimerRootView() -> some View {
        let viewModel = TimerViewModel(timerEngine: timerEngine)
        return TimerView(viewModel: viewModel)
    }
}
