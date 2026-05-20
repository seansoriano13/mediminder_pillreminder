#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Displays the signed-in user's info and a sign-out button.
/// Storyboard ID: "ProfileViewController"
/// Tab bar item: title="Profile", image=person.fill (SF Symbol)
@interface ProfileViewController : UIViewController

// ── IBOutlets — connect these in Interface Builder ────────────────────────────
//
//  avatarLabel     → UILabel   (large circle background via cornerRadius; shows first letter)
//  displayNameLabel → UILabel  (shows email or display name)
//  emailLabel      → UILabel   (shows email address)
//  accountIdLabel  → UILabel   (shows first 12 chars of UID)
//  signOutButton   → UIButton  (title: "Sign Out", destructive style)
//  activityIndicator → UIActivityIndicatorView

@property (weak, nonatomic) IBOutlet UILabel *avatarLabel;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountIdLabel;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)signOutTapped:(id)sender;

@end

NS_ASSUME_NONNULL_END
