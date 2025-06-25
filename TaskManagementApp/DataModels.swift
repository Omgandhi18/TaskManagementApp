//
//  DataModels.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI
import AuthenticationServices
// MARK: - Data Models
struct User: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var email: String
    var appleUserID: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

struct TaskGroup: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var members: [User]
    var adminID: UUID
    var createdAt: Date
    var color: String // Hex color for group theming
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TaskGroup, rhs: TaskGroup) -> Bool {
        lhs.id == rhs.id
    }
}

struct Task: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var assignedTo: UUID? // User ID
    var groupID: UUID? // Optional - for group tasks
    var createdBy: UUID
    var createdAt: Date
    var tags: [String]
    
    enum Priority: String, CaseIterable, Codable, Hashable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}
// MARK: - View Models
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                let fullName = appleIDCredential.fullName
                let name = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
                
                // Create user object
                let user = User(name: name.isEmpty ? "Apple User" : name,
                               email: email,
                               appleUserID: userID)
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var groups: [TaskGroup] = []
    @Published var showingAddTask = false
    @Published var showingAddGroup = false
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func addGroup(_ group: TaskGroup) {
        groups.append(group)
    }
    
    func deleteGroup(_ group: TaskGroup) {
        groups.removeAll { $0.id == group.id }
        // Also remove tasks associated with this group
        tasks.removeAll { $0.groupID == group.id }
    }
}
