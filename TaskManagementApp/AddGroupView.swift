//
//  AddGroupView.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//
import SwiftUI

// MARK: - Add Group View
struct AddGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#007AFF"
    
    let colors = ["#007AFF", "#FF3B30", "#FF9500", "#FFCC02", "#34C759", "#5856D6", "#AF52DE", "#FF2D92"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Group Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Group Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? .blue)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func createGroup() {
        guard let currentUser = authViewModel.currentUser,
              let userId = currentUser.id else { return }
        
        let newGroup = TaskGroup(
            name: name,
            description: description,
            members: [currentUser],
            adminID: userId,
            createdAt: Date(),
            color: selectedColor
        )
        
        taskViewModel.addGroup(newGroup)
        presentationMode.wrappedValue.dismiss()
    }
}
