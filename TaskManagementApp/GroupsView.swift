//
//  GroupsView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI

// MARK: - Groups View
struct GroupsView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingJoinGroup = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(taskViewModel.groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupRowView(group: group)
                    }
                }
                .onDelete(perform: deleteGroups)
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingJoinGroup = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Join")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        taskViewModel.showingAddGroup = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $taskViewModel.showingAddGroup) {
                AddGroupView()
            }
            .sheet(isPresented: $showingJoinGroup) {
                GroupInviteView()
            }
        }
    }
    
    func deleteGroups(offsets: IndexSet) {
        for index in offsets {
            taskViewModel.deleteGroup(taskViewModel.groups[index])
        }
    }
}
