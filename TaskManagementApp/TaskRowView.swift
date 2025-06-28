//
//  TaskRowView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI
// MARK: - TaskRowView.swift
struct TaskRowView: View {
    let task: Task
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var isCompleted: Bool
    @State private var currentStatus: TaskStatus
    
    init(task: Task) {
        self.task = task
        self._isCompleted = State(initialValue: task.isCompleted)
        self._currentStatus = State(initialValue: task.status)
    }
    
    var body: some View {
        NavigationLink(destination: TaskDetailView(task: task)) {
            HStack {
                Button(action: {
                    // Update local state immediately for instant UI feedback
                    isCompleted.toggle()
                    currentStatus = isCompleted ? .completed : .todo
                    
                    // Then update the view model
                    taskViewModel.toggleTaskCompletion(task)
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(isCompleted)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        // Priority indicator
                        Text(task.priority.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(task.priority.color.opacity(0.2))
                            .foregroundColor(task.priority.color)
                            .cornerRadius(4)
                        
                        // Status indicator
                        Text(currentStatus.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isCompleted ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                            .foregroundColor(isCompleted ? .green : .blue)
                            .cornerRadius(4)
                        
                        // Due date
                        if let dueDate = task.dueDate {
                            Text(dueDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle()) // Prevents NavigationLink from affecting button styling
        .padding(.vertical, 2)
        .opacity(isCompleted ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
        .onReceive(taskViewModel.$tasks) { tasks in
            // Update local state when the task changes in the view model
            if let updatedTask = tasks.first(where: { $0.id == task.id }) {
                isCompleted = updatedTask.isCompleted
                currentStatus = updatedTask.status
            }
        }
    }
}
