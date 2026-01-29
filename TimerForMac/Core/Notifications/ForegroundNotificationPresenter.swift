//
//  ForegroundNotificationPresenter.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 29.01.2026.
//

import Foundation
import UserNotifications

final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
