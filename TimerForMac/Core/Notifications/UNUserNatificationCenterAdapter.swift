//
//  UNUserNotificationCenterAdapter.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation
import UserNotifications

struct UNUserNotificationCenterAdapter: NotificationCenterLike {

    // MARK: - Dependencies

    private let center: UNUserNotificationCenter

    // MARK: - Init

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: - NotificationCenterLike

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }
}
