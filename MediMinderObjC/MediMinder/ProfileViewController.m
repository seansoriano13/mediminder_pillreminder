#import "ProfileViewController.h"
#import "LoginViewController.h"
#import <FirebaseAuth/FirebaseAuth.h>

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Profile";
    self.activityIndicator.hidesWhenStopped = YES;
    [self populateUserInfo];
}

- (void)populateUserInfo {
    FIRUser *user = [FIRAuth auth].currentUser;
    if (!user) return;

    NSString *displayName = user.displayName.length > 0 ? user.displayName : user.email;
    NSString *initial = (displayName.length > 0) ? [[displayName substringToIndex:1] uppercaseString] : @"?";

    self.avatarLabel.text = initial;

    // Make avatar label look like a circle (set in storyboard or here)
    self.avatarLabel.layer.cornerRadius  = self.avatarLabel.frame.size.width / 2.0;
    self.avatarLabel.layer.masksToBounds = YES;

    self.displayNameLabel.text = displayName;
    self.emailLabel.text       = user.email ?: @"No email";

    if (user.uid.length >= 12) {
        self.accountIdLabel.text = [[user.uid substringToIndex:12] stringByAppendingString:@"..."];
    } else {
        self.accountIdLabel.text = user.uid;
    }
}

- (IBAction)signOutTapped:(id)sender {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Sign Out"
        message:@"Are you sure you want to sign out?"
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Sign Out"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction *action) {
        [self performSignOut];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performSignOut {
    [self.activityIndicator startAnimating];
    self.signOutButton.enabled = NO;

    NSError *error = nil;
    [[FIRAuth auth] signOut:&error];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        if (error) {
            UIAlertController *errAlert = [UIAlertController
                alertControllerWithTitle:@"Error"
                message:error.localizedDescription
                preferredStyle:UIAlertControllerStyleAlert];
            [errAlert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
            [self presentViewController:errAlert animated:YES completion:nil];
            self.signOutButton.enabled = YES;
            return;
        }

        // Go back to login screen
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *loginVC = [sb instantiateViewControllerWithIdentifier:@"LoginViewController"];
        UIWindow *window = self.view.window;
        window.rootViewController = loginVC;
        [UIView transitionWithView:window
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:nil
                        completion:nil];
    });
}

@end
