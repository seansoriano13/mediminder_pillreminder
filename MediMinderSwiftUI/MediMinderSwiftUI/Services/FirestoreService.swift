import Foundation
import FirebaseFirestore
import Combine

/// Wraps all Firestore read/write operations.
/// Mirrors the Flutter firestore_service.dart exactly.
class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Collection References

    private func medicinesRef(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("medicines")
    }

    private func doseRecordsRef(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("doseRecords")
    }

    // MARK: - Medicines

    /// Returns a Combine publisher that streams real-time medicine updates.
    /// The Firestore listener is removed automatically when the publisher is cancelled.
    func getMedicinesStream(userId: String) -> AnyPublisher<[Medicine], Error> {
        let subject = PassthroughSubject<[Medicine], Error>()

        let listener = medicinesRef(userId: userId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                let medicines = snapshot?.documents.compactMap { Medicine(document: $0) } ?? []
                subject.send(medicines)
            }

        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func addMedicine(userId: String, medicine: Medicine) async throws {
        try await medicinesRef(userId: userId).addDocument(data: medicine.toFirestoreData())
    }

    func updateMedicine(userId: String, medicine: Medicine) async throws {
        try await medicinesRef(userId: userId)
            .document(medicine.id)
            .setData(medicine.toFirestoreData())
    }

    func deleteMedicine(userId: String, medicineId: String) async throws {
        try await medicinesRef(userId: userId).document(medicineId).delete()
    }

    func decrementAmount(userId: String, medicineId: String, currentAmount: Int) async throws {
        guard currentAmount > 0 else { return }
        try await medicinesRef(userId: userId).document(medicineId).updateData([
            "amount": currentAmount - 1
        ])
    }

    // MARK: - Dose Records

    func recordDose(userId: String, record: DoseRecord) async throws {
        try await doseRecordsRef(userId: userId).addDocument(data: record.toFirestoreData())
    }

    func getDoseRecordsForDate(userId: String, date: String) async throws -> [DoseRecord] {
        let snapshot = try await doseRecordsRef(userId: userId)
            .whereField("scheduledDate", isEqualTo: date)
            .getDocuments()
        return snapshot.documents.compactMap { DoseRecord(document: $0) }
    }
}
