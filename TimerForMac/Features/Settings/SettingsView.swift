//
//  SettingsView.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 29.01.2026.
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            NotificationSettingsView(viewModel: viewModel)
        }
        .padding(12)
        .frame(minWidth: 420, minHeight: 280)
    }
}
