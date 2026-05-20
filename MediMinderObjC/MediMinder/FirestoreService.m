#import "FirestoreService.h"
#import <FirebaseFirestore/FirebaseFirestore.h>

@interface FirestoreService ()
@property (nonatomic, strong) FIRFirestore *db;
@end

@implementation FirestoreService

- (instancetype)init {
    self = [super init];
    if (self) {
        _db = [FIRFirestore firestore];
    }
    return self;
}

// ── Private helpers ───────────────────────────────────────────────────────────

- (FIRCollectionReference *)medicinesRefForUserId:(NSString *)userId {
    return [[self.db collectionWithPath:@"users"] documentWithPath:userId].collection(@"medicines");
}

// Objective-C doesn't have the Swift subscript shorthand, use the method version:
- (FIRCollectionReference *)doseRecordsRefForUserId:(NSString *)userId {
    return [[[self.db collectionWithPath:@"users"] documentWithPath:userId] collectionWithPath:@"doseRecords"];
}

// ── Medicines ─────────────────────────────────────────────────────────────────

- (void)getMedicinesForUserId:(NSString *)userId completion:(MedicineArrayBlock)completion {
    FIRCollectionReference *ref = [self medicinesRefForUserId:userId];
    [[ref queryOrderedByField:@"createdAt" descending:NO]
     getDocumentsWithCompletion:^(FIRQuerySnapshot *snapshot, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSMutableArray<Medicine *> *list = [NSMutableArray array];
        for (FIRDocumentSnapshot *doc in snapshot.documents) {
            [list addObject:[Medicine medicineWithId:doc.documentID data:doc.data]];
        }
        completion([list copy], nil);
    }];
}

- (void)addMedicine:(Medicine *)medicine userId:(NSString *)userId completion:(ErrorBlock)completion {
    FIRCollectionReference *ref = [self medicinesRefForUserId:userId];
    [ref addDocumentWithData:[medicine toDictionary] completion:^(NSError *error) {
        completion(error);
    }];
}

- (void)updateMedicine:(Medicine *)medicine userId:(NSString *)userId completion:(ErrorBlock)completion {
    FIRCollectionReference *ref = [self medicinesRefForUserId:userId];
    [[ref documentWithPath:medicine.medicineId]
     setData:[medicine toDictionary]
     merge:NO
     completion:^(NSError *error) {
        completion(error);
    }];
}

- (void)deleteMedicineWithId:(NSString *)medicineId userId:(NSString *)userId completion:(ErrorBlock)completion {
    FIRCollectionReference *ref = [self medicinesRefForUserId:userId];
    [[ref documentWithPath:medicineId] deleteDocumentWithCompletion:^(NSError *error) {
        completion(error);
    }];
}

- (void)decrementAmountForMedicineId:(NSString *)medicineId
                              userId:(NSString *)userId
                       currentAmount:(NSInteger)currentAmount
                          completion:(ErrorBlock)completion {
    if (currentAmount <= 0) {
        completion(nil);
        return;
    }
    FIRCollectionReference *ref = [self medicinesRefForUserId:userId];
    [[ref documentWithPath:medicineId]
     updateData:@{@"amount": @(currentAmount - 1)}
     completion:^(NSError *error) {
        completion(error);
    }];
}

// ── Dose Records ──────────────────────────────────────────────────────────────

- (void)recordDose:(DoseRecord *)record userId:(NSString *)userId completion:(ErrorBlock)completion {
    FIRCollectionReference *ref = [self doseRecordsRefForUserId:userId];
    [ref addDocumentWithData:[record toDictionary] completion:^(NSError *error) {
        completion(error);
    }];
}

- (void)getDoseRecordsForUserId:(NSString *)userId
                           date:(NSString *)dateString
                     completion:(DoseRecordArrayBlock)completion {
    FIRCollectionReference *ref = [self doseRecordsRefForUserId:userId];
    [[ref queryWhereField:@"scheduledDate" isEqualTo:dateString]
     getDocumentsWithCompletion:^(FIRQuerySnapshot *snapshot, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSMutableArray<DoseRecord *> *list = [NSMutableArray array];
        for (FIRDocumentSnapshot *doc in snapshot.documents) {
            [list addObject:[DoseRecord recordWithId:doc.documentID data:doc.data]];
        }
        completion([list copy], nil);
    }];
}

@end
