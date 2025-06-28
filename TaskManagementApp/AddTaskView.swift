//
//  AddTaskView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//
import SwiftUI

// MARK: - Fixed AddTaskView.swift
struct AddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Task.Priority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedGroup: TaskGroup?
    @State private var selectedAssignee: User?
    
    let preselectedGroup: TaskGroup?
    
    init(preselectedGroup: TaskGroup? = nil) {
        self.preselectedGroup = preselectedGroup
    }
    
    // Get available assignees based on selected group
    var availableAssignees: [User] {
        if let group = selectedGroup {
            return group.members
        }
        return []
    }
    
    // Check if we should show assignment section
    var shouldShowAssignment: Bool {
        selectedGroup != nil && !availableAssignees.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Settings")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                if !taskViewModel.groups.isEmpty {
                    Section(header: Text("Assign to Group")) {
                        Picker("Group", selection: $selectedGroup) {
                            Text("Personal Task").tag(nil as TaskGroup?)
                            ForEach(taskViewModel.groups) { group in
                                Text(group.name).tag(group as TaskGroup?)
                            }
                        }
                        .onChange(of: selectedGroup) { _ in
                            // Reset assignee when group changes
                            selectedAssignee = nil
                        }
                    }
                }
                
                // Assignment section - only show for group tasks
                if shouldShowAssignment {
                    Section(header: Text("Assign to Member")) {
                        Picker("Assigned to", selection: $selectedAssignee) {
                            Text("Assign to me").tag(authViewModel.currentUser as User?)
                            ForEach(availableAssignees.filter { $0.id != authViewModel.currentUser?.id }) { member in
                                HStack {
                                    Image(systemName: "person.circle")
                                        .foregroundColor(.blue)
                                    Text(member.name)
                                }.tag(member as User?)
                            }
                        }
                        
                        // Show selected assignee info
                        if let assignee = selectedAssignee {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Assigned to: \(assignee.name)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(assignee.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if assignee.isOnline {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let preselectedGroup = preselectedGroup {
                    selectedGroup = preselectedGroup
                    // Auto-assign to current user when creating group task
                    selectedAssignee = authViewModel.currentUser
                }
            }
        }
    }
    
    func saveTask() {
        guard let currentUser = authViewModel.currentUser,
              let userId = currentUser.id else { return }
        
        // Determine who the task should be assigned to
        let assigneeId: String
        if let selectedGroup = selectedGroup {
            // For group tasks, use selected assignee or default to current user
            assigneeId = selectedAssignee?.id ?? userId
        } else {
            // For personal tasks, always assign to current user
            assigneeId = userId
        }
        
        let newTask = Task(
            title: title,
            description: description,
            isCompleted: false,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            assignedTo: assigneeId,
            groupID: selectedGroup?.id,
            createdBy: userId,
            createdAt: Date(),
            tags: []
        )
        
        taskViewModel.addTask(newTask)
        
        // Create notification if task is assigned to someone else
        if assigneeId != userId, let assignee = selectedAssignee {
            let notification = Notification(
                title: "New Task Assigned",
                message: "\(currentUser.name) assigned you a task: \(title)",
                type: .taskAssigned,
                recipientID: assigneeId,
                senderID: userId
            )
            var notificationWithTask = notification
            notificationWithTask.relatedTaskID = newTask.id
            notificationWithTask.relatedGroupID = selectedGroup?.id
            
            taskViewModel.createNotification(notificationWithTask)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}
