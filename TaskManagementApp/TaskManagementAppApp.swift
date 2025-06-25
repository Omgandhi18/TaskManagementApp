//
//  TaskManagementAppApp.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle deep links
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Parse URL parameters
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path,
              components.scheme == "taskapp" else {
            return false
        }
        
        // Check if it's a group join link
        if path == "/join" {
            if let queryItems = components.queryItems {
                let codeItem = queryItems.first(where: { $0.name == "code" })
                if let inviteCode = codeItem?.value {
                    // Store the invite code to be used when app fully loads
                    UserDefaults.standard.set(inviteCode, forKey: "pendingInviteCode")
                    NotificationCenter.default.post(name: NSNotification.Name("ProcessInviteCode"), object: nil)
                    return true
                }
            }
        }
        
        return false
    }
}

@main
struct TaskManagementAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(taskViewModel)
                .onAppear {
                    // Listen for deep link notification
                    NotificationCenter.default.addObserver(forName: NSNotification.Name("ProcessInviteCode"), object: nil, queue: .main) { _ in
                        processPendingInviteCode()
                    }
                    
                    // Check for pending invite code from deep link
                    processPendingInviteCode()
                }
        }
    }
    
    private func processPendingInviteCode() {
        if authViewModel.isAuthenticated,
           let inviteCode = UserDefaults.standard.string(forKey: "pendingInviteCode") {
            // Clear the stored code
            UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
            
            // Join the group
            taskViewModel.joinGroupWithInviteCode(inviteCode) { _ in
                // Handle result if needed
            }
        }
    }
}
