//
//  ContentView.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppStore.self) private var appStore
    var body: some View {
        TabView(selection: Binding(get: { appStore.selectedTab }, set: { appStore.selectedTab = $0 })) {
            Tab("Skills", systemImage: "circle.hexagonpath.fill", value: 0) {
                SkillsView()
            }
            Tab("Console", systemImage: "play.desktopcomputer", value: 1) {
                TerminalView()
            }
        }
        .tabViewStyle(.automatic)
        .labelStyle(.iconOnly)
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
        .frame(width: 960, height: 560)
}
