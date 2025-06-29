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
enum TaskStatus: String, CaseIterable, Codable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case completed = "Completed"
}

// Also add TaskPriority if it doesn't exist
enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}
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
    var color: String
    var status: TaskStatus = .todo
    
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
        self.color = priority.color.description
        self.status = .todo
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
// Helper struct for storing User data in UserDefaults (without Firestore property wrappers)
struct UserForStorage: Codable {
    let id: String?
    let name: String
    let email: String
    let appleUserID: String?
    let profileImageURL: String?
    let createdAt: Date
    let isOnline: Bool
    let lastSeen: Date
}

// Extension to convert between User and UserForStorage
extension User {
    init(from storage: UserForStorage) {
        self.init(name: storage.name, email: storage.email, appleUserID: storage.appleUserID)
        self.id = storage.id
        self.profileImageURL = storage.profileImageURL
        self.createdAt = storage.createdAt
        self.isOnline = storage.isOnline
        self.lastSeen = storage.lastSeen
    }
}

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    
    private let db = Firestore.firestore()
    
    init() {
        print("🚀 AuthenticationViewModel initialized")
        // Add a small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.checkExistingAuthentication()
        }
    }
    
    // Check for existing authentication on app launch
    private func checkExistingAuthentication() {
        print("🔍 === STARTING AUTH CHECK ===")
        print("🔍 Current thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Debug UserDefaults contents
        debugUserDefaults()
        
        // First check if we have stored user credentials
        if let storedUserID = UserDefaults.standard.string(forKey: "appleUserID"),
           let storedUserData = UserDefaults.standard.data(forKey: "currentUser") {
            
            print("📱 Found stored credentials:")
            print("   - Apple User ID: \(storedUserID)")
            print("   - Stored data size: \(storedUserData.count) bytes")
            
            // Try to decode stored user
            do {
                let decodedUserStorage = try JSONDecoder().decode(UserForStorage.self, from: storedUserData)
                let decodedUser = User(from: decodedUserStorage)
                print("✅ Successfully decoded stored user:")
                print("   - Name: \(decodedUser.name)")
                print("   - Email: \(decodedUser.email)")
                print("   - ID: \(decodedUser.id ?? "nil")")
                
                // Verify the user still exists in Firestore and update their data
                verifyStoredUser(user: decodedUser, appleUserID: storedUserID)
            } catch {
                print("❌ Error decoding stored user: \(error)")
                print("❌ Will clear corrupted data and show login")
                // Clear corrupted data and show login
                clearStoredCredentials()
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        } else {
            print("📝 No stored credentials found:")
            print("   - Apple User ID: \(UserDefaults.standard.string(forKey: "appleUserID") ?? "nil")")
            print("   - User Data: \(UserDefaults.standard.data(forKey: "currentUser") != nil ? "exists" : "nil")")
            
            // Check if we have appleUserID but no user data (corrupted state)
            if let storedAppleID = UserDefaults.standard.string(forKey: "appleUserID") {
                print("🔧 Found orphaned Apple ID, attempting to recover user...")
                recoverUserFromAppleID(appleUserID: storedAppleID)
            } else {
                print("📝 Showing login screen")
                // No stored credentials, show login
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func recoverUserFromAppleID(appleUserID: String) {
        print("🔄 Attempting to recover user from Apple ID: \(appleUserID)")
        
        db.collection("users").whereField("appleUserID", isEqualTo: appleUserID).getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error recovering user: \(error)")
                    self?.clearStoredCredentials()
                    self?.isLoading = false
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty,
                   let userData = documents.first {
                    do {
                        let user = try userData.data(as: User.self)
                        print("✅ User recovered successfully: \(user.name)")
                        
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.updateUserStatus(isOnline: true)
                        
                        // Store the recovered user data
                        self?.storeUserCredentials(user: user, appleUserID: appleUserID)
                        
                        print("🎉 AUTO-LOGIN SUCCESSFUL (recovered)!")
                    } catch {
                        print("❌ Error decoding recovered user: \(error)")
                        self?.clearStoredCredentials()
                    }
                } else {
                    print("❌ No user found for Apple ID, clearing credentials")
                    self?.clearStoredCredentials()
                }
                
                self?.isLoading = false
            }
        }
    }
    
    private func debugUserDefaults() {
        print("🔧 === USERDEFAULTS DEBUG ===")
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        print("🔧 All UserDefaults keys: \(allKeys)")
        
        // Check our specific keys
        if let appleID = UserDefaults.standard.string(forKey: "appleUserID") {
            print("🔧 appleUserID exists: \(appleID)")
        } else {
            print("🔧 appleUserID: NOT FOUND")
        }
        
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            print("🔧 currentUser data exists: \(userData.count) bytes")
        } else {
            print("🔧 currentUser data: NOT FOUND")
        }
        print("🔧 === END USERDEFAULTS DEBUG ===")
    }
    
    private func verifyStoredUser(user: User, appleUserID: String) {
        guard let userID = user.id else {
            print("❌ User has no ID, clearing credentials")
            clearStoredCredentials()
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        print("🔄 Verifying user exists in Firestore: \(userID)")
        
        // Check if user still exists in Firestore
        db.collection("users").document(userID).getDocument { [weak self] document, error in
            print("🔄 Firestore response received")
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error verifying user in Firestore: \(error)")
                    self?.clearStoredCredentials()
                    self?.isLoading = false
                    return
                }
                
                if let document = document, document.exists {
                    print("✅ User verified in Firestore")
                    // User exists, update with latest data from Firestore
                    do {
                        let updatedUser = try document.data(as: User.self)
                        print("🎉 AUTO-LOGIN SUCCESSFUL!")
                        print("   - User: \(updatedUser.name)")
                        print("   - Setting isAuthenticated = true")
                        
                        self?.currentUser = updatedUser
                        self?.isAuthenticated = true
                        self?.updateUserStatus(isOnline: true)
                        
                        // Update stored user data
                        self?.storeUserCredentials(user: updatedUser, appleUserID: appleUserID)
                        
                        print("✅ Auth state updated - isAuthenticated: \(self?.isAuthenticated ?? false)")
                    } catch {
                        print("⚠️ Error decoding updated user from Firestore: \(error)")
                        // Use stored user data as fallback
                        print("🔄 Using stored user data as fallback")
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.updateUserStatus(isOnline: true)
                        print("✅ Auth state updated (fallback) - isAuthenticated: \(self?.isAuthenticated ?? false)")
                    }
                } else {
                    // User no longer exists in Firestore
                    print("❌ User no longer exists in Firestore")
                    self?.clearStoredCredentials()
                }
                
                print("🏁 Setting isLoading = false")
                self?.isLoading = false
                print("🏁 Final state - isAuthenticated: \(self?.isAuthenticated ?? false), isLoading: \(self?.isLoading ?? true)")
            }
        }
    }
    
    private func storeUserCredentials(user: User, appleUserID: String) {
        print("💾 === STORING USER CREDENTIALS ===")
        print("💾 User: \(user.name)")
        print("💾 Apple ID: \(appleUserID)")
        
        UserDefaults.standard.set(appleUserID, forKey: "appleUserID")
        print("💾 ✅ Apple ID stored")
        
        // Create a JSON-encodable version of the user (without @DocumentID property wrapper)
        let userForStorage = UserForStorage(
            id: user.id,
            name: user.name,
            email: user.email,
            appleUserID: user.appleUserID,
            profileImageURL: user.profileImageURL,
            createdAt: user.createdAt,
            isOnline: user.isOnline,
            lastSeen: user.lastSeen
        )
        
        do {
            let encodedUser = try JSONEncoder().encode(userForStorage)
            UserDefaults.standard.set(encodedUser, forKey: "currentUser")
            print("💾 ✅ User data encoded and stored (\(encodedUser.count) bytes)")
            
            // Force synchronize
            UserDefaults.standard.synchronize()
            print("💾 ✅ UserDefaults synchronized")
            
            // Verify storage immediately
            let storedAppleID = UserDefaults.standard.string(forKey: "appleUserID")
            let storedUserData = UserDefaults.standard.data(forKey: "currentUser")
            print("💾 Verification - Apple ID: \(storedAppleID ?? "nil")")
            print("💾 Verification - User data: \(storedUserData?.count ?? 0) bytes")
            
        } catch {
            print("❌ Error encoding user for storage: \(error)")
        }
        print("💾 === END STORING CREDENTIALS ===")
    }
    
    private func clearStoredCredentials() {
        print("🗑️ === CLEARING STORED CREDENTIALS ===")
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.synchronize()
        print("🗑️ ✅ Credentials cleared and synchronized")
    }
    
    func signInWithApple(result: Result<ASAuthorization, Error>) {
        print("🍎 === APPLE SIGN IN STARTED ===")
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email ?? ""
                let fullName = appleIDCredential.fullName
                let name = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
                
                print("🍎 Apple Sign In Success:")
                print("   - Apple ID: \(userID)")
                print("   - Email: \(email)")
                print("   - Name: \(name)")
                
                // Check if user exists in Firestore
                checkUserExists(appleUserID: userID, name: name.isEmpty ? "Apple User" : name, email: email)
            }
        case .failure(let error):
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    private func checkUserExists(appleUserID: String, name: String, email: String) {
        print("🔍 Checking if user exists in Firestore...")
        
        db.collection("users").whereField("appleUserID", isEqualTo: appleUserID).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error checking user: \(error)")
                return
            }
            
            if let documents = snapshot?.documents, !documents.isEmpty {
                print("👤 Existing user found")
                // User exists, load their data
                if let userData = documents.first {
                    do {
                        let user = try userData.data(as: User.self)
                        DispatchQueue.main.async {
                            self?.currentUser = user
                            self?.isAuthenticated = true
                            self?.updateUserStatus(isOnline: true)
                            
                            // Store credentials for auto-login
                            self?.storeUserCredentials(user: user, appleUserID: appleUserID)
                            print("✅ Existing user signed in: \(user.name)")
                        }
                    } catch {
                        print("❌ Error decoding user: \(error)")
                    }
                }
            } else {
                print("🆕 New user, creating account...")
                // New user, create account
                self?.createNewUser(appleUserID: appleUserID, name: name, email: email)
            }
        }
    }
    
    private func createNewUser(appleUserID: String, name: String, email: String) {
        print("🆕 Creating new user: \(name)")
        let newUser = User(name: name, email: email, appleUserID: appleUserID)
        
        do {
            // Create a new document with auto ID
            let newDocRef = db.collection("users").document()
            
            // Create user data for Firestore (using Firestore.Encoder)
            var userWithId = newUser
            userWithId.id = newDocRef.documentID
            let firestoreUserData = try Firestore.Encoder().encode(userWithId)
            
            newDocRef.setData(firestoreUserData) { [weak self] error in
                if let error = error {
                    print("❌ Error creating user: \(error)")
                } else {
                    print("✅ New user created successfully: \(name)")
                    DispatchQueue.main.async {
                        self?.currentUser = userWithId
                        self?.isAuthenticated = true
                        
                        // Store credentials for auto-login
                        // This will handle the encoding issue properly
                        self?.storeUserCredentials(user: userWithId, appleUserID: appleUserID)
                        
                        // Set online status when user signs in
                        self?.updateUserStatus(isOnline: true)
                    }
                }
            }
        } catch {
            print("❌ Error encoding user for Firestore: \(error)")
        }
    }
    
    func updateUserStatus(isOnline: Bool) {
        guard let userId = currentUser?.id else { return }
        
        let updates: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).updateData(updates) { error in
            if let error = error {
                print("❌ Error updating user status: \(error)")
            } else {
                print("✅ User status updated: \(isOnline ? "online" : "offline")")
            }
        }
    }
    
    func signOut() {
        print("👋 === SIGNING OUT ===")
        updateUserStatus(isOnline: false)
        clearStoredCredentials()
        currentUser = nil
        isAuthenticated = false
        print("✅ User signed out successfully")
    }
    
    // Manual debug method - call this from your UI to see current state
    func debugCurrentState() {
        print("=== 🔧 CURRENT AUTH STATE ===")
        print("isAuthenticated: \(isAuthenticated)")
        print("isLoading: \(isLoading)")
        print("currentUser: \(currentUser?.name ?? "nil")")
        print("Thread: \(Thread.isMainThread ? "Main" : "Background")")
        debugUserDefaults()
        print("=== 🔧 END AUTH STATE ===")
    }
    
    // Force clear everything for testing
    func resetForTesting() {
        print("🧪 === RESETTING FOR TESTING ===")
        clearStoredCredentials()
        currentUser = nil
        isAuthenticated = false
        isLoading = false
        print("🧪 Reset complete")
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
        // Find and update in local array first
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].updatedAt = Date()
            
            // Update status based on completion
            tasks[index].status = tasks[index].isCompleted ? .completed : .todo
            
            let updatedTask = tasks[index]
            
            // Update in Firestore
            if let taskId = updatedTask.id {
                let updates: [String: Any] = [
                    "isCompleted": updatedTask.isCompleted,
                    "updatedAt": Timestamp(date: updatedTask.updatedAt),
                    "status": updatedTask.status.rawValue
                ]
                
                db.collection("tasks").document(taskId).updateData(updates) { [weak self] error in
                    if let error = error {
                        print("Error updating task: \(error)")
                        // Revert local changes if Firestore update fails
                        DispatchQueue.main.async {
                            if let index = self?.tasks.firstIndex(where: { $0.id == task.id }) {
                                self?.tasks[index].isCompleted.toggle()
                                self?.tasks[index].status = self?.tasks[index].isCompleted == true ? .completed : .todo
                            }
                        }
                    } else {
                        print("Task completion status updated successfully")
                    }
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
    func loadGroupMembers(for group: TaskGroup, completion: @escaping (TaskGroup) -> Void) {
        guard !group.memberIDs.isEmpty else {
            completion(group)
            return
        }
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: group.memberIDs)
            .getDocuments { snapshot, error in
                var updatedGroup = group
                if let documents = snapshot?.documents {
                    updatedGroup.members = documents.compactMap { try? $0.data(as: User.self) }
                }
                completion(updatedGroup)
            }
    }
    
    
    // Update fetchGroups method:
    func fetchGroups(for userId: String) {
        db.collection("groups")
            .whereField("memberIDs", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching groups: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let groups = documents.compactMap { try? $0.data(as: TaskGroup.self) }
                
                // Load members for each group
                let dispatchGroup = DispatchGroup()
                var updatedGroups: [TaskGroup] = []
                
                for group in groups {
                    dispatchGroup.enter()
                    self?.loadGroupMembers(for: group) { updatedGroup in
                        updatedGroups.append(updatedGroup)
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self?.groups = updatedGroups
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
    // Updated joinGroupWithInviteCode method for TaskViewModel
    func joinGroupWithInviteCode(_ inviteCode: String, completion: @escaping (Result<TaskGroup, Error>) -> Void) {
        // Get current user from AuthenticationViewModel
        // Since we can't access it directly, we'll get the current user ID from UserDefaults or Firebase Auth
        guard let currentUserData = UserDefaults.standard.data(forKey: "currentUser"),
              let decodedUserStorage = try? JSONDecoder().decode(UserForStorage.self, from: currentUserData),
              let userId = decodedUserStorage.id else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let currentUser = User(from: decodedUserStorage)
        
        db.collection("groups")
            .whereField("inviteCode", isEqualTo: inviteCode.uppercased())
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])))
                    return
                }
                
                do {
                    var group = try document.data(as: TaskGroup.self)
                    
                    // Check if user is already a member
                    if group.memberIDs.contains(userId) {
                        completion(.failure(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "Already a member"])))
                        return
                    }
                    
                    // Add user to group
                    group.memberIDs.append(userId)
                    group.members.append(currentUser)
                    
                    // Update Firestore
                    let groupRef = document.reference
                    groupRef.updateData([
                        "memberIDs": FieldValue.arrayUnion([userId])
                    ]) { updateError in
                        if let updateError = updateError {
                            completion(.failure(updateError))
                            return
                        }
                        
                        // Update local groups array
                        DispatchQueue.main.async {
                            if let index = self?.groups.firstIndex(where: { $0.id == group.id }) {
                                self?.groups[index] = group
                            } else {
                                self?.groups.append(group)
                            }
                            
                            // Create a notification for group admin
                            let notification = Notification(
                                title: "New Member Joined",
                                message: "\(currentUser.name) joined your group \"\(group.name)\"",
                                type: .groupInvite,
                                recipientID: group.adminID,
                                senderID: userId
                            )
                            self?.createNotification(notification)
                            
                            completion(.success(group))
                        }
                    }
                    
                } catch {
                    completion(.failure(error))
                }
            }
    }
    func getGroupInviteLink(for group: TaskGroup) -> String? {
        guard let groupId = group.id else { return nil }
        
        // Create a deep link format - you'll need to set up Firebase Dynamic Links separately
        // This is a simplified version
        return "taskapp://join?code=\(group.inviteCode)&groupId=\(groupId)"
    }
    
    func assignTaskToUser(_ task: Task, userId: String, currentUserName: String) {
        guard let taskId = task.id else {
            print("❌ Cannot assign task: no task ID")
            return
        }
        
        print("📋 Assigning task '\(task.title)' to user: \(userId)")
        
        // Update the task with new assignee
        let updates: [String: Any] = [
            "assignedTo": userId,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("tasks").document(taskId).updateData(updates) { [weak self] error in
            if let error = error {
                print("❌ Error assigning task: \(error)")
                return
            }
            
            print("✅ Task assigned successfully")
            
            // Update local task
            DispatchQueue.main.async {
                if let index = self?.tasks.firstIndex(where: { $0.id == taskId }) {
                    self?.tasks[index].assignedTo = userId
                    self?.tasks[index].updatedAt = Date()
                }
            }
            
            // Create notification for the assigned user (if not assigning to self)
            if userId != task.createdBy {
                self?.createTaskAssignmentNotification(
                    taskId: taskId,
                    taskTitle: task.title,
                    assignedToUserId: userId,
                    assignedByUserId: task.createdBy,
                    assignedByUserName: currentUserName
                )
            }
        }
    }
    private func createTaskAssignmentNotification(
        taskId: String,
        taskTitle: String,
        assignedToUserId: String,
        assignedByUserId: String,
        assignedByUserName: String
    ) {
        let notification = Notification(
            title: "New Task Assigned",
            message: "\(assignedByUserName) assigned you a task: \(taskTitle)",
            type: .taskAssigned,
            recipientID: assignedToUserId,
            senderID: assignedByUserId
        )
        
        var notificationWithDetails = notification
        notificationWithDetails.relatedTaskID = taskId
        
        createNotification(notificationWithDetails)
        
        print("📧 Assignment notification created:")
        print("   - To: \(assignedToUserId)")
        print("   - Task: \(taskTitle)")
        print("   - From: \(assignedByUserName)")
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
    // Function to create notifications
    func createNotification(_ notification: Notification) {
        do {
            let notificationData = try Firestore.Encoder().encode(notification)
            db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    print("Error creating notification: \(error)")
                }
            }
        } catch {
            print("Error encoding notification: \(error)")
        }
    }
    
    // Function to fetch user notifications
    func fetchNotifications(for userId: String, completion: @escaping ([Notification]) -> Void) {
        db.collection("notifications")
            .whereField("recipientID", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 30) // Limit to recent notifications
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error)")
                    completion([])
                    return
                }
                
                let notifications = snapshot?.documents.compactMap { try? $0.data(as: Notification.self) } ?? []
                completion(notifications)
            }
    }
    
    // Function to fetch all tasks assigned to a user, including group tasks
    func fetchAllUserTasks(for userId: String) {
        print("🔍 Fetching all tasks for user: \(userId)")
        
        // Create a more reliable task fetching system
        
        // 1. Listen to tasks directly assigned to the user
        let personalTasksListener = db.collection("tasks")
            .whereField("assignedTo", isEqualTo: userId)
            .addSnapshotListener { [weak self] personalSnapshot, error in
                if let error = error {
                    print("❌ Error fetching personal tasks: \(error)")
                    return
                }
                
                let personalTasks = personalSnapshot?.documents.compactMap {
                    try? $0.data(as: Task.self)
                } ?? []
                
                print("📝 Found \(personalTasks.count) personal tasks")
                
                // Update tasks immediately with personal tasks
                DispatchQueue.main.async {
                    // Remove old personal tasks and add new ones
                    self?.tasks.removeAll { $0.assignedTo == userId }
                    self?.tasks.append(contentsOf: personalTasks)
                    self?.sortTasks()
                }
            }
        
        // 2. Also listen to tasks in groups where user is a member
        // First get user's groups
        let groupsListener = db.collection("groups")
            .whereField("memberIDs", arrayContains: userId)
            .addSnapshotListener { [weak self] groupSnapshot, error in
                if let error = error {
                    print("❌ Error fetching user groups: \(error)")
                    return
                }
                
                let userGroups = groupSnapshot?.documents.compactMap {
                    try? $0.data(as: TaskGroup.self)
                } ?? []
                
                // Update groups first
                DispatchQueue.main.async {
                    self?.groups = userGroups
                }
                
                // Get group IDs for task fetching
                let groupIds = userGroups.compactMap { $0.id }
                
                if !groupIds.isEmpty {
                    // Listen to all tasks in user's groups
                    let groupTasksListener = self?.db.collection("tasks")
                        .whereField("groupID", in: groupIds)
                        .addSnapshotListener { [weak self] groupTaskSnapshot, error in
                            if let error = error {
                                print("❌ Error fetching group tasks: \(error)")
                                return
                            }
                            
                            let groupTasks = groupTaskSnapshot?.documents.compactMap {
                                try? $0.data(as: Task.self)
                            } ?? []
                            
                            print("👥 Found \(groupTasks.count) group tasks")
                            
                            DispatchQueue.main.async {
                                // Remove old group tasks and add new ones
                                self?.tasks.removeAll { task in
                                    groupIds.contains(task.groupID ?? "")
                                }
                                self?.tasks.append(contentsOf: groupTasks)
                                self?.sortTasks()
                            }
                        }
                }
            }
    }
    private func sortTasks() {
        tasks.sort { task1, task2 in
            // Incomplete tasks first
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted
            }
            
            // Then by priority (urgent first)
            if task1.priority != task2.priority {
                return task1.priority.sortOrder > task2.priority.sortOrder
            }
            
            // Then by due date (soonest first)
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            
            // Tasks with due dates come before those without
            if task1.dueDate != nil && task2.dueDate == nil {
                return true
            }
            if task1.dueDate == nil && task2.dueDate != nil {
                return false
            }
            
            // Finally by creation date (newest first)
            return task1.createdAt > task2.createdAt
        }
    }
    func getUserName(for userId: String?) -> String? {
        guard let userId = userId else { return nil }
        
        // First check if user is in any loaded groups
        for group in groups {
            if let member = group.members.first(where: { $0.id == userId }) {
                return member.name
            }
        }
        
        // Otherwise return a placeholder
        return "User"
    }
    
    func getGroup(for groupId: String?) -> TaskGroup? {
        guard let groupId = groupId else { return nil }
        return groups.first(where: { $0.id == groupId })
    }
    
    func getAllUsers(completion: @escaping ([User]) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                completion([])
                return
            }
            
            let users = snapshot?.documents.compactMap { try? $0.data(as: User.self) } ?? []
            completion(users)
        }
    }
    func startListening(for userId: String) {
        // Listen to all tasks user has access to
        fetchAllUserTasks(for: userId)
        
        // Listen to user's groups
        fetchGroups(for: userId)
        
        // Listen to notifications
        listenToNotifications(for: userId)
    }
    
    func listenToNotifications(for userId: String) {
        db.collection("notifications")
            .whereField("recipientID", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { snapshot, error in
                // Handle new notifications
            }
    }
    
}
