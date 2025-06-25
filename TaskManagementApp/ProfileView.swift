//
//  ProfileView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI
// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var completedTasks: Int {
        taskViewModel.tasks.filter { $0.isCompleted }.count
    }
    
    var pendingTasks: Int {
        taskViewModel.tasks.filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(authViewModel.currentUser?.name ?? "User")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Stats
                HStack(spacing: 40) {
                    VStack {
                        Text("\(taskViewModel.tasks.count)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Total Tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(completedTasks)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(taskViewModel.groups.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Groups")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Sign Out Button
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            .navigationTitle("Profile")
        }
    }
}

