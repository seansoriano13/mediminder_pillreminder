#import "SignupViewController.h"
#import "MainTabBarController.h"
#import <FirebaseAuth/FirebaseAuth.h>

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Create Account";
    self.errorLabel.hidden = YES;
    self.activityIndicator.hidesWhenStopped = YES;
    self.passwordTextField.secureTextEntry = YES;
    self.confirmTextField.secureTextEntry = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)createAccountTapped:(id)sender {
    NSString *email    = [self.emailTextField.text    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *confirm  = [self.confirmTextField.text  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (email.length == 0 || password.length == 0) {
        [self showError:@"Please fill in all fields."];
        return;
    }
    if (![password isEqualToString:confirm]) {
        [self showError:@"Passwords do not match."];
        return;
    }
    if (password.length < 6) {
        [self showError:@"Password must be at least 6 characters."];
        return;
    }

    [self setLoading:YES];
    self.errorLabel.hidden = YES;

    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRAuthDataResult *result, NSError *error) {
        [self setLoading:NO];
        if (error) {
            [self showError:error.localizedDescription];
            return;
        }
        // Registration succeeded — go straight to the main tab bar
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        MainTabBarController *tabBar = [sb instantiateViewControllerWithIdentifier:@"MainTabBarController"];
        UIWindow *window = self.view.window;
        window.rootViewController = tabBar;
        [UIView transitionWithView:window
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:nil
                        completion:nil];
    }];
}

- (void)setLoading:(BOOL)loading {
    self.createAccountButton.enabled = !loading;
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

@end
