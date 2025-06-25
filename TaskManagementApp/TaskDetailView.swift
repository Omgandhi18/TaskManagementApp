import SwiftUI
import FirebaseFirestore

struct TaskDetailView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var task: Task
    @State private var isEditing = false
    @State private var showingAssignSheet = false
    @State private var showingDeleteConfirmation = false
    
    init(task: Task) {
        _task = State(initialValue: task)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task header
                HStack {
                    Circle()
                        .fill(Color(hex: task.color) ?? .blue)
                        .frame(width: 16, height: 16)
                    
                    Text(task.priority.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(for: task.priority).opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(task.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(for: task.status))
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
                        
                        Button(action: {
                            showingAssignSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.blue)
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
                    
                    if task.createdAt != task.updatedAt {
                        HStack {
                            Label("Updated", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(task.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Task status controls
                VStack(alignment: .center, spacing: 12) {
                    Text("Update Status")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack(spacing: 12) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Button(action: {
                                updateTaskStatus(status)
                            }) {
                                Text(status.rawValue)
                                    .font(.caption)
                                    .fontWeight(task.status == status ? .bold : .medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(task.status == status ? 
                                                  statusColor(for: status) : 
                                                  statusColor(for: status).opacity(0.1))
                                    )
                                    .foregroundColor(task.status == status ? .white : statusColor(for: status))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
        .sheet(isPresented: $showingAssignSheet) {
            AssignTaskView(task: task) { updatedTask in
                task = updatedTask
            }
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
    
    private func updateTaskStatus(_ status: TaskStatus) {
        var updatedTask = task
        updatedTask.status = status
        updatedTask.updatedAt = Date()
        
        taskViewModel.updateTask(updatedTask)
        task = updatedTask
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo: return .gray
        case .inProgress: return .blue
        case .completed: return .green
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
    @State private var priority: TaskPriority
    @State private var color: String
    @State private var showDatePicker = false
    
    init(task: Binding<Task>) {
        self._task = task
        self._title = State(initialValue: task.wrappedValue.title)
        self._description = State(initialValue: task.wrappedValue.description)
        self._dueDate = State(initialValue: task.wrappedValue.dueDate)
        self._priority = State(initialValue: task.wrappedValue.priority)
        self._color = State(initialValue: task.wrappedValue.color)
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
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(["FF5733", "33A8FF", "33FF57", "F333FF", "FFFC33", "FF33A2", "33FFF6", "8C33FF", "FF8C33", "33FF8C"], id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .blue)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: color == colorHex ? 2 : 0)
                                )
                                .onTapGesture {
                                    color = colorHex
                                }
                        }
                    }
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
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.dueDate = dueDate
        updatedTask.priority = priority
        updatedTask.color = color
        updatedTask.updatedAt = Date()
        
        taskViewModel.updateTask(updatedTask)
        task = updatedTask
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