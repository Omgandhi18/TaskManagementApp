import SwiftUI

struct GroupInviteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Join Group")) {
                    TextField("Enter Invite Code", text: $inviteCode)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: joinGroup) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Join Group")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(inviteCode.isEmpty || isLoading)
                }
            }
            .navigationTitle("Join Group")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func joinGroup() {
        isLoading = true
        errorMessage = nil
        
        taskViewModel.joinGroupWithInviteCode(inviteCode.uppercased()) { result in
            isLoading = false
            
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}