//
//  AgentSkillsHubApp.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import SwiftUI
import SwiftData

@main
struct AgentSkillsHubApp: App {
    private let appStore = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appStore)
        }
    }
}
