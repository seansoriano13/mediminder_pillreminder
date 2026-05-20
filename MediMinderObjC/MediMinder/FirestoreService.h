#import <Foundation/Foundation.h>
#import "Medicine.h"
#import "DoseRecord.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^MedicineArrayBlock)(NSArray<Medicine *> * _Nullable medicines, NSError * _Nullable error);
typedef void(^DoseRecordArrayBlock)(NSArray<DoseRecord *> * _Nullable records, NSError * _Nullable error);
typedef void(^ErrorBlock)(NSError * _Nullable error);

@interface FirestoreService : NSObject

/// Fetches all medicines for a user (one-time, call again to refresh).
- (void)getMedicinesForUserId:(NSString *)userId completion:(MedicineArrayBlock)completion;

/// Adds a new medicine document. The medicineId field is ignored on write.
- (void)addMedicine:(Medicine *)medicine userId:(NSString *)userId completion:(ErrorBlock)completion;

/// Updates an existing medicine document by medicineId.
- (void)updateMedicine:(Medicine *)medicine userId:(NSString *)userId completion:(ErrorBlock)completion;

/// Deletes a medicine document.
- (void)deleteMedicineWithId:(NSString *)medicineId userId:(NSString *)userId completion:(ErrorBlock)completion;

/// Decrements the medicine amount by 1 (only if amount > 0).
- (void)decrementAmountForMedicineId:(NSString *)medicineId
                              userId:(NSString *)userId
                       currentAmount:(NSInteger)currentAmount
                          completion:(ErrorBlock)completion;

/// Saves a dose record (taken / dismissed).
- (void)recordDose:(DoseRecord *)record userId:(NSString *)userId completion:(ErrorBlock)completion;

/// Fetches all dose records for a given date string ("YYYY-MM-DD").
- (void)getDoseRecordsForUserId:(NSString *)userId
                           date:(NSString *)dateString
                     completion:(DoseRecordArrayBlock)completion;

@end

NS_ASSUME_NONNULL_END
