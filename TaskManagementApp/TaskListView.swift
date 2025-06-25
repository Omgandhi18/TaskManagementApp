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
        switch selectedFilter {
        case .all:
            return taskViewModel.tasks
        case .pending:
            return taskViewModel.tasks.filter { !$0.isCompleted }
        case .completed:
            return taskViewModel.tasks.filter { $0.isCompleted }
        case .high:
            return taskViewModel.tasks.filter { $0.priority == .high }
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
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
            .navigationTitle("My Tasks")
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

