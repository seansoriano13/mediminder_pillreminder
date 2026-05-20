#import "DoseRecord.h"
#import <FirebaseFirestore/FirebaseFirestore.h>

@implementation DoseRecord

+ (instancetype)recordWithId:(NSString *)docId data:(NSDictionary *)data {
    DoseRecord *r = [[DoseRecord alloc] init];
    r.recordId      = docId;
    r.medicineId    = data[@"medicineId"]    ?: @"";
    r.scheduledDate = data[@"scheduledDate"] ?: @"";
    r.scheduledTime = data[@"scheduledTime"] ?: @"";
    r.status        = data[@"status"]        ?: @"taken";

    id rawRecordedAt = data[@"recordedAt"];
    if ([rawRecordedAt isKindOfClass:[FIRTimestamp class]]) {
        r.recordedAt = [(FIRTimestamp *)rawRecordedAt dateValue];
    } else {
        r.recordedAt = [NSDate date];
    }

    return r;
}

- (NSDictionary *)toDictionary {
    return @{
        @"medicineId":    self.medicineId    ?: @"",
        @"scheduledDate": self.scheduledDate ?: @"",
        @"scheduledTime": self.scheduledTime ?: @"",
        @"status":        self.status        ?: @"taken",
        @"recordedAt":    [FIRTimestamp timestampWithDate:self.recordedAt ?: [NSDate date]],
    };
}

@end
