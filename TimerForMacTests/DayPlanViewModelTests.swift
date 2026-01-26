//
//  DayPlanViewModelTests.swift
//  TimerForMacTests
//
//  Created by Ivan Revchuk on 19.01.2026.
//

import XCTest
@testable import TimerForMac

final class DayPlanViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockDayPlanRepository: DayPlanRepositoryProtocol {
        var planToLoad: DayPlan
        private(set) var loadCalls = 0
        private(set) var savedPlans: [DayPlan] = []

        init(planToLoad: DayPlan) {
            self.planToLoad = planToLoad
        }

        func load(completion: @escaping (DayPlan) -> Void) {
            loadCalls += 1
            completion(planToLoad)
        }

        func save(_ plan: DayPlan, completion: @escaping (Result<Void, Error>) -> Void) {
            savedPlans.append(plan)
            planToLoad = plan
            completion(.success(()))
        }
    }

    private final class ElapsedBox {
        var value: TimeInterval
        init(_ value: TimeInterval) { self.value = value }
    }

    // MARK: - Tests

    @MainActor
    func testInit_LoadsPlanOnce_AndComputesPosition() throws {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
            PlanSegment(kind: .breakTime, title: "Break", duration: 30),
        ])
        let repo = MockDayPlanRepository(planToLoad: plan)

        let elapsed = ElapsedBox(70) // 60 sec work + 10 sec into break
        let vm = DayPlanViewModel(repository: repo, elapsedProvider: { elapsed.value })

        XCTAssertEqual(repo.loadCalls, 1)
        XCTAssertEqual(vm.plan, plan)

        let position = try XCTUnwrap(vm.currentPosition)
        XCTAssertEqual(position.segmentIndex, 1)
        XCTAssertEqual(position.segment.title, "Break")
        XCTAssertEqual(position.elapsedInSegment, 10, accuracy: 0.0001)
        XCTAssertEqual(position.remainingInSegment, 20, accuracy: 0.0001)
    }

    @MainActor
    func testUpdatePosition_RecalculatesForSamePlan() throws {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
            PlanSegment(kind: .breakTime, title: "Break", duration: 30),
        ])
        let repo = MockDayPlanRepository(planToLoad: plan)

        let elapsed = ElapsedBox(0)
        let vm = DayPlanViewModel(repository: repo, elapsedProvider: { elapsed.value })

        let initial = try XCTUnwrap(vm.currentPosition)
        XCTAssertEqual(initial.segmentIndex, 0)

        elapsed.value = 65
        vm.updatePosition()

        let updated = try XCTUnwrap(vm.currentPosition)
        XCTAssertEqual(updated.segmentIndex, 1)
        XCTAssertEqual(updated.elapsedInSegment, 5, accuracy: 0.0001)
        XCTAssertEqual(updated.remainingInSegment, 25, accuracy: 0.0001)
    }

    @MainActor
    func testRefresh_ReloadsPlan_AndRecomputesPosition() throws {
        let planA = DayPlan(segments: [
            PlanSegment(kind: .work, title: "A", duration: 100),
        ])
        let planB = DayPlan(segments: [
            PlanSegment(kind: .lunch, title: "B", duration: 50),
            PlanSegment(kind: .custom, title: "C", duration: 50),
        ])

        let repo = MockDayPlanRepository(planToLoad: planA)
        let elapsed = ElapsedBox(60)
        let vm = DayPlanViewModel(repository: repo, elapsedProvider: { elapsed.value })

        XCTAssertEqual(vm.plan, planA)
        XCTAssertEqual(try XCTUnwrap(vm.currentPosition).segment.title, "A")

        repo.planToLoad = planB
        elapsed.value = 10
        vm.refresh()

        XCTAssertEqual(repo.loadCalls, 2)
        XCTAssertEqual(vm.plan, planB)
        XCTAssertEqual(try XCTUnwrap(vm.currentPosition).segment.title, "B")
    }

    @MainActor
    func testEmptyPlan_PositionIsNil() {
        let repo = MockDayPlanRepository(planToLoad: DayPlan(segments: []))
        let vm = DayPlanViewModel(repository: repo, elapsedProvider: { 0 })
        XCTAssertNil(vm.currentPosition)
    }

    @MainActor
    func testNegativeElapsed_IsClampedToZero() throws {
        let plan = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60),
        ])
        let repo = MockDayPlanRepository(planToLoad: plan)

        let vm = DayPlanViewModel(repository: repo, elapsedProvider: { -999 })

        let position = try XCTUnwrap(vm.currentPosition)
        XCTAssertEqual(position.segmentIndex, 0)
        XCTAssertEqual(position.elapsedInSegment, 0, accuracy: 0.0001)
        XCTAssertEqual(position.remainingInSegment, 60, accuracy: 0.0001)
    }
}
