import Foundation
import FirebaseFirestore

struct DoseRecord: Identifiable {
    let id: String
    let medicineId: String
    let scheduledDate: String  // YYYY-MM-DD
    let scheduledTime: String  // HH:mm
    let status: String         // "taken" or "dismissed"
    let recordedAt: Date

    init(
        id: String = "",
        medicineId: String,
        scheduledDate: String,
        scheduledTime: String,
        status: String,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.medicineId = medicineId
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.status = status
        self.recordedAt = recordedAt
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        self.id = document.documentID
        self.medicineId = data["medicineId"] as? String ?? ""
        self.scheduledDate = data["scheduledDate"] as? String ?? ""
        self.scheduledTime = data["scheduledTime"] as? String ?? ""
        self.status = data["status"] as? String ?? "taken"
        if let ts = data["recordedAt"] as? Timestamp {
            self.recordedAt = ts.dateValue()
        } else {
            self.recordedAt = Date()
        }
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "medicineId": medicineId,
            "scheduledDate": scheduledDate,
            "scheduledTime": scheduledTime,
            "status": status,
            "recordedAt": Timestamp(date: recordedAt)
        ]
    }
}
