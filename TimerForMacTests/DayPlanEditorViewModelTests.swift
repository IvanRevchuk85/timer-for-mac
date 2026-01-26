//
//  DayPlanEditorViewModelTests.swift
//  TimerForMacTests
//
//  Created by Ivan Revchuk on 20.01.2026.
//

import XCTest
@testable import TimerForMac

final class DayPlanEditorViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockDayPlanRepository: DayPlanRepositoryProtocol {
        var stored: DayPlan
        private(set) var loadCalls = 0
        private(set) var saveCalls = 0

        init(stored: DayPlan) {
            self.stored = stored
        }

        func load(completion: @escaping (DayPlan) -> Void) {
            loadCalls += 1
            completion(stored)
        }

        func save(_ plan: DayPlan, completion: @escaping (Result<Void, Error>) -> Void) {
            saveCalls += 1
            stored = plan
            completion(.success(()))
        }
    }

    // MARK: - Validation

    func testValidation_EmptyPlan_Fails() {
        let errors = DayPlanEditorViewModel.validate(segments: [])
        XCTAssertEqual(errors, [.emptyPlan])
    }

    func testValidation_AllZeroMinutes_Fails() {
        let segments: [DayPlanEditorViewModel.DraftSegment] = [
            .init(kind: .work, title: "Work", minutes: 0),
            .init(kind: .breakTime, title: "Break", minutes: 0)
        ]

        let errors = DayPlanEditorViewModel.validate(segments: segments)
        XCTAssertTrue(errors.contains(.totalDurationIsZero))
    }

    func testSaveIfValid_DoesNotSave_WhenInvalid() async {
        let repo = MockDayPlanRepository(stored: DayPlan(segments: []))

        let exp = expectation(description: "Completion called for invalid save")

        let (result, saveCalls): (Bool, Int) = await MainActor.run {
            let vm = DayPlanEditorViewModel(plan: DayPlan(segments: []), repository: repo)

            let started = vm.saveIfValid { success in
                XCTAssertFalse(success)
                exp.fulfill()
            }

            return (started, repo.saveCalls)
        }

        XCTAssertFalse(result)
        XCTAssertEqual(saveCalls, 0)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func testSaveIfValid_Saves_WhenValid() async {
        let initial = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60) // 60 sec -> 1 minute in editor
        ])
        let repo = MockDayPlanRepository(stored: initial)

        let exp = expectation(description: "Completion called for valid save")

        await MainActor.run {
            let vm = DayPlanEditorViewModel(plan: initial, repository: repo)
            vm.updateMinutes(id: vm.segments[0].id, minutes: 25)

            let started = vm.saveIfValid { success in
                XCTAssertTrue(success)
                exp.fulfill()
            }

            XCTAssertTrue(started)
        }

        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertEqual(repo.saveCalls, 1)
        XCTAssertEqual(repo.stored.totalDuration, TimeInterval(25 * 60))
    }

    // MARK: - Calculator compatibility

    func testCalculatorPosition_WorksWithBuiltPlan() async {
        let repo = MockDayPlanRepository(stored: DayPlan(segments: []))

        let plan: DayPlan = await MainActor.run {
            let vm = DayPlanEditorViewModel(plan: DayPlan(segments: []), repository: repo)
            vm.addSegment(kind: .work)
            vm.addSegment(kind: .breakTime)
            vm.updateMinutes(id: vm.segments[0].id, minutes: 20)
            vm.updateMinutes(id: vm.segments[1].id, minutes: 5)
            return vm.buildPlan()
        }

        let pos0 = ScheduleCalculator.position(in: plan, elapsed: 0)
        XCTAssertEqual(pos0?.segmentIndex, 0)

        let pos1 = ScheduleCalculator.position(in: plan, elapsed: TimeInterval(20 * 60))
        XCTAssertEqual(pos1?.segmentIndex, 1)

        let finished = ScheduleCalculator.isFinished(plan: plan, elapsed: TimeInterval(25 * 60))
        XCTAssertTrue(finished)
    }
}
