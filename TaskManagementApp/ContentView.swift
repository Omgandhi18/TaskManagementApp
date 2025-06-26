//
//  ContentView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI
import AuthenticationServices

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                // Show loading screen while checking authentication
                LoadingView()
            } else if authViewModel.isAuthenticated {
                // User is authenticated, show main app
                MainTabView()
            } else {
                // User is not authenticated, show login
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoading)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("TaskManager")
                .font(.title)
                .fontWeight(.semibold)
            
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 10)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
