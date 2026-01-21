//
//  DayPlanView.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 19.01.2026.
//

import SwiftUI
import Combine

struct DayPlanView: View {
    @ObservedObject var viewModel: DayPlanViewModel

    @State private var editorSession: EditorSession?

    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        content
            .navigationTitle("Day Plan")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(viewModel.plan.segments.isEmpty ? "Create" : "Edit") {
                        openEditor()
                    }
                }
            }
            .task {
                viewModel.refresh()
                viewModel.updatePosition()
            }
            .onReceive(ticker) { _ in
                guard editorSession == nil else { return }
                viewModel.updatePosition()
            }
            .sheet(item: $editorSession, onDismiss: { editorSession = nil }) { session in
                DayPlanEditorView(
                    viewModel: session.viewModel,
                    onSaved: {
                        viewModel.refresh()
                        viewModel.updatePosition()
                    }
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.plan.segments.isEmpty {
            ContentUnavailableView(
                "No plan yet",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("Create a plan to see the timeline.")
            )
        } else {
            List {
                ForEach(Array(viewModel.plan.segments.enumerated()), id: \.element.id) { index, segment in
                    segmentRow(index: index, segment: segment)
                }
            }
        }
    }

    private func openEditor() {
        guard editorSession == nil else { return }
        editorSession = EditorSession(viewModel: viewModel.makeEditorViewModel())
    }

    private func segmentRow(index: Int, segment: PlanSegment) -> some View {
        let isCurrent = viewModel.currentPosition?.segmentIndex == index
        let position = isCurrent ? viewModel.currentPosition : nil

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.title)
                        .font(.headline)

                    Text(displayKind(segment.kind))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatDuration(segment.duration))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                if isCurrent {
                    Text("Now")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
            }

            if let position, segment.duration > 0 {
                ProgressView(value: position.elapsedInSegment, total: segment.duration)

                HStack {
                    Text("Elapsed: \(formatDuration(position.elapsedInSegment))")
                    Spacer()
                    Text("Remaining: \(formatDuration(position.remainingInSegment))")
                }
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(isCurrent ? Color.accentColor.opacity(0.15) : Color.clear)
        .accessibilityElement(children: .combine)
    }

    private func displayKind(_ kind: SegmentKind) -> String {
        switch kind {
        case .work: return "Work"
        case .breakTime: return "Break"
        case .lunch: return "Lunch"
        case .custom: return "Custom"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let safe = max(0, seconds)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        formatter.allowedUnits = safe >= 3600 ? [.hour, .minute, .second] : [.minute, .second]

        return formatter.string(from: safe) ?? "0:00"
    }
}

private struct EditorSession: Identifiable {
    let id = UUID()
    let viewModel: DayPlanEditorViewModel
}
