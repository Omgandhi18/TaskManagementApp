//
//  GroupRowView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI

// MARK: - Group Row View
struct GroupRowView: View {
    let group: TaskGroup
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    var groupTasks: [Task] {
        taskViewModel.tasks.filter { $0.groupID == group.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: group.color) ?? .blue)
                    .frame(width: 12, height: 12)
                
                Text(group.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(group.members.count) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(group.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("\(groupTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(group.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
