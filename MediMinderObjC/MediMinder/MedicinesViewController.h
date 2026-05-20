#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Lists all saved medicines in a UITableView.
/// Storyboard ID: "MedicinesViewController"
/// Tab bar item: title="Medicines", image=pills.fill (SF Symbol)
@interface MedicinesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// ── IBOutlets — connect these in Interface Builder ────────────────────────────
//
//  tableView         → UITableView    (prototype cell id: "MedicineCell", style: Subtitle)
//  emptyStateView    → UIView         (shown when list is empty)
//  activityIndicator → UIActivityIndicatorView
//  addButton         → UIBarButtonItem (placed in nav bar, "+" title or system Add item)
//                      — connect to addMedicineTapped: action

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *emptyStateView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)addMedicineTapped:(id)sender;

@end

NS_ASSUME_NONNULL_END
