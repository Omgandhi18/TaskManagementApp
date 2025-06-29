import SwiftUI
import FirebaseFirestore

struct TaskDetailView: View {
    let taskId: String // Change from task object to task ID
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingReassignSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    // Computed property to get the current task from TaskViewModel
    var task: Task? {
        taskViewModel.tasks.first { $0.id == taskId }
    }
    
    var assigneeName: String {
        guard let task = task else { return "Unknown User" }
        if let currentUser = authViewModel.currentUser,
           task.assignedTo == currentUser.id {
            return "You"
        }
        return taskViewModel.getUserName(for: task.assignedTo) ?? "Unknown User"
    }
    
    var group: TaskGroup? {
        guard let task = task else { return nil }
        return taskViewModel.getGroup(for: task.groupID)
    }
    
    var isGroupTask: Bool {
        task?.groupID != nil
    }
    
    var canReassign: Bool {
        guard let task = task,
              let group = group,
              let currentUser = authViewModel.currentUser else { return false }
        
        // Allow reassignment if user is admin or the task creator
        return group.adminID == currentUser.id || task.createdBy == currentUser.id
    }
    
    var isAssignedToCurrentUser: Bool {
        task?.assignedTo == authViewModel.currentUser?.id
    }
    
    var body: some View {
        Group {
            if let task = task {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Task Status Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Button(action: {
                                    taskViewModel.toggleTaskCompletion(task)
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                        .font(.title)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .strikethrough(task.isCompleted)
                                    
                                    Text(task.status.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(task.isCompleted ? .green : .orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            (task.isCompleted ? Color.green : Color.orange)
                                                .opacity(0.2)
                                        )
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Task Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            if !task.description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.headline)
                                    Text(task.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Priority
                            HStack {
                                Text("Priority")
                                    .font(.headline)
                                Spacer()
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(task.priority.color)
                                        .frame(width: 12, height: 12)
                                    Text(task.priority.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            // Due Date
                            if let dueDate = task.dueDate {
                                HStack {
                                    Text("Due Date")
                                        .font(.headline)
                                    Spacer()
                                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(dueDate < Date() ? .red : .primary)
                                }
                            }
                            
                            // Assignment Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assignment")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(isAssignedToCurrentUser ? .blue : .orange)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Assigned to: \(assigneeName)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        if let group = group {
                                            Text("in \(group.name)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Reassign button for group tasks
                                    if isGroupTask && canReassign {
                                        Button("Reassign") {
                                            showingReassignSheet = true
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Created info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Created")
                                    .font(.headline)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("By: \(taskViewModel.getUserName(for: task.createdBy) ?? "Unknown")")
                                            .font(.subheadline)
                                        Text("On: \(task.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Task Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                showingEditSheet = true
                            }) {
                                Label("Edit Task", systemImage: "pencil")
                            }
                            
                            if isGroupTask && canReassign {
                                Button(action: {
                                    showingReassignSheet = true
                                }) {
                                    Label("Reassign Task", systemImage: "person.2")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                showingDeleteAlert = true
                            }) {
                                Label("Delete Task", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingReassignSheet) {
                    // Fixed: Pass the task directly since we know it exists here
                    ReassignTaskView(task: task)
                }
                .sheet(isPresented: $showingEditSheet) {
                    // Fixed: Pass the task directly since we know it exists here
                    EditTaskView(task: task)
                }
                .alert("Delete Task", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        // Fixed: Use the task directly since we know it exists here
                        taskViewModel.deleteTask(task)
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete this task? This action cannot be undone.")
                }
            } else {
                // Show loading or error state if task is not found
                VStack {
                    Text("Task not found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Go Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Reassign Task View
struct ReassignTaskView: View {
    let task: Task
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedAssignee: User?
    
    var group: TaskGroup? {
        taskViewModel.getGroup(for: task.groupID)
    }
    
    var availableAssignees: [User] {
        group?.members ?? []
    }
    
    var currentAssignee: User? {
        availableAssignees.first { $0.id == task.assignedTo }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Assignment")) {
                    if let current = currentAssignee {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(current.name)
                                    .font(.subheadline)
                                Text(current.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if current.isOnline {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                
                Section(header: Text("Reassign to")) {
                    ForEach(availableAssignees) { member in
                        Button(action: {
                            selectedAssignee = member
                        }) {
                            HStack {
                                Image(systemName: selectedAssignee?.id == member.id ? "checkmark.circle.fill" : "person.circle")
                                    .foregroundColor(selectedAssignee?.id == member.id ? .green : .blue)
                                
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if member.isOnline {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                        .disabled(member.id == task.assignedTo)
                        .opacity(member.id == task.assignedTo ? 0.5 : 1.0)
                    }
                }
            }
            .navigationTitle("Reassign Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reassign") {
                        reassignTask()
                    }
                    .disabled(selectedAssignee == nil || selectedAssignee?.id == task.assignedTo)
                }
            }
        }
        .onAppear {
            selectedAssignee = currentAssignee
        }
    }
    
    private func reassignTask() {
        guard let assignee = selectedAssignee,
              let assigneeId = assignee.id,
              let currentUser = authViewModel.currentUser else { return }
        
        taskViewModel.assignTaskToUser(task, userId: assigneeId, currentUserName: currentUser.name)
        
        // Create notification for the new assignee if it's not the current user
        if assigneeId != currentUser.id {
            let notification = Notification(
                title: "Task Reassigned",
                message: "\(currentUser.name) assigned you a task: \(task.title)",
                type: .taskAssigned,
                recipientID: assigneeId,
                senderID: currentUser.id
            )
            var notificationWithTask = notification
            notificationWithTask.relatedTaskID = task.id
            notificationWithTask.relatedGroupID = task.groupID
            
            taskViewModel.createNotification(notificationWithTask)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Placeholder Edit Task View
struct EditTaskView: View {
    let task: Task
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Task Feature")
                Text("Coming Soon...")
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
