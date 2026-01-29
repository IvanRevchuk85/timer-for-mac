//
//  NotificationCenterLike.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation
import UserNotifications

protocol NotificationCenterLike {

    /// Requests notification authorization.
    /// - Returns: `true` if authorization was granted, otherwise `false`.
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool

    /// Adds a notification request to the system.
    func add(_ request: UNNotificationRequest) async throws
}
