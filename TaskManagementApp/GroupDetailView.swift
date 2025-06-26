import SwiftUI

struct GroupDetailView: View {
    let group: TaskGroup
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var isAddingTask = false
    @State private var isShowingShareSheet = false
    
    var groupTasks: [Task] {
        taskViewModel.tasks.filter { $0.groupID == group.id }
    }
    
    var body: some View {
        List {
            Section(header: Text("Group Info")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(.headline)
                    
                    Text(group.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(Color(hex: group.color) ?? .blue)
                            .frame(width: 16, height: 16)
                        
                        Text("Created on \(group.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Members (\(group.members.count))")) {
                ForEach(group.members) { member in
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(member.name)
                                .font(.subheadline)
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
            }
            
            Section(header: Text("Tasks (\(groupTasks.count))")) {
                if groupTasks.isEmpty {
                    Text("No tasks in this group")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(groupTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskRowView(task: task)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    isShowingShareSheet = true
                }) {
                    Label("Invite Members", systemImage: "person.badge.plus")
                }
            }
        }
        .navigationTitle("Group Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isAddingTask = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let inviteLink = taskViewModel.getGroupInviteLink(for: group) {
                ShareSheet(items: [inviteLink])
            }
        }
    }
}

// Helper ShareSheet view
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
