#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Sign-up screen — pushed from LoginViewController via segue "ShowSignup".
/// Storyboard ID: "SignupViewController"
@interface SignupViewController : UIViewController

// ── IBOutlets — connect these in Interface Builder ────────────────────────────
//
//  emailTextField        → UITextField   (placeholder: "Email", keyboard: email)
//  passwordTextField     → UITextField   (placeholder: "Password", secureTextEntry: YES)
//  confirmTextField      → UITextField   (placeholder: "Confirm Password", secureTextEntry: YES)
//  createAccountButton   → UIButton      (title: "Create Account")
//  activityIndicator     → UIActivityIndicatorView
//  errorLabel            → UILabel       (hidden by default, red text)

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmTextField;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

- (IBAction)createAccountTapped:(id)sender;

@end

NS_ASSUME_NONNULL_END
