//
//  DayPlanRepository.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

protocol DayPlanRepositoryProtocol: AnyObject {
    func load(completion: @escaping (DayPlan) -> Void)
    func save(_ plan: DayPlan, completion: @escaping (Result<Void, Error>) -> Void)
}

final class DayPlanRepository: DayPlanRepositoryProtocol {
    private let fileStore: JSONFileStoring
    private let fileURL: URL
    private let defaultPlanProvider: @Sendable () -> DayPlan
    private let ioQueue = DispatchQueue(label: "com.timerformac.dayplan.repo.io", qos: .userInitiated)

    init(
        fileStore: JSONFileStoring,
        fileURL: URL,
        defaultPlanProvider: @escaping @Sendable () -> DayPlan
    ) {
        self.fileStore = fileStore
        self.fileURL = fileURL
        self.defaultPlanProvider = defaultPlanProvider
    }

    func load(completion: @escaping (DayPlan) -> Void) {
        let fileStore = fileStore
        let fileURL = fileURL
        let defaultPlanProvider = defaultPlanProvider

        ioQueue.async {
            let plan: DayPlan
            do {
                plan = try fileStore.read(DayPlan.self, from: fileURL)
            } catch {
                plan = defaultPlanProvider()
            }

            DispatchQueue.main.async {
                completion(plan)
            }
        }
    }

    func save(_ plan: DayPlan, completion: @escaping (Result<Void, Error>) -> Void) {
        let fileStore = fileStore
        let fileURL = fileURL

        ioQueue.async {
            do {
                try fileStore.write(plan, to: fileURL)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
