#import "AddMedicineViewController.h"
#import "FirestoreService.h"
#import <FirebaseAuth/FirebaseAuth.h>

static NSArray<NSString *> *medicineTypes() {
    return @[@"Antibiotic", @"Antiviral", @"Analgesic", @"Antihypertensive",
             @"Antihistamine", @"Supplement", @"Vitamin", @"Other"];
}

static NSArray<NSString *> *dayNames() {
    return @[@"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat", @"Sun"];
}

@interface AddMedicineViewController ()
@property (nonatomic, strong) FirestoreService *firestoreService;

// Internal state
@property (nonatomic, assign) NSInteger selectedTypeIndex;
@property (nonatomic, assign) NSInteger intervalHours;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *selectedWeeklyDays; // 0..6
@property (nonatomic, strong) NSMutableArray<NSString *> *scheduleTimes; // "HH:mm"
@end

@implementation AddMedicineViewController

// ── Lifecycle ─────────────────────────────────────────────────────────────────

- (void)viewDidLoad {
    [super viewDidLoad];
    self.firestoreService = [[FirestoreService alloc] init];
    self.selectedWeeklyDays = [NSMutableArray array];
    self.scheduleTimes = [NSMutableArray arrayWithObject:@"08:00"];
    self.intervalHours = 8;
    self.selectedTypeIndex = 0;

    // Nav bar items
    self.navigationItem.title = self.existingMedicine ? @"Edit Medicine" : @"Add Medicine";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
        target:self action:@selector(cancelTapped:)];

    // Picker view
    self.typePickerView.dataSource = self;
    self.typePickerView.delegate   = self;

    // Default UI state
    self.intervalSlider.minimumValue = 1;
    self.intervalSlider.maximumValue = 24;
    self.intervalSlider.value = 8;
    [self updateIntervalLabel];

    // Show interval panel by default
    [self showSchedulePanel:0];

    // Prefill if editing
    [self prefillIfEditing];
}

- (void)prefillIfEditing {
    Medicine *m = self.existingMedicine;
    if (!m) return;

    self.nameTextField.text         = m.name;
    self.dosageTextField.text       = m.dosage;
    self.amountTextField.text       = [NSString stringWithFormat:@"%ld", (long)m.amount];
    self.instructionsTextView.text  = m.instructions;

    // Medicine type
    NSArray *types = medicineTypes();
    NSInteger typeIdx = [types indexOfObject:m.medicineType];
    if (typeIdx != NSNotFound) {
        self.selectedTypeIndex = typeIdx;
        [self.typePickerView selectRow:typeIdx inComponent:0 animated:NO];
    }

    // Form (Pill/Liquid/Injection)
    NSArray *forms = @[@"Pill", @"Liquid", @"Injection"];
    NSInteger formIdx = [forms indexOfObject:m.form];
    if (formIdx != NSNotFound) self.formSegmentedControl.selectedSegmentIndex = formIdx;

    // Schedule
    if ([m.scheduleType isEqualToString:@"weekly"]) {
        self.scheduleSegmentControl.selectedSegmentIndex = 1;
        [self showSchedulePanel:1];
        self.selectedWeeklyDays = [m.weeklyDays mutableCopy];
    } else {
        self.scheduleSegmentControl.selectedSegmentIndex = 0;
        [self showSchedulePanel:0];
        self.intervalHours = m.intervalHours;
        self.intervalSlider.value = m.intervalHours;
        [self updateIntervalLabel];
    }

    if (m.scheduleTimes.count > 0) {
        self.scheduleTimes = [m.scheduleTimes mutableCopy];
        [self updateStartTimeButton];
    }
}

// ── IBActions ─────────────────────────────────────────────────────────────────

- (IBAction)scheduleSegmentChanged:(id)sender {
    [self showSchedulePanel:self.scheduleSegmentControl.selectedSegmentIndex];
}

- (IBAction)intervalSliderChanged:(id)sender {
    self.intervalHours = (NSInteger)roundf(self.intervalSlider.value);
    [self updateIntervalLabel];
}

- (IBAction)startTimeButtonTapped:(id)sender {
    [self showTimePickerForIndex:0];
}

- (IBAction)addTimeTapped:(id)sender {
    [self.scheduleTimes addObject:@"08:00"];
    [self rebuildTimesStackView];
}

- (IBAction)weekdayButtonTapped:(UIButton *)sender {
    NSInteger day = sender.tag;
    NSNumber *dayNum = @(day);
    if ([self.selectedWeeklyDays containsObject:dayNum]) {
        [self.selectedWeeklyDays removeObject:dayNum];
        sender.selected = NO;
    } else {
        [self.selectedWeeklyDays addObject:dayNum];
        sender.selected = YES;
    }
}

- (IBAction)cancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveTapped:(id)sender {
    // Basic validation
    NSString *name    = [self.nameTextField.text   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *dosage  = [self.dosageTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *amountStr = [self.amountTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (name.length == 0 || dosage.length == 0 || amountStr.length == 0) {
        [self showAlert:@"Please fill in Name, Dosage, and Amount."];
        return;
    }

    NSInteger amount = [amountStr integerValue];
    BOOL isWeekly = (self.scheduleSegmentControl.selectedSegmentIndex == 1);

    if (isWeekly && self.selectedWeeklyDays.count == 0) {
        [self showAlert:@"Please select at least one day."];
        return;
    }

    FIRUser *user = [FIRAuth auth].currentUser;
    if (!user) return;

    // Build medicine object
    NSArray *forms = @[@"Pill", @"Liquid", @"Injection"];
    NSString *form = forms[self.formSegmentedControl.selectedSegmentIndex];

    Medicine *med = [[Medicine alloc] init];
    med.medicineId   = self.existingMedicine ? self.existingMedicine.medicineId : @"";
    med.userId       = user.uid;
    med.name         = name;
    med.medicineType = medicineTypes()[self.selectedTypeIndex];
    med.dosage       = dosage;
    med.amount       = amount;
    med.form         = form;
    med.instructions = [self.instructionsTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    med.scheduleType = isWeekly ? @"weekly" : @"interval";
    med.intervalHours = self.intervalHours;
    med.weeklyDays   = [self.selectedWeeklyDays copy];
    med.scheduleTimes = [self.scheduleTimes copy];
    med.createdAt    = self.existingMedicine ? self.existingMedicine.createdAt : [NSDate date];

    [self setLoading:YES];

    void (^handler)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setLoading:NO];
            if (error) {
                [self showAlert:[NSString stringWithFormat:@"Save failed: %@", error.localizedDescription]];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    };

    if (self.existingMedicine) {
        [self.firestoreService updateMedicine:med userId:user.uid completion:handler];
    } else {
        [self.firestoreService addMedicine:med userId:user.uid completion:handler];
    }
}

// ── UI helpers ────────────────────────────────────────────────────────────────

- (void)showSchedulePanel:(NSInteger)index {
    // index 0 = interval, 1 = weekly
    self.intervalPanel.hidden = (index != 0);
    self.weeklyPanel.hidden   = (index != 1);
}

- (void)updateIntervalLabel {
    self.intervalLabel.text = [NSString stringWithFormat:@"Every %ld hours", (long)self.intervalHours];
}

- (void)updateStartTimeButton {
    NSString *time = self.scheduleTimes.firstObject ?: @"08:00";
    [self.startTimeButton setTitle:time forState:UIControlStateNormal];
}

- (void)rebuildTimesStackView {
    // Remove all existing arranged subviews
    for (UIView *v in self.timesStackView.arrangedSubviews) {
        [self.timesStackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    // Add a button for each time
    for (NSInteger i = 0; i < self.scheduleTimes.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:self.scheduleTimes[i] forState:UIControlStateNormal];
        btn.tag = i;
        [btn addTarget:self action:@selector(timeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.timesStackView addArrangedSubview:btn];
    }
}

- (void)timeButtonTapped:(UIButton *)sender {
    [self showTimePickerForIndex:sender.tag];
}

- (void)showTimePickerForIndex:(NSInteger)index {
    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.datePickerMode = UIDatePickerModeTime;
    if (@available(iOS 13.4, *)) picker.preferredDatePickerStyle = UIDatePickerStyleWheels;

    // Parse existing time to pre-select
    NSString *existing = (index < self.scheduleTimes.count) ? self.scheduleTimes[index] : @"08:00";
    NSArray *parts = [existing componentsSeparatedByString:@":"];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.hour   = [parts[0] integerValue];
    comps.minute = parts.count > 1 ? [parts[1] integerValue] : 0;
    picker.date  = [cal dateFromComponents:comps];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Time"
                                                                   message:@"\n\n\n\n\n\n\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert.view addSubview:picker];
    picker.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [picker.centerXAnchor constraintEqualToAnchor:alert.view.centerXAnchor],
        [picker.topAnchor constraintEqualToAnchor:alert.view.topAnchor constant:50],
    ]];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm";
        NSString *timeStr = [fmt stringFromDate:picker.date];

        if (index < self.scheduleTimes.count) {
            self.scheduleTimes[index] = timeStr;
        } else {
            [self.scheduleTimes addObject:timeStr];
        }
        [self updateStartTimeButton];
        [self rebuildTimesStackView];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.saveButton.enabled = !loading;
    if (loading) [self.activityIndicator startAnimating];
    else         [self.activityIndicator stopAnimating];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"MediMinder"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// ── UIPickerView (medicine type) ─────────────────────────────────────────────

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return medicineTypes().count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return medicineTypes()[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedTypeIndex = row;
}

@end
