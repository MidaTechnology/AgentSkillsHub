//
//  SkillsView.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import SwiftUI
import Combine

struct SkillsView: View {
    @Environment(AppStore.self) private var appStore
    
    @State private var searchText: String = ""
    @State private var searchTextSubject = PassthroughSubject<String, Never>()
    @State private var searchTextCancellables = Set<AnyCancellable>()
    
    @State private var selectedSkill: AgentSkill?
    @State private var skills: [AgentSkill] = []
    @State private var isLoading: Bool = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240))]) {
                ForEach(skills) { skill in
                    VStack(alignment:. leading, spacing: 12) {
                        Text(skill.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(height: 32, alignment: .top)
                        Text(skill.desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        HStack {
                            Text(skill.formattedUpdatedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 10)
                                    .foregroundStyle(Color.yellow)
                                Text(skill.formattedStars)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSkill = skill
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.background)
                        .strokeBorder(Color.gray.opacity(0.2))
                        .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 1, y: 1)
                )
            }
        }
        .contentMargins(.all, 12, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color.secondaryBackground)
        .searchable(text: $searchText, prompt: "Search skills")
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .foregroundStyle(Color.primary)
            }
        }
        .sheet(item: $selectedSkill) { skill in
            SkillView(skill: skill)
        }
        .onChange(of: searchText) { _, newValue in
            searchTextSubject.send(newValue)
        }
        .onAppear {
            setSearchSubject()
            getAgentSkills()
        }
        .onDisappear {
            removeSearchSubject()
        }
    }
    
    private func removeSearchSubject() {
        searchTextCancellables.forEach { $0.cancel() }
    }
    
    private func setSearchSubject() {
        searchTextSubject
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { _ in
                getAgentSkills()
            }
            .store(in: &searchTextCancellables)
    }
    
    private func getAgentSkills() {
        self.isLoading = true
        Task {
            do {
                let skills = try await appStore.getAllSkills(self.searchText)
                await MainActor.run {
                    self.skills = skills
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SkillsView()
        .environment(AppStore())
        .frame(width: 960, height: 560)
}
