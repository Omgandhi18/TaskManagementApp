//
//  TaskManagementAppApp.swift
//  TaskManagementApp
//
//  Created by Om Gandhi on 25/06/25.
//

import SwiftUI

@main
struct TaskManagementAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(taskViewModel)
        }
    }
}
