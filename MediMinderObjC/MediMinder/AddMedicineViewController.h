#import <UIKit/UIKit.h>
#import "Medicine.h"

NS_ASSUME_NONNULL_BEGIN

/// Add or edit a medicine.
/// Storyboard ID: "AddMedicineViewController"
/// Present modally (inside a UINavigationController).
@interface AddMedicineViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

/// Pass nil to add a new medicine, or an existing object to edit.
@property (nonatomic, strong, nullable) Medicine *existingMedicine;

// ── IBOutlets — connect these in Interface Builder ────────────────────────────
//
//  nameTextField         → UITextField   (placeholder: "Medicine Name")
//  dosageTextField       → UITextField   (placeholder: "e.g. 500mg")
//  amountTextField       → UITextField   (placeholder: "e.g. 30", keyboard: numberPad)
//  instructionsTextView  → UITextView    (placeholder behaviour via delegate)
//
//  typePickerView        → UIPickerView  (shows medicine type list)
//  formSegmentedControl  → UISegmentedControl  (segments: Pill | Liquid | Injection)
//
//  scheduleSegmentControl → UISegmentedControl (segments: Every X Hours | Days of Week)
//
//  — Interval schedule panel (hide/show based on scheduleSegmentControl):
//  intervalSlider        → UISlider      (min:1 max:24)
//  intervalLabel         → UILabel       (text: "Every 8 hours")
//  startTimeButton       → UIButton      (shows selected start time, e.g. "08:00")
//
//  — Weekly schedule panel (hide/show based on scheduleSegmentControl):
//  weekdayStackView      → UIStackView   (contains 7 UIButtons: Mon–Sun)
//                          name each button tag 0–6 (Mon=0, Sun=6)
//  addTimeButton         → UIButton      (title: "+ Add Time")
//  timesStackView        → UIStackView   (programmatically populated with time buttons)
//
//  saveButton            → UIButton      (title: "Save Medicine")
//  activityIndicator     → UIActivityIndicatorView

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *dosageTextField;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UITextView  *instructionsTextView;

@property (weak, nonatomic) IBOutlet UIPickerView *typePickerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *formSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *scheduleSegmentControl;

// Interval panel
@property (weak, nonatomic) IBOutlet UIView   *intervalPanel;
@property (weak, nonatomic) IBOutlet UISlider *intervalSlider;
@property (weak, nonatomic) IBOutlet UILabel  *intervalLabel;
@property (weak, nonatomic) IBOutlet UIButton *startTimeButton;

// Weekly panel
@property (weak, nonatomic) IBOutlet UIView      *weeklyPanel;
@property (weak, nonatomic) IBOutlet UIStackView *weekdayStackView;
@property (weak, nonatomic) IBOutlet UIButton    *addTimeButton;
@property (weak, nonatomic) IBOutlet UIStackView *timesStackView;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// ── IBActions ─────────────────────────────────────────────────────────────────
- (IBAction)scheduleSegmentChanged:(id)sender;
- (IBAction)intervalSliderChanged:(id)sender;
- (IBAction)startTimeButtonTapped:(id)sender;
- (IBAction)addTimeTapped:(id)sender;
- (IBAction)weekdayButtonTapped:(UIButton *)sender; // tag = 0..6
- (IBAction)saveTapped:(id)sender;
- (IBAction)cancelTapped:(id)sender;

@end

NS_ASSUME_NONNULL_END
