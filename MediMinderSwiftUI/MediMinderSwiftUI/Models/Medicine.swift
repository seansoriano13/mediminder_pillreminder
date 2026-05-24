import Foundation
import FirebaseFirestore

struct Medicine: Identifiable {
    let id: String
    let userId: String
    let name: String
    let medicineType: String
    let dosage: String
    let amount: Int
    let form: String          // "Pill", "Liquid", "Injection"
    let instructions: String
    let scheduleType: String  // "interval" or "weekly"
    let intervalHours: Int
    let weeklyDays: [Int]     // 0 = Mon, 6 = Sun
    let scheduleTimes: [String] // HH:mm strings
    let createdAt: Date

    init(
        id: String = "",
        userId: String,
        name: String,
        medicineType: String,
        dosage: String,
        amount: Int,
        form: String,
        instructions: String = "",
        scheduleType: String,
        intervalHours: Int = 8,
        weeklyDays: [Int] = [],
        scheduleTimes: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.medicineType = medicineType
        self.dosage = dosage
        self.amount = amount
        self.form = form
        self.instructions = instructions
        self.scheduleType = scheduleType
        self.intervalHours = intervalHours
        self.weeklyDays = weeklyDays
        self.scheduleTimes = scheduleTimes
        self.createdAt = createdAt
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id = document.documentID
        self.userId = data["userId"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.medicineType = data["medicineType"] as? String ?? ""
        self.dosage = data["dosage"] as? String ?? ""
        self.amount = data["amount"] as? Int ?? 0
        self.form = data["form"] as? String ?? "Pill"
        self.instructions = data["instructions"] as? String ?? ""
        self.scheduleType = data["scheduleType"] as? String ?? "interval"
        self.intervalHours = data["intervalHours"] as? Int ?? 8
        self.weeklyDays = (data["weeklyDays"] as? [Int]) ?? []
        self.scheduleTimes = (data["scheduleTimes"] as? [String]) ?? []
        if let ts = data["createdAt"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = Date()
        }
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "medicineType": medicineType,
            "dosage": dosage,
            "amount": amount,
            "form": form,
            "instructions": instructions,
            "scheduleType": scheduleType,
            "intervalHours": intervalHours,
            "weeklyDays": weeklyDays,
            "scheduleTimes": scheduleTimes,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
