import SwiftUI
import FirebaseFirestore

struct TaskDetailView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var task: Task
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    init(task: Task) {
        _task = State(initialValue: task)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task header
                HStack {
                    Text(task.priority.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(for: task.priority).opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(task.isCompleted ? "Completed" : "Pending")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.isCompleted ? .green : .orange)
                        .cornerRadius(4)
                }
                .padding(.horizontal)
                
                // Task title and description
                VStack(alignment: .leading, spacing: 12) {
                    Text(task.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Task metadata
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Due Date", systemImage: "calendar")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(task.dueDate?.formatted(date: .long, time: .shortened) ?? "No due date")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Label("Assigned To", systemImage: "person")
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        if let assignedToName = taskViewModel.getUserName(for: task.assignedTo) {
                            Text(assignedToName)
                                .fontWeight(.medium)
                        } else {
                            Text("Unassigned")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let group = taskViewModel.getGroup(for: task.groupID) {
                        HStack {
                            Label("Group", systemImage: "folder")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(group.name)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Label("Created", systemImage: "clock")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Toggle completion button
                Button(action: {
                    taskViewModel.toggleTaskCompletion(task)
                    task.isCompleted.toggle()
                }) {
                    Label(task.isCompleted ? "Mark as Pending" : "Mark as Complete",
                          systemImage: task.isCompleted ? "circle" : "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(task.isCompleted ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { isEditing = true }) {
                        Label("Edit Task", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        Label("Delete Task", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: $task)
        }
        .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                taskViewModel.deleteTask(task)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private func priorityColor(for priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

struct EditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Binding var task: Task
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date?
    @State private var priority: Task.Priority
    
    init(task: Binding<Task>) {
        self._task = task
        self._title = State(initialValue: task.wrappedValue.title)
        self._description = State(initialValue: task.wrappedValue.description)
        self._dueDate = State(initialValue: task.wrappedValue.dueDate)
        self._priority = State(initialValue: task.wrappedValue.priority)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: Binding(
                        get: { dueDate != nil },
                        set: { if !$0 { dueDate = nil } else if dueDate == nil { dueDate = Date() } }
                    ))
                    
                    if dueDate != nil {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Edit Task")
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
        }
    }
    
    private func saveTask() {
        task.title = title
        task.description = description
        task.dueDate = dueDate
        task.priority = priority
        
        taskViewModel.updateTask(task)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AssignTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    let task: Task
    let onAssign: (Task) -> Void
    
    @State private var selectedUserId: String?
    @State private var users: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading members...")
                } else {
                    List {
                        if users.isEmpty {
                            Text("No users available to assign")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(users) { user in
                                Button(action: {
                                    selectedUserId = user.id
                                }) {
                                    HStack {
                                        Image(systemName: "person.circle")
                                            .foregroundColor(.blue)
                                        
                                        VStack(alignment: .leading) {
                                            Text(user.name)
                                                .font(.subheadline)
                                            Text(user.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if user.id == task.assignedTo {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.green)
                                        } else if user.id == selectedUserId {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assign Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignTask()
                    }
                    .disabled(selectedUserId == nil || selectedUserId == task.assignedTo)
                }
            }
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        // If task is part of a group, get group members
        if let groupId = task.groupID, let group = taskViewModel.getGroup(for: groupId) {
            users = group.members
            isLoading = false
        } else {
            // For personal tasks or if group isn't loaded yet
            taskViewModel.getAllUsers { fetchedUsers in
                DispatchQueue.main.async {
                    users = fetchedUsers
                    isLoading = false
                }
            }
        }
    }
    
    private func assignTask() {
        guard let userId = selectedUserId else { return }
        
        var updatedTask = task
        updatedTask.assignedTo = userId
        updatedTask.updatedAt = Date()
        
        taskViewModel.updateTask(updatedTask)
        onAssign(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }
}


