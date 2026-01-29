//
//  NotificationService.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation
import UserNotifications

actor NotificationService {

    // MARK: - Dependencies

    private let center: NotificationCenterLike

    // MARK: - State

    private var didRequestAuthorization = false
    private var isAuthorized = false

    // MARK: - Init

    init(center: NotificationCenterLike = UNUserNotificationCenterAdapter()) {
        self.center = center
    }

    // MARK: - Public API

    /// Requests notification permissions once per app lifetime.
    /// - Returns: `true` if granted, otherwise `false`.
    func requestPermissionsIfNeeded() async -> Bool {
        if didRequestAuthorization { return isAuthorized }

        didRequestAuthorization = true
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound])
            return isAuthorized
        } catch {
            isAuthorized = false
            return false
        }
    }

    /// Posts a local notification for a domain event.
    /// This method is intentionally simple: it posts an immediate (near-instant) notification.
    func post(event: NotificationEvent) async {
        // If authorization is not requested yet, try requesting implicitly.
        // Coordinator/UI can also call requestPermissionsIfNeeded explicitly.
        if didRequestAuthorization == false {
            _ = await requestPermissionsIfNeeded()
        }
        guard isAuthorized else { return }

        let payload = makePayload(for: event)
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: payload.identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Intentionally ignore errors to avoid crashing the app.
            // Coordinator can add logging later if needed.
        }
    }

    // MARK: - Private

    private func makePayload(for event: NotificationEvent) -> (identifier: String, title: String, body: String) {
        switch event {
        case .timerStarted(let total):
            let text = formatDuration(total)
            return (
                identifier: "timer.started.\(UUID().uuidString)",
                title: "Timer started",
                body: "Total: \(text)"
            )

        case .timerFinished:
            return (
                identifier: "timer.finished.\(UUID().uuidString)",
                title: "Timer finished",
                body: "Day plan is complete."
            )

        case .segmentChanged(_, let to):
            return (
                identifier: "timer.segment.\(to.index).\(UUID().uuidString)",
                title: "Segment started",
                body: "\(to.title) (\(formatDuration(to.duration)))"
            )

        case .breakStarted(let to):
            return (
                identifier: "timer.break.\(to.index).\(UUID().uuidString)",
                title: "Time for a break",
                body: "\(to.title) (\(formatDuration(to.duration)))"
            )

        case .lunchStarted(let to):
            return (
                identifier: "timer.lunch.\(to.index).\(UUID().uuidString)",
                title: "Time for lunch",
                body: "\(to.title) (\(formatDuration(to.duration)))"
            )

        case .timerStopped:
            return (
                identifier: "timer.stopped.\(UUID().uuidString)",
                title: "Timer stopped",
                body: "The timer was stopped."
            )

        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
