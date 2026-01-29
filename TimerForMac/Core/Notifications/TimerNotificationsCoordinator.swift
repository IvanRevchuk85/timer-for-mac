//
//  TimerNotificationsCoordinator.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 27.01.2026.
//

import Foundation

@MainActor
final class TimerNotificationsCoordinator {
    
    // MARK: - Dependencies
    
    private let timerEngine: TimerEngineProtocol
    private let notificationService: NotificationService
    private let planProvider: @MainActor () -> DayPlan
    private let settingsProvider: @MainActor () -> NotificationSettings
    
    // MARK: - State
    
    private var listenTask: Task<Void, Never>?
    private var previousStatus: TimerStatus = .idle
    private var previousSegment: ActiveSegmentState?
    
    // MARK: - Init
    
    init(
        timerEngine: TimerEngineProtocol,
        notificationService: NotificationService,
        planProvider: @escaping @MainActor () -> DayPlan,
        settingsProvider: @escaping @MainActor () -> NotificationSettings
    ) {
        self.timerEngine = timerEngine
        self.notificationService = notificationService
        self.planProvider = planProvider
        self.settingsProvider = settingsProvider
    }
    
    deinit {
        listenTask?.cancel()
    }
    
    // MARK: - Lifecycle
    
    func start() {
        guard listenTask == nil else { return }
        
        listenTask = Task { [weak self] in
            guard let self else { return }
            
            for await snapshot in timerEngine.stream {
                await self.process(snapshot: snapshot)
            }
        }
    }
    
    func stop() {
        listenTask?.cancel()
        listenTask = nil
        previousStatus = .idle
        previousSegment = nil
    }
    
    // MARK: - Processing
    
    private func process(snapshot: TimerSnapshot) async {
        let plan = planProvider()
        let settings = settingsProvider()
        
        let currentStatus = snapshot.status
        let totalDuration = resolveTotalDuration(snapshot: snapshot, plan: plan)
        
        let currentSegment = resolveActiveSegment(snapshot: snapshot, plan: plan, totalDuration: totalDuration)
        
        let events = NotificationEventDetector.detect(
            previousStatus: previousStatus,
            currentStatus: currentStatus,
            previousSegment: previousSegment,
            currentSegment: currentSegment,
            totalDuration: totalDuration,
            settings: settings
        )
        
        if events.isEmpty == false {
            #if DEBUG
            print(
                "STATUS:", previousStatus, "->", currentStatus,
                "SEG:", previousSegment?.index as Any, "->", currentSegment?.index as Any,
                "EVENTS:", events
            )
            #endif
            
            _ = await notificationService.requestPermissionsIfNeeded()
            for event in events {
                await notificationService.post(event: event)
            }
        }
        
        previousStatus = currentStatus
        previousSegment = currentSegment
    }
    
    // MARK: - Helpers
    
    private func resolveTotalDuration(snapshot: TimerSnapshot, plan: DayPlan) -> TimeInterval {
        if plan.totalDuration > 0 {
            return plan.totalDuration
        }
        
        if let target = snapshot.target, target > 0 {
            return target
        }
        
        return 0
    }
    
    private func resolveActiveSegment(
        snapshot: TimerSnapshot,
        plan: DayPlan,
        totalDuration: TimeInterval
    ) -> ActiveSegmentState? {
        guard plan.totalDuration > 0 else { return nil }
        guard totalDuration > 0 else { return nil }
        
        switch snapshot.status {
        case .running, .paused:
            guard let remaining = snapshot.remaining else { return nil }
            return DayPlanProgressCalculator.activeSegment(
                plan: plan,
                totalRemaining: remaining
            )
            
        case .idle, .finished:
            return nil
        }
    }
}
