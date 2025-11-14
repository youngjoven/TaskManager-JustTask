//
//  MainView.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var gmailService: GmailService

    var body: some View {
        Group {
            if gmailService.isAuthenticated {
                LabelSelectionView(gmailService: gmailService)
                    .onAppear {
                        print("🟢 LabelSelectionView appeared")
                    }
            } else {
                LoginView(gmailService: gmailService)
                    .onAppear {
                        print("🔴 LoginView appeared, isAuthenticated: \(gmailService.isAuthenticated)")
                    }
            }
        }
        .onChange(of: gmailService.isAuthenticated) { newValue in
            print("🔄 isAuthenticated changed to: \(newValue)")
        }
    }
}

#Preview {
    MainView()
        .environmentObject(GmailService())
}
