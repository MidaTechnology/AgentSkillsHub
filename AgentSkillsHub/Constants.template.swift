//
//  Constants.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/3.
//

import Foundation

final class Constants {
    static let workspaceURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.appending(path: "my-skills")
    static let SKILLS_MP_API_URL = URL(string: "https://skillsmp.com/api/v1/skills")!
    static let SKILLS_MP_API_KEY = ""
    static let ANTHROPIC_API_KEY = ""
    
    static let prompts = [""]
}
