//
//  DataModels.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseFirestore
import FirebaseAuth

// MARK: - Data Models
struct User: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var appleUserID: String?
    var profileImageURL: String?
    var createdAt: Date
    var isOnline: Bool
    var lastSeen: Date
    
    init(name: String, email: String, appleUserID: String? = nil) {
        self.name = name
        self.email = email
        self.appleUserID = appleUserID
        self.profileImageURL = nil
        self.createdAt = Date()
        self.isOnline = false
        self.lastSeen = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

struct TaskGroup: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var memberIDs: [String] // Store user IDs instead of User objects
    var adminID: String
    var createdAt: Date
    var color: String
    var inviteCode: String
    var isPrivate: Bool
    
    // Computed property for members (fetch from Firestore when needed)
    var members: [User] = []
    
    init(name: String, description: String, members: [User], adminID: String, createdAt: Date, color: String) {
        self.name = name
        self.description = description
        self.memberIDs = members.compactMap { $0.id }
        self.adminID = adminID
        self.createdAt = createdAt
        self.color = color
        self.inviteCode = Self.generateInviteCode()
        self.isPrivate = false
        self.members = members
    }
    
    private static func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TaskGroup, rhs: TaskGroup) -> Bool {
        lhs.id == rhs.id
    }
}

struct Task: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var assignedTo: String // User ID - fixed property name
    var groupID: String? // Optional - for group tasks
    var createdBy: String // User ID - fixed property name
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var subtasks: [Subtask]
    var attachments: [TaskAttachment]
    var comments: [TaskComment]
    
    enum Priority: String, CaseIterable, Codable, Hashable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            case .urgent: return .purple
            }
        }
        
        var sortOrder: Int {
            switch self {
            case .low: return 0
            case .medium: return 1
            case .high: return 2
            case .urgent: return 3
            }
        }
    }
    
    init(title: String, description: String, isCompleted: Bool, priority: Priority, dueDate: Date?, assignedTo: String, groupID: String?, createdBy: String, createdAt: Date, tags: [String]) {
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.dueDate = dueDate
        self.assignedTo = assignedTo
        self.groupID = groupID
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = Date()
        self.tags = tags
        self.subtasks = []
        self.attachments = []
        self.comments = []
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}

struct Subtask: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}

struct TaskAttachment: Identifiable, Codable, Hashable {
    let id = UUID()
    var fileName: String
    var fileURL: String
    var fileType: String
    var uploadedBy: String
    var uploadedAt: Date
    
    init(fileName: String, fileURL: String, fileType: String, uploadedBy: String) {
        self.fileName = fileName
        self.fileURL = fileURL
        self.fileType = fileType
        self.uploadedBy = uploadedBy
        self.uploadedAt = Date()
    }
}

struct TaskComment: Identifiable, Codable, Hashable {
    let id = UUID()
    var text: String
    var authorID: String
    var createdAt: Date
    var isEdited: Bool
    
    init(text: String, authorID: String) {
        self.text = text
        self.authorID = authorID
        self.createdAt = Date()
        self.isEdited = false
    }
}

struct Notification: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var message: String
    var type: NotificationType
    var recipientID: String
    var senderID: String?
    var relatedTaskID: String?
    var relatedGroupID: String?
    var isRead: Bool
    var createdAt: Date
    
    enum NotificationType: String, Codable, CaseIterable {
        case taskAssigned = "task_assigned"
        case taskCompleted = "task_completed"
        case taskDueSoon = "task_due_soon"
        case taskOverdue = "task_overdue"
        case groupInvite = "group_invite"
        case taskComment = "task_comment"
        case taskUpdated = "task_updated"
    }
    
    init(title: String, message: String, type: NotificationType, recipientID: String, senderID: String? = nil) {
        self.title = title
        self.message = message
        self.type = type
        self.recipientID = recipientID
        self.senderID = senderID
        self.isRead = false
        self.createdAt = Date()
    }
}

// MARK: - Analytics Data
struct TaskAnalytics: Codable {
    var totalTasks: Int
    var completedTasks: Int
    var pendingTasks: Int
    var overdueTasks: Int
    var tasksByPriority: [String: Int]
    var tasksByGroup: [String: Int]
    var completionRate: Double
    var averageCompletionTime: Double // in hours
    
    init() {
        self.totalTasks = 0
        self.completedTasks = 0
        self.pendingTasks = 0
        self.overdueTasks = 0
        self.tasksByPriority = [:]
        self.tasksByGroup = [:]
        self.completionRate = 0.0
        self.averageCompletionTime = 0.0
    }
}

// MARK: - View Models
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let db = Firestore.firestore()
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                let fullName = appleIDCredential.fullName
                let name = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
                
                // Check if user exists in Firestore
                checkUserExists(appleUserID: userID, name: name.isEmpty ? "Apple User" : name, email: email)
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    private func checkUserExists(appleUserID: String, name: String, email: String) {
        db.collection("users").whereField("appleUserID", isEqualTo: appleUserID).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error checking user: \(error)")
                return
            }
            
            if let documents = snapshot?.documents, !documents.isEmpty {
                // User exists, load their data
                if let userData = documents.first {
                    do {
                        let user = try userData.data(as: User.self)
                        DispatchQueue.main.async {
                            self?.currentUser = user
                            self?.isAuthenticated = true
                        }
                    } catch {
                        print("Error decoding user: \(error)")
                    }
                }
            } else {
                // New user, create account
                self?.createNewUser(appleUserID: appleUserID, name: name, email: email)
            }
        }
    }
    
    private func createNewUser(appleUserID: String, name: String, email: String) {
        let newUser = User(name: name, email: email, appleUserID: appleUserID)
        
        do {
            let userData = try Firestore.Encoder().encode(newUser)
            db.collection("users").addDocument(data: userData) { [weak self] error in
                if let error = error {
                    print("Error creating user: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self?.currentUser = newUser
                        self?.isAuthenticated = true
                    }
                }
            }
        } catch {
            print("Error encoding user: \(error)")
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
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Task Methods
    func addTask(_ task: Task) {
        isLoading = true
        
        // Add to local array immediately for UI responsiveness
        tasks.append(task)
        
        // Convert task to dictionary for Firestore
        do {
            let taskData = try Firestore.Encoder().encode(task)
            
            db.collection("tasks").addDocument(data: taskData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("Error adding task: \(error)")
                        // Remove from local array if Firebase fails
                        self?.tasks.removeAll { $0.id == task.id }
                    }
                }
            }
        } catch {
            print("Error encoding task: \(error)")
            isLoading = false
            tasks.removeAll { $0.id == task.id }
        }
    }
    
    func deleteTask(_ task: Task) {
        // Remove from local array immediately
        tasks.removeAll { $0.id == task.id }
        
        // Remove from Firestore
        if let taskId = task.id {
            db.collection("tasks").document(taskId).delete { error in
                if let error = error {
                    print("Error deleting task: \(error)")
                    // Could add back to local array if needed
                }
            }
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        // Find and update in local array
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].updatedAt = Date()
            let updatedTask = tasks[index]
            
            // Update in Firestore
            if let taskId = updatedTask.id {
                do {
                    let taskData = try Firestore.Encoder().encode(updatedTask)
                    db.collection("tasks").document(taskId).setData(taskData) { error in
                        if let error = error {
                            print("Error updating task: \(error)")
                            // Revert local change if Firebase update fails
                            DispatchQueue.main.async {
                                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                                    self.tasks[index].isCompleted.toggle()
                                }
                            }
                        }
                    }
                } catch {
                    print("Error encoding task: \(error)")
                    // Revert local change
                    tasks[index].isCompleted.toggle()
                }
            }
        }
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            
            if let taskId = task.id {
                do {
                    let taskData = try Firestore.Encoder().encode(task)
                    db.collection("tasks").document(taskId).setData(taskData) { error in
                        if let error = error {
                            print("Error updating task: \(error)")
                        }
                    }
                } catch {
                    print("Error encoding task: \(error)")
                }
            }
        }
    }
    
    // MARK: - Group Methods
    func addGroup(_ group: TaskGroup) {
        isLoading = true
        groups.append(group)
        
        do {
            let groupData = try Firestore.Encoder().encode(group)
            
            db.collection("groups").addDocument(data: groupData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        print("Error adding group: \(error)")
                        self?.groups.removeAll { $0.id == group.id }
                    }
                }
            }
        } catch {
            print("Error encoding group: \(error)")
            isLoading = false
            groups.removeAll { $0.id == group.id }
        }
    }
    
    func deleteGroup(_ group: TaskGroup) {
        groups.removeAll { $0.id == group.id }
        tasks.removeAll { $0.groupID == group.id }
        
        // Delete from Firestore
        if let groupId = group.id {
            db.collection("groups").document(groupId).delete { error in
                if let error = error {
                    print("Error deleting group: \(error)")
                }
            }
            
            // Delete all tasks in this group
            db.collection("tasks").whereField("groupID", isEqualTo: groupId).getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    for document in documents {
                        document.reference.delete()
                    }
                }
            }
        }
    }
    
    func addMemberToGroup(_ group: TaskGroup, member: User) {
        if let index = groups.firstIndex(where: { $0.id == group.id }),
           let memberId = member.id {
            if !groups[index].memberIDs.contains(memberId) {
                groups[index].memberIDs.append(memberId)
                groups[index].members.append(member)
                
                if let groupId = group.id {
                    do {
                        let groupData = try Firestore.Encoder().encode(groups[index])
                        db.collection("groups").document(groupId).setData(groupData) { error in
                            if let error = error {
                                print("Error adding member to group: \(error)")
                            }
                        }
                    } catch {
                        print("Error encoding group: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Methods
    func fetchTasks(for userId: String) {
        db.collection("tasks")
            .whereField("assignedTo", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.tasks = documents.compactMap { document in
                        try? document.data(as: Task.self)
                    }
                }
            }
    }
    
    func fetchGroups(for userId: String) {
        db.collection("groups")
            .whereField("memberIDs", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching groups: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.groups = documents.compactMap { document in
                        try? document.data(as: TaskGroup.self)
                    }
                }
            }
    }
    
    func fetchGroupTasks(for groupID: String) {
        db.collection("tasks")
            .whereField("groupID", isEqualTo: groupID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching group tasks: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let groupTasks = documents.compactMap { document in
                    try? document.data(as: Task.self)
                }
                
                DispatchQueue.main.async {
                    // Update tasks array with group tasks
                    self?.tasks.removeAll { $0.groupID == groupID }
                    self?.tasks.append(contentsOf: groupTasks)
                }
            }
    }
    
    // MARK: - User Search
    func searchUsers(by email: String, completion: @escaping (Result<[User], Error>) -> Void) {
        db.collection("users")
            .whereField("email", isEqualTo: email.lowercased())
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let users = snapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
                
                completion(.success(users))
            }
    }
}
