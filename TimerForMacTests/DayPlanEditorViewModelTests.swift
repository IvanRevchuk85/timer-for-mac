//
//  DayPlanEditorViewModelTests.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 20.01.2026.
//

import XCTest
@testable import TimerForMac

final class DayPlanEditorViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockDayPlanRepository: DayPlanRepositoryProtocol {
        var stored: DayPlan
        var saveCalls = 0

        init(stored: DayPlan) {
            self.stored = stored
        }

        func load() -> DayPlan { stored }

        func save(_ plan: DayPlan) {
            saveCalls += 1
            stored = plan
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

        let saveCalls: Int = await MainActor.run {
            let vm = DayPlanEditorViewModel(repository: repo)
            vm.saveIfValid()
            return repo.saveCalls
        }

        XCTAssertEqual(saveCalls, 0)
    }

    func testSaveIfValid_Saves_WhenValid() async {
        let initial = DayPlan(segments: [
            PlanSegment(kind: .work, title: "Work", duration: 60)
        ])
        let repo = MockDayPlanRepository(stored: initial)

        let (saveCalls, totalDuration): (Int, TimeInterval) = await MainActor.run {
            let vm = DayPlanEditorViewModel(repository: repo)
            vm.updateMinutes(id: vm.segments[0].id, minutes: 25)
            vm.saveIfValid()
            return (repo.saveCalls, repo.stored.totalDuration)
        }

        XCTAssertEqual(saveCalls, 1)
        XCTAssertEqual(totalDuration, TimeInterval(25 * 60))
    }

    // MARK: - Calculator compatibility

    func testCalculatorPosition_WorksWithBuiltPlan() async {
        let repo = MockDayPlanRepository(stored: DayPlan(segments: []))
        let plan: DayPlan = await MainActor.run {
            let vm = DayPlanEditorViewModel(repository: repo)
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
