import SwiftUI
import Combine

// MARK: - Dose Status

enum DoseStatus {
    case upcoming, overdue, taken
}

// MARK: - Dose Item (display model)

struct DoseItem: Identifiable {
    let id = UUID()
    let medicine: Medicine
    let scheduledTime: String
    let status: DoseStatus
}

// MARK: - TodayView

struct TodayView: View {
    @EnvironmentObject var authService: AuthService

    @State private var medicines: [Medicine] = []
    @State private var todayRecords: [DoseRecord] = []
    @State private var isLoading = true
    @State private var cancellable: AnyCancellable?
    @State private var currentTime = Date()  // Updated every minute to trigger redraws
    @State private var timer: Timer?

    private let firestoreService = FirestoreService()
    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    // MARK: Helpers

    var userId: String { authService.currentUser?.uid ?? "" }

    var todayDateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    /// Mirrors Flutter's _buildDoseItems() logic exactly.
    var doseItems: [DoseItem] {
        let now = currentTime  // SwiftUI tracks this @State dependency → redraws every minute
        var items: [DoseItem] = []
        for medicine in medicines {
            for time in computeTodayTimes(medicine: medicine) {
                let status = computeStatus(medicine: medicine, scheduledTime: time, records: todayRecords, now: now)
                items.append(DoseItem(medicine: medicine, scheduledTime: time, status: status))
            }
        }
        // Sort: overdue first → upcoming by time → taken last
        items.sort { a, b in
            if a.status == .overdue && b.status != .overdue { return true }
            if a.status != .overdue && b.status == .overdue { return false }
            if a.status == .taken && b.status != .taken { return false }
            if a.status != .taken && b.status == .taken { return true }
            return a.scheduledTime < b.scheduledTime
        }
        return items
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if doseItems.isEmpty {
                    EmptyTodayView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(doseItems) { item in
                            DoseRowView(
                                item: item,
                                onMarkTaken: { Task { await markAsTaken(item) } },
                                onDismiss:   { Task { await dismissDose(item) } }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Today's Doses")
        }
        .onAppear {
            startListening()
            startTimer()
        }
        .onDisappear {
            cancellable?.cancel()
            timer?.invalidate()
        }
    }

    // MARK: - Data

    private func startListening() {
        cancellable = firestoreService
            .getMedicinesStream(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }) { meds in
                medicines = meds
                isLoading = false
                Task { await loadTodayRecords() }
            }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func loadTodayRecords() async {
        do {
            let records = try await firestoreService.getDoseRecordsForDate(
                userId: userId, date: todayDateString)
            await MainActor.run { todayRecords = records }
        } catch {}
    }

    private func markAsTaken(_ item: DoseItem) async {
        let record = DoseRecord(
            medicineId: item.medicine.id,
            scheduledDate: todayDateString,
            scheduledTime: item.scheduledTime,
            status: "taken"
        )
        try? await firestoreService.recordDose(userId: userId, record: record)
        try? await firestoreService.decrementAmount(
            userId: userId, medicineId: item.medicine.id, currentAmount: item.medicine.amount)
        await loadTodayRecords()
    }

    private func dismissDose(_ item: DoseItem) async {
        let record = DoseRecord(
            medicineId: item.medicine.id,
            scheduledDate: todayDateString,
            scheduledTime: item.scheduledTime,
            status: "dismissed"
        )
        try? await firestoreService.recordDose(userId: userId, record: record)
        await loadTodayRecords()
    }

    // MARK: - Schedule Logic (mirrors Flutter exactly)

    /// Computes all scheduled dose times for a medicine on today's date.
    private func computeTodayTimes(medicine: Medicine) -> [String] {
        var times: [String] = []
        let calendar = Calendar.current
        let weekdayRaw = calendar.component(.weekday, from: Date())
        // Calendar.weekday: 1=Sun…7=Sat → convert to 0=Mon…6=Sun
        let todayIndex = (weekdayRaw + 5) % 7

        if medicine.scheduleType == "interval" {
            guard let startStr = medicine.scheduleTimes.first else { return [] }
            let parts = startStr.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return [] }
            var hour = parts[0]
            let minute = parts[1]
            while hour < 24 {
                times.append(String(format: "%02d:%02d", hour, minute))
                hour += medicine.intervalHours
            }
        } else {
            if medicine.weeklyDays.contains(todayIndex) {
                times = medicine.scheduleTimes
            }
        }
        return times
    }

    private func computeStatus(medicine: Medicine, scheduledTime: String, records: [DoseRecord], now: Date) -> DoseStatus {
        // Check for taken or dismissed record
        for record in records {
            if record.medicineId == medicine.id && record.scheduledTime == scheduledTime {
                return .taken  // Flutter treats both "taken" and "dismissed" as .taken for sorting
            }
        }
        // Check if the scheduled time has passed
        let parts = scheduledTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return .upcoming }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: now)
        comps.hour = parts[0]
        comps.minute = parts[1]
        comps.second = 0
        if let scheduled = Calendar.current.date(from: comps), scheduled < now {
            return .overdue
        }
        return .upcoming
    }
}

// MARK: - DoseRowView

struct DoseRowView: View {
    let item: DoseItem
    let onMarkTaken: () -> Void
    let onDismiss: () -> Void

    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    var statusColor: Color {
        switch item.status {
        case .upcoming: return .blue
        case .overdue:  return .red
        case .taken:    return .green
        }
    }

    var statusLabel: String {
        switch item.status {
        case .upcoming: return "Upcoming"
        case .overdue:  return "Overdue"
        case .taken:    return "Taken"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.medicine.name)
                        .font(.system(size: 17, weight: .semibold))
                    Text("\(item.medicine.dosage) · \(item.scheduledTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(statusLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(20)
            }

            if item.status != .taken {
                HStack(spacing: 10) {
                    Button(action: onMarkTaken) {
                        Label("Take", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(purple)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDismiss) {
                        Label("Dismiss", systemImage: "xmark.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - EmptyTodayView

struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary.opacity(0.5))
            Text("All clear for today!")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("No medications scheduled.\nAdd one in My Medicines.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }
}
