#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DoseRecord : NSObject

@property (nonatomic, copy) NSString *recordId;       // Firestore document ID
@property (nonatomic, copy) NSString *medicineId;
@property (nonatomic, copy) NSString *scheduledDate;  // "YYYY-MM-DD"
@property (nonatomic, copy) NSString *scheduledTime;  // "HH:mm"
@property (nonatomic, copy) NSString *status;         // "taken" | "dismissed"
@property (nonatomic, strong) NSDate *recordedAt;

+ (instancetype)recordWithId:(NSString *)docId data:(NSDictionary *)data;
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
