#import "Medicine.h"
#import <FirebaseFirestore/FirebaseFirestore.h>

@implementation Medicine

+ (instancetype)medicineWithId:(NSString *)docId data:(NSDictionary *)data {
    Medicine *m = [[Medicine alloc] init];
    m.medicineId    = docId;
    m.userId        = data[@"userId"]        ?: @"";
    m.name          = data[@"name"]          ?: @"";
    m.medicineType  = data[@"medicineType"]  ?: @"";
    m.dosage        = data[@"dosage"]        ?: @"";
    m.amount        = [data[@"amount"] integerValue];
    m.form          = data[@"form"]          ?: @"Pill";
    m.instructions  = data[@"instructions"]  ?: @"";
    m.scheduleType  = data[@"scheduleType"]  ?: @"interval";
    m.intervalHours = [data[@"intervalHours"] integerValue] ?: 8;

    NSArray *rawDays = data[@"weeklyDays"];
    m.weeklyDays = [rawDays isKindOfClass:[NSArray class]] ? rawDays : @[];

    NSArray *rawTimes = data[@"scheduleTimes"];
    m.scheduleTimes = [rawTimes isKindOfClass:[NSArray class]] ? rawTimes : @[];

    id rawCreatedAt = data[@"createdAt"];
    if ([rawCreatedAt isKindOfClass:[FIRTimestamp class]]) {
        m.createdAt = [(FIRTimestamp *)rawCreatedAt dateValue];
    } else {
        m.createdAt = [NSDate date];
    }

    return m;
}

- (NSDictionary *)toDictionary {
    return @{
        @"userId":        self.userId        ?: @"",
        @"name":          self.name          ?: @"",
        @"medicineType":  self.medicineType  ?: @"",
        @"dosage":        self.dosage        ?: @"",
        @"amount":        @(self.amount),
        @"form":          self.form          ?: @"Pill",
        @"instructions":  self.instructions  ?: @"",
        @"scheduleType":  self.scheduleType  ?: @"interval",
        @"intervalHours": @(self.intervalHours),
        @"weeklyDays":    self.weeklyDays    ?: @[],
        @"scheduleTimes": self.scheduleTimes ?: @[],
        @"createdAt":     [FIRTimestamp timestampWithDate:self.createdAt ?: [NSDate date]],
    };
}

@end
