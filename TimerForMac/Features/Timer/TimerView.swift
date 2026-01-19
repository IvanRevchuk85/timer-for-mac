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

    @State private var targetMinutes: Int = 25

    init(viewModel: TimerViewModel, dayPlanViewModel: DayPlanViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.dayPlanViewModel = dayPlanViewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(titleText)
                    .font(.title2)

                Spacer()

                NavigationLink("Day Plan") {
                    DayPlanView(viewModel: dayPlanViewModel)
                }
            }

            Text(timeText)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .monospacedDigit()

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

            HStack(spacing: 8) {
                Text("Minutes:")
                Stepper(value: $targetMinutes, in: 1...240, step: 1) {
                    Text("\(targetMinutes)")
                        .frame(minWidth: 40, alignment: .leading)
                }
                .disabled(!viewModel.isEditingTargetAllowed)
                .onChange(of: targetMinutes) { _, newValue in
                    viewModel.setTargetMinutes(newValue)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 260)
        .onAppear {
            targetMinutes = Int(viewModel.targetSeconds / 60)
        }
    }

    private var titleText: String {
        switch viewModel.snapshot.status {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        case .finished: return "Finished"
        }
    }

    private var timeText: String {
        let seconds: Int
        switch viewModel.snapshot.status {
        case .idle, .finished:
            seconds = Int(viewModel.targetSeconds.rounded(.down))
        case .running, .paused:
            let value = viewModel.snapshot.remaining ?? viewModel.snapshot.elapsed
            seconds = Int(value.rounded(.down))
        }
        return format(seconds: seconds)
    }

    private func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
