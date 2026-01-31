//
//  TimerRecoveryCoordinator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 30.01.2026.
//

import AppKit
import Foundation

/// English: Coordinates timer recovery on macOS lifecycle events (launch, sleep/wake, app activation).
/// Russian: Координатор восстановления таймера на событиях жизненного цикла macOS (запуск, sleep/wake, активизация).
final class TimerRecoveryCoordinator {

    // MARK: - Dependencies

    private let timerEngine: TimerEngineProtocol
    private let appNotificationCenter: NotificationCenter
    private let workspace: NSWorkspace

    // MARK: - State

    private var appObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var isStarted = false

    // MARK: - Init

    init(
        timerEngine: TimerEngineProtocol,
        appNotificationCenter: NotificationCenter = .default,
        workspace: NSWorkspace = .shared
    ) {
        self.timerEngine = timerEngine
        self.appNotificationCenter = appNotificationCenter
        self.workspace = workspace
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    /// English: Starts observing lifecycle events and triggers recovery.
    /// Russian: Начинает слушать события жизненного цикла и триггерит восстановление.
    func start() {
        guard isStarted == false else { return }
        isStarted = true

        let engine = timerEngine
        let wsCenter = workspace.notificationCenter

        @Sendable func trigger(_ reason: StaticString) {
            // English: Reserved for future logging hook.
            // Russian: Зарезервировано под логирование.
            _ = reason

            Task {
                await engine.recoverIfNeeded()
            }
        }

        // 1) App becomes active (best public approximation for "unlock" in sandboxed apps).
        appObservers.append(
            appNotificationCenter.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                trigger("app.didBecomeActive")
            }
        )

        // 2) Wake.
        workspaceObservers.append(
            wsCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                trigger("workspace.didWake")
            }
        )

        // Optional: Usually not needed; wake + active are enough. Uncomment only if you have a proven gap.
        // workspaceObservers.append(
        //     wsCenter.addObserver(
        //         forName: NSWorkspace.willSleepNotification,
        //         object: nil,
        //         queue: .main
        //     ) { _ in
        //         trigger("workspace.willSleep")
        //     }
        // )

        // 3) Initial recovery on launch.
        trigger("app.launch")
    }

    /// English: Stops observing lifecycle events.
    /// Russian: Останавливает наблюдение за событиями.
    func stop() {
        guard isStarted else { return }
        isStarted = false

        appObservers.forEach { appNotificationCenter.removeObserver($0) }
        workspaceObservers.forEach { workspace.notificationCenter.removeObserver($0) }

        appObservers.removeAll()
        workspaceObservers.removeAll()
    }
}
