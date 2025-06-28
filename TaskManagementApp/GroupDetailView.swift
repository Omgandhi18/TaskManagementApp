import SwiftUI

struct GroupDetailView: View {
    let group: TaskGroup
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isAddingTask = false
    @State private var showingInviteCode = false
    @State private var copiedToClipboard = false
    
    var groupTasks: [Task] {
        taskViewModel.tasks.filter { $0.groupID == group.id }
    }
    
    var isAdmin: Bool {
        authViewModel.currentUser?.id == group.adminID
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
            
            // Invite Code Section (only show to admins)
            if isAdmin {
                Section(header: Text("Invite Code")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share this code with others to invite them:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(group.inviteCode)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                        }
                        
                        Spacer()
                        
                        Button(action: copyInviteCode) {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                .foregroundColor(copiedToClipboard ? .green : .blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Members (\(group.members.count))")) {
                ForEach(group.members) { member in
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(member.name)
                                    .font(.subheadline)
                                
                                if member.id == group.adminID {
                                    Text("Admin")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
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
        }
        .navigationTitle("Group Details")
        .navigationBarTitleDisplayMode(.large)
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
    }
    
    private func copyInviteCode() {
        UIPasteboard.general.string = group.inviteCode
        copiedToClipboard = true
        
        // Reset the copied state after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedToClipboard = false
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
