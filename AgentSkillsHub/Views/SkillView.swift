//
//  SkillView.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/3.
//

import SwiftUI

struct SkillView: View {
    @Environment(AppStore.self) private var appStore
    @Environment(\.dismiss) private var dissmiss
    @State var skill: AgentSkill
    
    var body: some View {
        VStack {
            VStack(alignment:. leading, spacing: 12) {
                HStack {
                    Text(skill.name)
                        .font(.title)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                Text(skill.desc)
                    .font(.body)
                    .foregroundStyle(.secondary)
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
                VStack(alignment:. leading, spacing: 0) {
                    Button {
                        viewAgentSkill()
                    } label: {
                        Label(skill.githubUrl ?? "", systemImage: "eye")
                            .labelIconToTitleSpacing(6)
                            .font(.headline)
                            .foregroundStyle(.accent)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        installAgentSkill()
                    } label: {
                        Label("Install", systemImage: "arrow.down")
                            .labelIconToTitleSpacing(6)
                            .font(.headline)
                            .foregroundStyle(.accent)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button {
                        dissmiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .padding(2)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.tertiary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(Color.background)
        .frame(minHeight: 240)
    }
    
    private func viewAgentSkill() {
        guard let githubUrl = skill.githubUrl, let url = URL(string: githubUrl) else {
            return
        }
         NSWorkspace.shared.open(url)
    }
    
    private func installAgentSkill() {
        dissmiss()
        appStore.installSkill(skill)
    }
}

#Preview {
    @Previewable @State var skill = AgentSkill(
        id: "anthropics-skills-skills-frontend-design-skill-md",
        name: "frontend-design",
        desc: "Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics.",
        stars: 645788999,
        githubUrl: "https://github.com/anthropics/skills/tree/main/skills/frontend-design",
        updatedAt: 1766254185,
        sourceProvider: "skillsmp.com"
    )
    SkillView(
        skill: skill
    )
    .environment(AppStore())

}
