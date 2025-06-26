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
    
    let preselectedGroup: TaskGroup?
    
    init(preselectedGroup: TaskGroup? = nil) {
        self.preselectedGroup = preselectedGroup
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
                }
            }
        }
    }
    
    func saveTask() {
        guard let currentUser = authViewModel.currentUser,
              let userId = currentUser.id else { return }
        
        let newTask = Task(
            title: title,
            description: description,
            isCompleted: false,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            assignedTo: userId,
            groupID: selectedGroup?.id,
            createdBy: userId,
            createdAt: Date(),
            tags: []
        )
        
        taskViewModel.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
}
