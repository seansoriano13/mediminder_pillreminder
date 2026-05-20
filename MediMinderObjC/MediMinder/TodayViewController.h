#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Shows all of today's scheduled doses in a UITableView.
/// Storyboard ID: "TodayViewController"
/// Tab bar item: title="Today", image=clock.fill (SF Symbol)
@interface TodayViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// ── IBOutlets — connect these in Interface Builder ────────────────────────────
//
//  tableView         → UITableView    (style: Plain, prototype cell with id "DoseCell")
//  emptyStateView    → UIView         (shown when there are no doses; contains emptyLabel)
//  emptyLabel        → UILabel        (text: "No doses scheduled for today.")
//  activityIndicator → UIActivityIndicatorView

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *emptyStateView;
@property (weak, nonatomic) IBOutlet UILabel *emptyLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

NS_ASSUME_NONNULL_END
