#import "TodayViewController.h"
#import "Medicine.h"
#import "DoseRecord.h"
#import "FirestoreService.h"
#import <FirebaseAuth/FirebaseAuth.h>

// ── Simple model to hold one displayable dose row ─────────────────────────────

typedef NS_ENUM(NSInteger, DoseStatus) {
    DoseStatusUpcoming,
    DoseStatusOverdue,
    DoseStatusTaken,
};

@interface DoseItem : NSObject
@property (nonatomic, strong) Medicine *medicine;
@property (nonatomic, copy)   NSString *scheduledTime; // "HH:mm"
@property (nonatomic, assign) DoseStatus status;
@end
@implementation DoseItem @end

// ── TodayViewController ───────────────────────────────────────────────────────

@interface TodayViewController ()
@property (nonatomic, strong) FirestoreService *firestoreService;
@property (nonatomic, strong) NSMutableArray<Medicine *> *medicines;
@property (nonatomic, strong) NSArray<DoseRecord *> *todayRecords;
@property (nonatomic, strong) NSArray<DoseItem *> *doseItems;
@property (nonatomic, strong) NSTimer *refreshTimer;
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Today's Doses";
    self.firestoreService = [[FirestoreService alloc] init];
    self.medicines = [NSMutableArray array];
    self.todayRecords = @[];
    self.doseItems = @[];

    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    self.emptyStateView.hidden = YES;
    self.activityIndicator.hidesWhenStopped = YES;

    // Add a manual refresh button in the nav bar
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
        target:self
        action:@selector(loadData)];

    [self loadData];

    // Refresh every 60 seconds so overdue status updates automatically
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                        target:self
                                                      selector:@selector(loadData)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)dealloc {
    [self.refreshTimer invalidate];
}

// ── Data loading ──────────────────────────────────────────────────────────────

- (void)loadData {
    FIRUser *user = [FIRAuth auth].currentUser;
    if (!user) return;

    [self.activityIndicator startAnimating];

    // Step 1 — load medicines
    [self.firestoreService getMedicinesForUserId:user.uid
                                      completion:^(NSArray<Medicine *> *medicines, NSError *error) {
        if (error || !medicines) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopAnimating];
            });
            return;
        }
        self.medicines = [medicines mutableCopy];

        // Step 2 — load today's dose records
        NSString *today = [self todayDateString];
        [self.firestoreService getDoseRecordsForUserId:user.uid
                                                 date:today
                                           completion:^(NSArray<DoseRecord *> *records, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopAnimating];
                self.todayRecords = records ?: @[];
                [self rebuildDoseItems];
                [self.tableView reloadData];
                self.emptyStateView.hidden = (self.doseItems.count > 0);
                self.tableView.hidden = (self.doseItems.count == 0);
            });
        }];
    }];
}

// ── Schedule logic (mirrors Flutter) ─────────────────────────────────────────

- (NSString *)todayDateString {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    return [fmt stringFromDate:[NSDate date]];
}

/// Returns every "HH:mm" string that a medicine should show today.
- (NSArray<NSString *> *)computeTodayTimesForMedicine:(Medicine *)medicine {
    NSMutableArray<NSString *> *times = [NSMutableArray array];

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger weekday = [cal component:NSCalendarUnitWeekday fromDate:[NSDate date]];
    // NSCalendar: Sunday=1 … Saturday=7. Convert to Mon=0..Sun=6.
    NSInteger todayIndex = (weekday == 1) ? 6 : weekday - 2;

    if ([medicine.scheduleType isEqualToString:@"interval"]) {
        if (medicine.scheduleTimes.count == 0) return @[];

        // Parse starting time
        NSArray *parts = [medicine.scheduleTimes[0] componentsSeparatedByString:@":"];
        NSInteger startHour   = [parts[0] integerValue];
        NSInteger startMinute = parts.count > 1 ? [parts[1] integerValue] : 0;

        NSInteger currentHour   = startHour;
        NSInteger currentMinute = startMinute;

        while (currentHour < 24) {
            [times addObject:[NSString stringWithFormat:@"%02ld:%02ld",
                              (long)currentHour, (long)currentMinute]];
            currentHour += medicine.intervalHours;
        }
    } else {
        // Weekly
        BOOL todaySelected = NO;
        for (NSNumber *day in medicine.weeklyDays) {
            if (day.integerValue == todayIndex) { todaySelected = YES; break; }
        }
        if (todaySelected) {
            [times addObjectsFromArray:medicine.scheduleTimes];
        }
    }
    return [times copy];
}

/// Determines the display status of a single dose slot.
- (DoseStatus)statusForMedicine:(Medicine *)medicine
                          time:(NSString *)scheduledTime
                       records:(NSArray<DoseRecord *> *)records {
    for (DoseRecord *r in records) {
        if ([r.medicineId isEqualToString:medicine.medicineId] &&
            [r.scheduledTime isEqualToString:scheduledTime]) {
            // Both "taken" and "dismissed" show as Taken (removed from active)
            return DoseStatusTaken;
        }
    }

    // Check if the time has passed
    NSArray *parts = [scheduledTime componentsSeparatedByString:@":"];
    NSInteger hour   = [parts[0] integerValue];
    NSInteger minute = parts.count > 1 ? [parts[1] integerValue] : 0;

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *comps = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                     fromDate:now];
    comps.hour   = hour;
    comps.minute = minute;
    comps.second = 0;
    NSDate *scheduledDateTime = [cal dateFromComponents:comps];

    if ([scheduledDateTime compare:now] == NSOrderedAscending) {
        return DoseStatusOverdue;
    }
    return DoseStatusUpcoming;
}

- (void)rebuildDoseItems {
    NSMutableArray<DoseItem *> *items = [NSMutableArray array];

    for (Medicine *med in self.medicines) {
        NSArray<NSString *> *times = [self computeTodayTimesForMedicine:med];
        for (NSString *t in times) {
            DoseItem *item = [[DoseItem alloc] init];
            item.medicine = med;
            item.scheduledTime = t;
            item.status = [self statusForMedicine:med time:t records:self.todayRecords];
            [items addObject:item];
        }
    }

    // Sort: overdue first, upcoming by time, taken last
    [items sortUsingComparator:^NSComparisonResult(DoseItem *a, DoseItem *b) {
        if (a.status == DoseStatusOverdue && b.status != DoseStatusOverdue) return NSOrderedAscending;
        if (a.status != DoseStatusOverdue && b.status == DoseStatusOverdue) return NSOrderedDescending;
        if (a.status == DoseStatusTaken   && b.status != DoseStatusTaken)   return NSOrderedDescending;
        if (a.status != DoseStatusTaken   && b.status == DoseStatusTaken)   return NSOrderedAscending;
        return [a.scheduledTime compare:b.scheduledTime];
    }];

    self.doseItems = [items copy];
}

// ── UITableViewDataSource ─────────────────────────────────────────────────────

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.doseItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Dequeue the prototype cell you created in the storyboard with id "DoseCell"
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DoseCell"
                                                            forIndexPath:indexPath];
    DoseItem *item = self.doseItems[indexPath.row];

    // ── Set the cell text ──
    // cell.textLabel      → medicine name + scheduled time
    // cell.detailTextLabel → status badge text
    cell.textLabel.text = [NSString stringWithFormat:@"%@  •  %@",
                           item.medicine.name, item.scheduledTime];

    switch (item.status) {
        case DoseStatusUpcoming:
            cell.detailTextLabel.text = @"Upcoming";
            cell.detailTextLabel.textColor = [UIColor systemBlueColor];
            break;
        case DoseStatusOverdue:
            cell.detailTextLabel.text = @"⚠ Overdue";
            cell.detailTextLabel.textColor = [UIColor systemOrangeColor];
            break;
        case DoseStatusTaken:
            cell.detailTextLabel.text = @"✓ Taken";
            cell.detailTextLabel.textColor = [UIColor systemGreenColor];
            break;
    }

    return cell;
}

// ── UITableViewDelegate — swipe actions ──────────────────────────────────────

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {

    DoseItem *item = self.doseItems[indexPath.row];
    if (item.status == DoseStatusTaken) return nil;

    // "Mark as Taken" swipe
    UIContextualAction *takenAction =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                title:@"✓ Taken"
                                              handler:^(UIContextualAction *action,
                                                        UIView *sourceView,
                                                        void (^completionHandler)(BOOL)) {
            [self markAsTaken:item];
            completionHandler(YES);
        }];
    takenAction.backgroundColor = [UIColor systemGreenColor];

    return [UISwipeActionsConfiguration configurationWithActions:@[takenAction]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {

    DoseItem *item = self.doseItems[indexPath.row];
    if (item.status == DoseStatusTaken) return nil;

    // "Dismiss" swipe
    UIContextualAction *dismissAction =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:@"Dismiss"
                                              handler:^(UIContextualAction *action,
                                                        UIView *sourceView,
                                                        void (^completionHandler)(BOOL)) {
            [self dismissDose:item];
            completionHandler(YES);
        }];

    return [UISwipeActionsConfiguration configurationWithActions:@[dismissAction]];
}

// ── Actions ───────────────────────────────────────────────────────────────────

- (void)markAsTaken:(DoseItem *)item {
    FIRUser *user = [FIRAuth auth].currentUser;
    if (!user) return;

    DoseRecord *record = [[DoseRecord alloc] init];
    record.recordId      = @"";
    record.medicineId    = item.medicine.medicineId;
    record.scheduledDate = [self todayDateString];
    record.scheduledTime = item.scheduledTime;
    record.status        = @"taken";
    record.recordedAt    = [NSDate date];

    [self.firestoreService recordDose:record userId:user.uid completion:^(NSError *error) {
        // Decrement pill count
        [self.firestoreService decrementAmountForMedicineId:item.medicine.medicineId
                                                     userId:user.uid
                                              currentAmount:item.medicine.amount
                                                 completion:^(NSError *err) {
            [self loadData];
        }];
    }];
}

- (void)dismissDose:(DoseItem *)item {
    FIRUser *user = [FIRAuth auth].currentUser;
    if (!user) return;

    DoseRecord *record = [[DoseRecord alloc] init];
    record.recordId      = @"";
    record.medicineId    = item.medicine.medicineId;
    record.scheduledDate = [self todayDateString];
    record.scheduledTime = item.scheduledTime;
    record.status        = @"dismissed";
    record.recordedAt    = [NSDate date];

    [self.firestoreService recordDose:record userId:user.uid completion:^(NSError *error) {
        [self loadData];
    }];
}

@end
