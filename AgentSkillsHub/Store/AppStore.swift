//
//  AppStore.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import Foundation

@Observable
class AppStore {
    private var skillsService = SkillsService(
        baseURL: Constants.SKILLS_MP_API_URL,
        apiKey: Constants.SKILLS_MP_API_KEY
    )
    private var terminalService = TerminalService(
        url: Constants.workspaceURL,
        apiKey: Constants.ANTHROPIC_API_KEY
    )

    // 默认技能页面
    var selectedTab: Int = 0
    // 提示词
    var prompt: String = ""
    
    func getAllSkills(_ query: String) async throws -> [AgentSkill] {
        if query.isEmpty {
            return try await skillsService.fetchPopularSkills()
        } else {
            return try await skillsService.searchSkills(query: query)
        }
    }
    
    func getInstalledSkills() -> [AgentSkill] {
        return terminalService.installedSkills()
    }
    
    func installSkill(_ skill: AgentSkill) {
        guard let githubUrl = skill.githubUrl, !githubUrl.isEmpty else {
            return
        }
        self.selectedTab = 1
        self.prompt = "下载技能 \(githubUrl) 到 \(terminalService.skillsURL.path())"
    }
    
    func executeWithPrompt(_ prompt: String, onMessage: ((_ message: ConsoleMesage) -> Void)? = nil) async throws {
        try await terminalService.execute(prompt, onMessage: onMessage)
    }
    
    func executeWithInput(_ input: String) async throws {
        try await terminalService.input(input)
    }
}
