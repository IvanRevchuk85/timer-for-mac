//
//  DayPlanEditorView.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 20.01.2026.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct DayPlanEditorView: View {
    @ObservedObject var viewModel: DayPlanEditorViewModel
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isReordering = false
    @State private var draggedSegmentID: UUID?

    private let maxMinutesPerSegment = 12 * 60

    var body: some View {
        NavigationStack {
            List {
                validationSection
                templateSection
                segmentsSection
            }
            .navigationTitle("Edit Day Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    addMenu
                }

                ToolbarItem(placement: .automatic) {
                    Button(isReordering ? "Done" : "Reorder") {
                        withAnimation { isReordering.toggle() }
                    }
                    .disabled(viewModel.segments.count < 2)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSaveTapped() }
                        .disabled(!viewModel.isValid)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 520)
    }

    @ViewBuilder
    private var validationSection: some View {
        if !viewModel.errors.isEmpty {
            Section {
                ForEach(viewModel.errors, id: \.self) { error in
                    Text(errorText(error))
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var templateSection: some View {
        Section {
            Button("Working day template") {
                viewModel.applyWorkingDayTemplate()
            }
        }
    }

    private var segmentsSection: some View {
        Section("Segments") {
            if viewModel.segments.isEmpty {
                Text("Use Add to create segments.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.segments) { segment in
                    segmentRow(segment)
                        .onDrag {
                            draggedSegmentID = segment.id
                            return NSItemProvider(object: segment.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: SegmentDropDelegate(
                                target: segment,
                                draggedID: $draggedSegmentID,
                                isEnabled: isReordering,
                                segmentsProvider: { viewModel.segments },
                                move: moveByIDs
                            )
                        )
                }
                .onDelete(perform: deleteSegments)
            }
        }
    }

    private func segmentRow(_ segment: DayPlanEditorViewModel.DraftSegment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(
                "Type",
                selection: Binding(
                    get: { segment.kind },
                    set: { viewModel.updateKind(id: segment.id, kind: $0) }
                )
            ) {
                Text("Work").tag(SegmentKind.work)
                Text("Break").tag(SegmentKind.breakTime)
                Text("Lunch").tag(SegmentKind.lunch)
                Text("Custom").tag(SegmentKind.custom)
            }
            .pickerStyle(.segmented)

            TextField(
                "Title",
                text: Binding(
                    get: { segment.title },
                    set: { viewModel.updateTitle(id: segment.id, title: $0) }
                )
            )
            .textFieldStyle(.roundedBorder)

            Stepper(
                value: Binding(
                    get: { segment.minutes },
                    set: { viewModel.updateMinutes(id: segment.id, minutes: $0) }
                ),
                in: 0...maxMinutesPerSegment,
                step: 1
            ) {
                Text("Duration: \(segment.minutes) min")
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var addMenu: some View {
        Menu {
            Button("Add work") { viewModel.addSegment(kind: .work) }
            Button("Add break") { viewModel.addSegment(kind: .breakTime) }
            Button("Add lunch") { viewModel.addSegment(kind: .lunch) }
            Button("Add custom") { viewModel.addSegment(kind: .custom) }
        } label: {
            Label("Add", systemImage: "plus")
        }
    }

    private func deleteSegments(at offsets: IndexSet) {
        viewModel.removeSegments(at: offsets)
    }

    private func onSaveTapped() {
        viewModel.saveIfValid { didSave in
            guard didSave else { return }
            onSaved()
            dismiss()
        }
    }

    private func errorText(_ error: DayPlanEditorViewModel.ValidationError) -> String {
        switch error {
        case .emptyPlan: return "Plan cannot be empty."
        case .totalDurationIsZero: return "Total duration cannot be 0."
        }
    }

    private func moveByIDs(sourceID: UUID, targetID: UUID) {
        guard sourceID != targetID else { return }

        let segments = viewModel.segments
        guard
            let fromIndex = segments.firstIndex(where: { $0.id == sourceID }),
            let toIndex = segments.firstIndex(where: { $0.id == targetID })
        else { return }

        viewModel.moveSegments(from: IndexSet(integer: fromIndex), to: toIndex > fromIndex ? toIndex + 1 : toIndex)
    }
}

private struct SegmentDropDelegate: DropDelegate {
    let target: DayPlanEditorViewModel.DraftSegment
    @Binding var draggedID: UUID?

    let isEnabled: Bool
    let segmentsProvider: () -> [DayPlanEditorViewModel.DraftSegment]
    let move: (_ sourceID: UUID, _ targetID: UUID) -> Void

    func validateDrop(info: DropInfo) -> Bool { isEnabled }

    func dropEntered(info: DropInfo) {
        guard isEnabled else { return }
        guard let draggedID, draggedID != target.id else { return }

        let segments = segmentsProvider()
        guard segments.contains(where: { $0.id == draggedID }) else { return }

        move(draggedID, target.id)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        return true
    }
}
