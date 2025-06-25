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
        if authViewModel.isAuthenticated {
            MainTabView()
                .onAppear {
                    // Start fetching data when user is authenticated
                    if let userId = authViewModel.currentUser?.id {
                        taskViewModel.fetchTasks(for: userId)
                        taskViewModel.fetchGroups(for: userId)
                    }
                }
        } else {
            LoginView()
        }
    }
}
