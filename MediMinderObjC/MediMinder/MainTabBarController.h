#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The root tab bar shown after the user logs in.
/// Storyboard ID: "MainTabBarController"
///
/// In the storyboard, embed three navigation controllers as tabs:
///   Tab 0 — "Today"        → TodayViewController
///   Tab 1 — "Medicines"    → MedicinesViewController
///   Tab 2 — "Profile"      → ProfileViewController
@interface MainTabBarController : UITabBarController

@end

NS_ASSUME_NONNULL_END
