//
//  GmailTaskManagerApp.swift
//  GmailTaskManager
//
//  Created by Young Joong on 11/10/25.
//

import SwiftUI
import GoogleSignIn

@main
struct GmailTaskManagerApp: App {
    @StateObject private var gmailService = GmailService()

    init() {
        NSLog("🚀🚀🚀 APP STARTED 🚀🚀🚀")
        print("🚀 GmailTaskManager app initialized")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(gmailService)
                .onAppear {
                    NSLog("🟢🟢🟢 MAIN VIEW APPEARED 🟢🟢🟢")
                    print("🟢 MainView appeared")
                }
                .onOpenURL { url in
                    NSLog("🔗🔗🔗 RECEIVED URL: %@", url.absoluteString)
                    print("🔗 Received URL: \(url)")
                    // Google Sign-In URL만 처리
                    if url.scheme?.hasPrefix("com.googleusercontent.apps") == true {
                        let handled = GIDSignIn.sharedInstance.handle(url)
                        NSLog("🔗 URL handled: %d", handled)
                        print("🔗 URL handled: \(handled)")
                    }
                }
        }
    }
}
