import SwiftUI
import Combine

struct MedicinesView: View {
    @EnvironmentObject var authService: AuthService

    @State private var medicines: [Medicine] = []
    @State private var isLoading = true
    @State private var cancellable: AnyCancellable?
    @State private var showAddMedicine = false
    @State private var editingMedicine: Medicine?
    @State private var medicineToDelete: Medicine?
    @State private var showDeleteConfirm = false

    private let firestoreService = FirestoreService()
    var userId: String { authService.currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if medicines.isEmpty {
                    EmptyMedicinesView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(medicines) { medicine in
                            MedicineRowView(medicine: medicine)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        medicineToDelete = medicine
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        editingMedicine = medicine
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Medicines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddMedicine = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showAddMedicine) {
            AddMedicineView(existingMedicine: nil)
                .environmentObject(authService)
        }
        .sheet(item: $editingMedicine) { medicine in
            AddMedicineView(existingMedicine: medicine)
                .environmentObject(authService)
        }
        .confirmationDialog(
            "Delete Medicine",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let m = medicineToDelete {
                    Task { try? await firestoreService.deleteMedicine(userId: userId, medicineId: m.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let m = medicineToDelete {
                Text("Remove \"\(m.name)\"? This cannot be undone.")
            }
        }
        .onAppear { startListening() }
        .onDisappear { cancellable?.cancel() }
    }

    private func startListening() {
        cancellable = firestoreService
            .getMedicinesStream(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { meds in
                medicines = meds
                isLoading = false
            }
    }
}

// MARK: - MedicineRowView

struct MedicineRowView: View {
    let medicine: Medicine
    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    var scheduleDescription: String {
        if medicine.scheduleType == "interval" {
            let start = medicine.scheduleTimes.first ?? "08:00"
            return "Every \(medicine.intervalHours)h starting \(start)"
        } else {
            let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let days = medicine.weeklyDays.sorted().map { dayNames[$0] }.joined(separator: ", ")
            return days.isEmpty ? "Weekly" : days
        }
    }

    var formIcon: String {
        switch medicine.form {
        case "Liquid":    return "drop.fill"
        case "Injection": return "syringe.fill"
        default:          return "pills.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(purple.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: formIcon)
                    .foregroundColor(purple)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name)
                    .font(.system(size: 16, weight: .semibold))
                Text("\(medicine.dosage) · \(medicine.medicineType)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(scheduleDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(medicine.amount)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(medicine.amount < 5 ? .red : .primary)
                Text("left")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - EmptyMedicinesView

struct EmptyMedicinesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 72))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No medicines yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Tap + to add your first medication.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }
}
