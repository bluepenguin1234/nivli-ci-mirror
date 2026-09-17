import FamilyControls
import Foundation
import SwiftUI

/// The picker row, plus the Screen Time permission when it has not been granted yet.
struct AppsThatWaitSection: View {
    @Environment(AppModel.self) private var model

    @State private var isPickerPresented = false
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        Section {
            Button {
                openPicker()
            } label: {
                HStack {
                    Text(summaryLine)
                        .foregroundStyle(Color.primary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .nivliRow()
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .onChange(of: isPickerPresented) { _, presented in
                guard !presented else { return }
                model.applySelection(selection)
            }

            if needsAuthorization {
                Button("Allow Screen Time") {
                    Task { await model.screenTime.request() }
                }
                .nivliRow()
            }
        } header: {
            Text("Apps that wait")
        } footer: {
            if let message = unavailableMessage {
                Text(message)
            }
        }
    }

    private var summaryLine: String {
        let summary = model.state.selectionSummary
        return "\(summary.apps) apps · \(summary.categories) categories · \(summary.sites) sites"
    }

    private var needsAuthorization: Bool {
        switch model.screenTime.status {
        case .approved, .unavailable: return false
        case .notDetermined, .denied: return true
        }
    }

    private var unavailableMessage: String? {
        switch model.screenTime.status {
        case .unavailable(let message): return message
        case .approved, .notDetermined, .denied: return nil
        }
    }

    private func openPicker() {
        selection = model.state.selection
        isPickerPresented = true
    }
}

/// Health is one way: Nivli can ask for it, but only iOS can take it back.
struct AppleHealthSection: View {
    @Environment(AppModel.self) private var model

    @State private var isConnecting = false

    var body: some View {
        Section {
            if model.health.isAvailable {
                if model.state.healthEnabled {
                    HStack {
                        Text("Connected")
                        Spacer(minLength: 8)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .nivliRow()
                } else {
                    Button("Connect Apple Health") { connect() }
                        .disabled(isConnecting)
                        .nivliRow()
                }
            }
        } header: {
            Text("Apple Health")
        } footer: {
            Text(footnote)
        }
    }

    private var footnote: String {
        guard model.health.isAvailable else {
            return "Apple Health isn't available on this device."
        }
        guard model.state.healthEnabled else {
            return "A workout from your Watch, or any app that writes to Health, unlocks your apps on its own."
        }
        return "To disconnect, open Health, then Sharing, then Apps, then Nivli."
    }

    private func connect() {
        isConnecting = true
        Task {
            _ = await model.connectHealth()
            isConnecting = false
        }
    }
}

/// Seven weekday toggles, and the one-off day off.
struct RestDaysSection: View {
    @Environment(AppModel.self) private var model

    @State private var isConfirmingDayOff = false

    var body: some View {
        Section {
            ForEach(0..<7, id: \.self) { index in
                Toggle(weekdayName(index), isOn: restDay(weekday: index + 1))
                    .nivliRow()
            }

            Button(model.isRestDayToday ? "Today is a rest day" : "Take today off") {
                isConfirmingDayOff = true
            }
            .foregroundStyle(.orange)
            .disabled(model.isRestDayToday)
            .nivliRow()
            .confirmationDialog(
                "Take today off?",
                isPresented: $isConfirmingDayOff,
                titleVisibility: .visible
            ) {
                Button("Take today off") { model.takeTodayOff() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Nothing is locked until tomorrow. Your streak is kept.")
            }
        } header: {
            Text("Rest days")
        } footer: {
            Text("On a rest day nothing is locked, and your streak is neither broken nor grown.")
        }
    }

    /// `Calendar.weekdaySymbols` always starts at Sunday, whatever the first day of the
    /// week is here, which is the numbering `weeklyRestDays` stores.
    private func weekdayName(_ index: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    private func restDay(weekday: Int) -> Binding<Bool> {
        Binding(
            get: { model.state.weeklyRestDays.contains(weekday) },
            set: { isOn in
                model.update { state in
                    if isOn {
                        state.weeklyRestDays.insert(weekday)
                    } else {
                        state.weeklyRestDays.remove(weekday)
                    }
                }
            }
        )
    }
}

/// The evening nudge. Both controls funnel through `setReminder`, which is the only thing
/// that asks iOS for permission and schedules or cancels the notification.
struct RemindersSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Section {
            Toggle("Evening reminder", isOn: reminderEnabled)
                .nivliRow()
            if model.state.reminderEnabled {
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    .nivliRow()
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A single nudge, and only if you have not moved yet that day.")
        }
    }

    private var reminderEnabled: Binding<Bool> {
        Binding(
            get: { model.state.reminderEnabled },
            set: { isOn in
                let minutes = model.state.reminderMinutesFromMidnight
                Task { _ = await model.setReminder(enabled: isOn, minutesFromMidnight: minutes) }
            }
        )
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: { ReminderClock.date(fromMinutesFromMidnight: model.state.reminderMinutesFromMidnight) },
            set: { newValue in
                let minutes = ReminderClock.minutesFromMidnight(newValue)
                let isOn = model.state.reminderEnabled
                Task { _ = await model.setReminder(enabled: isOn, minutesFromMidnight: minutes) }
            }
        )
    }
}

/// Minutes after midnight, and the `Date` the picker shows, both anchored to today.
enum ReminderClock {
    static func date(fromMinutesFromMidnight minutes: Int) -> Date {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: midnight) ?? midnight
    }

    static func minutesFromMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
