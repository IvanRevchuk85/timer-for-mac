//
//  DayPlanRepository.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

// MARK: - DayPlanRepositoryProtocol
protocol DayPlanRepositoryProtocol {
    func load() -> DayPlan
    func save(_ plan: DayPlan)
}

// MARK: - DayPlanRepository
final class DayPlanRepository: DayPlanRepositoryProtocol {
    private let fileStore: JSONFileStoring
    private let fileURL: URL
    private let defaultPlanProvider: @Sendable () -> DayPlan

    init(
        fileStore: JSONFileStoring,
        fileURL: URL,
        defaultPlanProvider: @escaping @Sendable () -> DayPlan
    ) {
        self.fileStore = fileStore
        self.fileURL = fileURL
        self.defaultPlanProvider = defaultPlanProvider
    }

    func load() -> DayPlan {
        do {
            return try fileStore.read(DayPlan.self, from: fileURL)
        } catch {
            return defaultPlanProvider()
        }
    }

    func save(_ plan: DayPlan) {
        do {
            try fileStore.write(plan, to: fileURL)
        } catch {
            // Intentionally ignore I/O errors in MVP layer to avoid crashing.
        }
    }
}
