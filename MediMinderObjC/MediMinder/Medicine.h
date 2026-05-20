#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Medicine : NSObject

@property (nonatomic, copy) NSString *medicineId;       // Firestore document ID
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *medicineType;     // e.g. "Antibiotic"
@property (nonatomic, copy) NSString *dosage;           // e.g. "500mg"
@property (nonatomic, assign) NSInteger amount;         // pill count remaining
@property (nonatomic, copy) NSString *form;             // "Pill" | "Liquid" | "Injection"
@property (nonatomic, copy) NSString *instructions;
@property (nonatomic, copy) NSString *scheduleType;     // "interval" | "weekly"
@property (nonatomic, assign) NSInteger intervalHours;  // used when scheduleType == "interval"
@property (nonatomic, copy) NSArray<NSNumber *> *weeklyDays;   // 0=Mon..6=Sun
@property (nonatomic, copy) NSArray<NSString *> *scheduleTimes; // "HH:mm" strings
@property (nonatomic, strong) NSDate *createdAt;

/// Build a Medicine from a Firestore document dictionary.
+ (instancetype)medicineWithId:(NSString *)docId data:(NSDictionary *)data;

/// Convert back to a dictionary suitable for writing to Firestore.
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
