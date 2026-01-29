//
//  NotificationSettings.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation

struct NotificationSettings: Codable, Equatable, Sendable {
    
    // MARK: - Stored settings
    
    var isEnabled: Bool
    var notifyOnStart: Bool
    var notifyOnStop: Bool
    var notifyOnFinish: Bool
    var notifyOnSegmentChange: Bool
    var notifyOnBreak: Bool
    var notifyOnLunch: Bool
    
    // MARK: - Init
    
    init(
        isEnabled: Bool = false,
        notifyOnStart: Bool = true,
        notifyOnStop: Bool = true,
        notifyOnFinish: Bool = true,
        notifyOnSegmentChange: Bool = true,
        notifyOnBreak: Bool = true,
        notifyOnLunch: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.notifyOnStart = notifyOnStart
        self.notifyOnStop = notifyOnStop
        self.notifyOnFinish = notifyOnFinish
        self.notifyOnSegmentChange = notifyOnSegmentChange
        self.notifyOnBreak = notifyOnBreak
        self.notifyOnLunch = notifyOnLunch
    }
    
    // MARK: - Defaults
    
    static let `default` = NotificationSettings()
}
