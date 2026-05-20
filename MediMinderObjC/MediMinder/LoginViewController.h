#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Root view controller shown before the user is authenticated.
/// Storyboard ID: "LoginViewController"
@interface LoginViewController : UIViewController

// ── IBOutlets — connect these in Interface Builder ────────────────────────────
//
//  emailTextField        → UITextField   (placeholder: "Email", keyboard: email)
//  passwordTextField     → UITextField   (placeholder: "Password", secureTextEntry: YES)
//  signInButton          → UIButton      (title: "Sign In", style: filled)
//  signUpButton          → UIButton      (title: "Don't have an account? Sign Up")
//  activityIndicator     → UIActivityIndicatorView (hides when stopped)
//  errorLabel            → UILabel       (hidden by default, red text)

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

// ── IBActions — connect these to the buttons in Interface Builder ──────────────
- (IBAction)signInTapped:(id)sender;
- (IBAction)signUpTapped:(id)sender;

@end

NS_ASSUME_NONNULL_END
