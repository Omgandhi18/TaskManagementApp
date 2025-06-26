import SwiftUI

struct GroupInviteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var joinedGroupName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Join Group")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter the invite code shared by a group admin:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Invite Code (e.g., ABC123XY)", text: $inviteCode)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: inviteCode) { newValue in
                                // Auto-format to uppercase and limit to 8 characters
                                inviteCode = String(newValue.uppercased().prefix(8))
                                // Clear error when user types
                                if errorMessage != nil {
                                    errorMessage = nil
                                }
                            }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button(action: joinGroup) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Joining...")
                            } else {
                                Image(systemName: "person.badge.plus")
                                Text("Join Group")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(inviteCode.isEmpty || isLoading ? .secondary : .white)
                    }
                    .disabled(inviteCode.isEmpty || isLoading)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(inviteCode.isEmpty || isLoading ? Color.gray.opacity(0.3) : Color.blue)
                    )
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to get an invite code:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("• Ask a group admin to share their group's invite code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Invite codes are 8 characters long (letters and numbers)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showingSuccess) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("You've successfully joined \"\(joinedGroupName)\"!")
            }
        }
    }
    
    private func joinGroup() {
        guard !inviteCode.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        taskViewModel.joinGroupWithInviteCode(inviteCode.uppercased()) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let group):
                    joinedGroupName = group.name
                    showingSuccess = true
                case .failure(let error):
                    if error.localizedDescription.contains("404") {
                        errorMessage = "Invalid invite code. Please check and try again."
                    } else if error.localizedDescription.contains("409") {
                        errorMessage = "You're already a member of this group."
                    } else if error.localizedDescription.contains("401") {
                        errorMessage = "Please sign in to join a group."
                    } else {
                        errorMessage = "Failed to join group. Please try again."
                    }
                }
            }
        }
    }
}
