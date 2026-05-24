import SwiftUI

/// Auth gate: shows LoginView when logged out, MainTabView when logged in.
struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        if authService.currentUser != nil {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

// MARK: - Main Tab Bar

struct MainTabView: View {
    private let purple = Color(red: 0.404, green: 0.314, blue: 0.643)

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "clock.fill")
                }

            MedicinesView()
                .tabItem {
                    Label("My Medicines", systemImage: "pills.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(purple)
    }
}
