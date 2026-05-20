#import "MedicinesViewController.h"
#import "AddMedicineViewController.h"
#import "Medicine.h"
#import "FirestoreService.h"
#import <FirebaseAuth/FirebaseAuth.h>

@interface MedicinesViewController ()
@property (nonatomic, strong) FirestoreService *firestoreService;
@property (nonatomic, strong) NSArray<Medicine *> *medicines;
@end

@implementation MedicinesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"My Medicines";
    self.firestoreService = [[FirestoreService alloc] init];
    self.medicines = @[];

    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
    self.emptyStateView.hidden = YES;
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadMedicines]; // Refresh every time we come back to this tab
}

- (void)loadMedicines {
    FIRUser *user = [FIRAuth auth].currentUser;
    if (!user) return;

    [self.activityIndicator startAnimating];

    [self.firestoreService getMedicinesForUserId:user.uid
                                      completion:^(NSArray<Medicine *> *medicines, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.medicines = medicines ?: @[];
            [self.tableView reloadData];
            self.emptyStateView.hidden = (self.medicines.count > 0);
            self.tableView.hidden = (self.medicines.count == 0);
        });
    }];
}

// ── Add medicine ──────────────────────────────────────────────────────────────

- (IBAction)addMedicineTapped:(id)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AddMedicineViewController *vc = [sb instantiateViewControllerWithIdentifier:@"AddMedicineViewController"];
    vc.existingMedicine = nil; // nil = add mode
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

// ── UITableViewDataSource ─────────────────────────────────────────────────────

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.medicines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MedicineCell"
                                                            forIndexPath:indexPath];
    Medicine *med = self.medicines[indexPath.row];
    cell.textLabel.text = med.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %@ • %ld remaining",
                                 med.dosage, med.form, (long)med.amount];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

// ── UITableViewDelegate — tap to edit, swipe to delete ───────────────────────

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Medicine *med = self.medicines[indexPath.row];

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AddMedicineViewController *vc = [sb instantiateViewControllerWithIdentifier:@"AddMedicineViewController"];
    vc.existingMedicine = med;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {

    UIContextualAction *deleteAction =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:@"Delete"
                                              handler:^(UIContextualAction *action,
                                                        UIView *sourceView,
                                                        void (^completionHandler)(BOOL)) {
            [self confirmDeleteAtIndex:indexPath];
            completionHandler(NO); // we'll reload after confirm
        }];

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

- (void)confirmDeleteAtIndex:(NSIndexPath *)indexPath {
    Medicine *med = self.medicines[indexPath.row];
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Delete Medicine"
        message:[NSString stringWithFormat:@"Remove \"%@\"? This cannot be undone.", med.name]
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction *action) {
        FIRUser *user = [FIRAuth auth].currentUser;
        if (!user) return;
        [self.firestoreService deleteMedicineWithId:med.medicineId
                                            userId:user.uid
                                        completion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadMedicines];
            });
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
