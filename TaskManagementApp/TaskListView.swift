//
//  TaskListView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//
import SwiftUI
// MARK: - Task List View
struct TaskListView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case high = "High Priority"
    }
    
    var filteredTasks: [Task] {
        let tasks = taskViewModel.tasks
        switch selectedFilter {
        case .all:
            return tasks.sorted { task1, task2 in
                // Sort by completion status first, then by priority, then by due date
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                if task1.priority.sortOrder != task2.priority.sortOrder {
                    return task1.priority.sortOrder > task2.priority.sortOrder
                }
                if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                }
                return task1.createdAt > task2.createdAt
            }
        case .pending:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        case .high:
            return tasks.filter { $0.priority == .high }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Task List
                List {
                    ForEach(filteredTasks, id: \.id) { task in
                        TaskRowView(task: task)
                            .id(task.id) // Force view update when task changes
                    }
                    .onDelete(perform: deleteTasks)
                }
                .refreshable {
                    // Pull to refresh
                    if let userId = authViewModel.currentUser?.id {
                        taskViewModel.startListening(for: userId)
                    }
                }
            }
            .navigationTitle("My Tasks (\(filteredTasks.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        taskViewModel.showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $taskViewModel.showingAddTask) {
                AddTaskView()
            }
        }
    }
    
    func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            taskViewModel.deleteTask(filteredTasks[index])
        }
    }
}
