//
//  TimerForMacApp.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import SwiftUI

@main
struct TimerForMacApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            container.makeTimerRootView()
        }
    }
}
