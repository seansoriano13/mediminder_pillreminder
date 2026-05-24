import SwiftUI

// MARK: - Constants

private let medicineTypes = [
    "Antibiotic", "Antiviral", "Analgesic", "Antihypertensive",
    "Antihistamine", "Supplement", "Vitamin", "Other"
]
private let medicineForms = ["Pill", "Liquid", "Injection"]
private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

// MARK: - AddMedicineView

struct AddMedicineView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    let existingMedicine: Medicine?

    // Form state
    @State private var name = ""
    @State private var dosage = ""
    @State private var amount = ""
    @State private var instructions = ""
    @State private var selectedType = medicineTypes[0]
    @State private var selectedForm = "Pill"
    @State private var scheduleType = "interval"
    @State private var intervalHours = 8
    @State private var selectedWeeklyDays: Set<Int> = []
    @State private var scheduleTimes: [Date] = [
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    ]
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showError = false

    private let firestoreService = FirestoreService()
    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    var isEditing: Bool { existingMedicine != nil }
    var userId: String { authService.currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            Form {
                // ── Basic Information ─────────────────────────────────────
                Section("Basic Information") {
                    TextField("Medicine Name *", text: $name)

                    Picker("Type", selection: $selectedType) {
                        ForEach(medicineTypes, id: \.self) { Text($0) }
                    }

                    TextField("Dosage * (e.g. 500mg)", text: $dosage)

                    TextField("Amount * (e.g. 30)", text: $amount)
                        .keyboardType(.numberPad)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Form")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Form", selection: $selectedForm) {
                            ForEach(medicineForms, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // ── Instructions ──────────────────────────────────────────
                Section("Instructions (Optional)") {
                    TextField(
                        "e.g. Take with food, avoid sunlight…",
                        text: $instructions,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                // ── Schedule Type ─────────────────────────────────────────
                Section("Schedule") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Schedule Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Schedule Type", selection: $scheduleType) {
                            Text("Every X Hours").tag("interval")
                            Text("Days of Week").tag("weekly")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // ── Interval Panel ────────────────────────────────────────
                if scheduleType == "interval" {
                    Section("Interval") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Repeat every \(intervalHours) hour\(intervalHours == 1 ? "" : "s")")
                                .font(.subheadline)
                            Slider(
                                value: Binding(
                                    get: { Double(intervalHours) },
                                    set: { intervalHours = Int($0) }
                                ),
                                in: 1...24,
                                step: 1
                            )
                            .tint(purple)
                        }

                        DatePicker(
                            "Start Time",
                            selection: $scheduleTimes[0],
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // ── Weekly Panel ──────────────────────────────────────────
                if scheduleType == "weekly" {
                    Section("Days") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                            ForEach(0..<7, id: \.self) { index in
                                let isSelected = selectedWeeklyDays.contains(index)
                                Button(action: {
                                    if isSelected { selectedWeeklyDays.remove(index) }
                                    else { selectedWeeklyDays.insert(index) }
                                }) {
                                    Text(dayNames[index])
                                        .font(.caption2)
                                        .fontWeight(isSelected ? .bold : .regular)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? purple : Color(.systemGray5))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Times") {
                        ForEach(scheduleTimes.indices, id: \.self) { i in
                            HStack {
                                DatePicker(
                                    "Time \(i + 1)",
                                    selection: $scheduleTimes[i],
                                    displayedComponents: .hourAndMinute
                                )
                                if scheduleTimes.count > 1 {
                                    Button(action: { scheduleTimes.remove(at: i) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button(action: {
                            let base = Calendar.current.date(
                                bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
                            scheduleTimes.append(base)
                        }) {
                            Label("Add another time", systemImage: "plus.circle")
                                .foregroundColor(purple)
                        }
                    }
                }

                // ── Save Button ───────────────────────────────────────────
                Section {
                    Button(action: save) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSaving ? purple.opacity(0.6) : purple)
                                .frame(height: 44)
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text(isEditing ? "Save Changes" : "Add Medicine")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isSaving)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle(isEditing ? "Edit Medicine" : "Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { prefillIfEditing() }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Helpers

    private func prefillIfEditing() {
        guard let m = existingMedicine else { return }
        name = m.name
        dosage = m.dosage
        amount = "\(m.amount)"
        instructions = m.instructions
        selectedType = m.medicineType
        selectedForm = m.form
        scheduleType = m.scheduleType
        intervalHours = m.intervalHours
        selectedWeeklyDays = Set(m.weeklyDays)

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let parsed = m.scheduleTimes.compactMap { fmt.date(from: $0) }
        if !parsed.isEmpty {
            scheduleTimes = parsed
        }
    }

    private func buildTimeStrings() -> [String] {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return scheduleTimes.map { fmt.string(from: $0) }
    }

    private func save() {
        let trimName = name.trimmingCharacters(in: .whitespaces)
        guard !trimName.isEmpty else {
            errorMessage = "Please enter a medicine name."
            showError = true
            return
        }
        let trimDosage = dosage.trimmingCharacters(in: .whitespaces)
        guard !trimDosage.isEmpty else {
            errorMessage = "Please enter a dosage."
            showError = true
            return
        }
        guard let amountInt = Int(amount.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Amount must be a whole number."
            showError = true
            return
        }
        if scheduleType == "weekly" && selectedWeeklyDays.isEmpty {
            errorMessage = "Please select at least one day."
            showError = true
            return
        }

        isSaving = true

        let medicine = Medicine(
            id: isEditing ? (existingMedicine?.id ?? "") : "",
            userId: userId,
            name: trimName,
            medicineType: selectedType,
            dosage: trimDosage,
            amount: amountInt,
            form: selectedForm,
            instructions: instructions.trimmingCharacters(in: .whitespaces),
            scheduleType: scheduleType,
            intervalHours: intervalHours,
            weeklyDays: Array(selectedWeeklyDays).sorted(),
            scheduleTimes: buildTimeStrings(),
            createdAt: isEditing ? (existingMedicine?.createdAt ?? Date()) : Date()
        )

        Task {
            do {
                if isEditing {
                    try await firestoreService.updateMedicine(userId: userId, medicine: medicine)
                } else {
                    try await firestoreService.addMedicine(userId: userId, medicine: medicine)
                }
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    showError = true
                    isSaving = false
                }
            }
        }
    }
}
