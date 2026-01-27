//
//  TimerView.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 14.01.2026.
//

import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel
    @ObservedObject private var dayPlanViewModel: DayPlanViewModel

    private var targetMinutesBinding: Binding<Int> {
        Binding(
            get: { Int(viewModel.targetSeconds / 60) },
            set: { viewModel.setTargetMinutes($0) }
        )
    }

    init(viewModel: TimerViewModel, dayPlanViewModel: DayPlanViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.dayPlanViewModel = dayPlanViewModel
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            headerLeft
            headerRight
            centerContent
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 320)
    }

    // MARK: - Layout

    private var headerLeft: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titleText)
                .font(.title3)

            Text("Total: \(format(seconds: totalRemainingSeconds))")
                .font(.headline)
                .monospacedDigit()
                .opacity(0.8)
        }
        .padding(.top, 8)
        .padding(.leading, 8)
    }

    private var headerRight: some View {
        VStack {
            HStack {
                Spacer()
                NavigationLink("Day Plan") {
                    DayPlanView(viewModel: dayPlanViewModel)
                }
            }
            Spacer()
        }
        .padding(.top, 8)
        .padding(.trailing, 8)
    }

    private var centerContent: some View {
        VStack(spacing: 10) {
            Spacer()

            Text(activeDisplayTimeText)
                .font(.system(size: 80, weight: .semibold, design: .rounded))
                .monospacedDigit()

            Text(activeDisplayTitleText)
                .font(.title3)
                .opacity(0.85)

            controlsSection

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Start") { viewModel.onStart() }
                    .disabled(viewModel.snapshot.status == .running)

                Button("Pause") { viewModel.onPause() }
                    .disabled(viewModel.snapshot.status != .running)

                Button("Resume") { viewModel.onResume() }
                    .disabled(viewModel.snapshot.status != .paused)

                Button("Stop") { viewModel.onStop() }
                    .disabled(viewModel.snapshot.status == .idle)
            }

            if shouldShowManualMinutesControl {
                HStack(spacing: 8) {
                    Text("Minutes:")
                    Stepper(value: targetMinutesBinding, in: 1...240, step: 1) {
                        Text("\(targetMinutesBinding.wrappedValue)")
                            .frame(minWidth: 40, alignment: .leading)
                    }
                    .disabled(!viewModel.isEditingTargetAllowed)
                }
            }
        }
    }

    // MARK: - UI State

    private var titleText: String {
        switch viewModel.snapshot.status {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        case .finished: return "Finished"
        }
    }

    private var totalRemainingSeconds: Int {
        switch viewModel.snapshot.status {
        case .idle, .finished:
            return Int(viewModel.targetSeconds.rounded(.down))

        case .running, .paused:
            if let remaining = viewModel.snapshot.remaining {
                return Int(remaining.rounded(.down))
            }
            return 0
        }
    }

    private var activeSegmentState: ActiveSegmentState? {
        DayPlanProgressCalculator.activeSegment(
            plan: dayPlanViewModel.plan,
            totalRemaining: TimeInterval(totalRemainingSeconds)
        )
    }

    private var activeDisplayTimeText: String {
        if let state = activeSegmentState {
            return format(seconds: Int(state.remaining.rounded(.down)))
        }
        return format(seconds: totalRemainingSeconds)
    }

    private var activeDisplayTitleText: String {
        activeSegmentState?.title ?? "Total"
    }

    private var shouldShowManualMinutesControl: Bool {
        dayPlanViewModel.plan.totalDuration <= 0
    }

    // MARK: - Formatting

    private func format(seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
