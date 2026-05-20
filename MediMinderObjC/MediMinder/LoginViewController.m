#import "LoginViewController.h"
#import "SignupViewController.h"
#import "MainTabBarController.h"
#import <FirebaseAuth/FirebaseAuth.h>

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MediMinder";
    self.errorLabel.hidden = YES;
    self.activityIndicator.hidesWhenStopped = YES;
    self.passwordTextField.secureTextEntry = YES;

    // Dismiss keyboard when tapping outside text fields
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

// ── Sign In ───────────────────────────────────────────────────────────────────

- (IBAction)signInTapped:(id)sender {
    NSString *email    = [self.emailTextField.text    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (email.length == 0 || password.length == 0) {
        [self showError:@"Please enter your email and password."];
        return;
    }

    [self setLoading:YES];
    self.errorLabel.hidden = YES;

    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRAuthDataResult *result, NSError *error) {
        [self setLoading:NO];
        if (error) {
            [self showError:[self friendlyError:error]];
            return;
        }
        [self navigateToMain];
    }];
}

// ── Navigate to Sign Up ───────────────────────────────────────────────────────

- (IBAction)signUpTapped:(id)sender {
    // The storyboard segue with identifier "ShowSignup" handles this automatically
    // if you connect the button. Alternatively, perform it manually:
    [self performSegueWithIdentifier:@"ShowSignup" sender:nil];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

- (void)navigateToMain {
    // Load the MainTabBarController from the storyboard and set it as root
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MainTabBarController *tabBar = [sb instantiateViewControllerWithIdentifier:@"MainTabBarController"];
    UIWindow *window = self.view.window;
    window.rootViewController = tabBar;
    [UIView transitionWithView:window
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:nil
                    completion:nil];
}

- (void)setLoading:(BOOL)loading {
    self.signInButton.enabled = !loading;
    if (loading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void)showError:(NSString *)message {
    self.errorLabel.text = message;
    self.errorLabel.hidden = NO;
}

- (NSString *)friendlyError:(NSError *)error {
    NSString *code = error.userInfo[FIRAuthErrorUserInfoNameKey] ?: @"";
    if ([code isEqualToString:@"ERROR_USER_NOT_FOUND"]) {
        return @"No account found with this email.";
    } else if ([code isEqualToString:@"ERROR_WRONG_PASSWORD"]) {
        return @"Incorrect password. Please try again.";
    } else if ([code isEqualToString:@"ERROR_INVALID_EMAIL"]) {
        return @"Please enter a valid email address.";
    } else {
        return @"Sign-in failed. Please try again.";
    }
}

@end
