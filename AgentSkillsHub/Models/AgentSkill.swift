//
//  AgentSkill.swift
//  AgentSkillHub
//
//  Created by ZhiYou on 2026/2/2.
//

import Foundation
import SwiftData

@Model
class AgentSkill: Identifiable, Codable, Hashable, CustomStringConvertible {
    var id: String
    var name: String
    var desc: String
    var stars: Int64
    var githubUrl: String?
    var updatedAt: Int64
    var sourceProvider: String  // "Skills.sh" or "SkillsMP"
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case desc
        case stars
        case githubUrl
        case updatedAt
        case sourceProvider
    }
    
    var formattedStars: String {
        if stars >= 1000000 {
            return String(format: "%.1fM", Double(stars) / 1000000)
        } else if stars >= 1000 {
            return String(format: "%.1fk", Double(stars) / 1000)
        }
        return "\(stars)"
    }
    
    var formattedUpdatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(updatedAt)))
    }
    
    
    init(id: String, name: String, desc: String, stars: Int64, githubUrl: String?, updatedAt: Int64, sourceProvider: String = "Skills.sh") {
        self.id = id
        self.name = name
        self.desc = desc
        self.stars = stars
        self.githubUrl = githubUrl
        self.updatedAt = updatedAt
        self.sourceProvider = sourceProvider
    }
    
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.desc = try container.decode(String.self, forKey: .desc)
        self.stars = try container.decode(Int64.self, forKey: .stars)
        self.githubUrl = try container.decodeIfPresent(String.self, forKey: .githubUrl)
        self.updatedAt = try container.decode(Int64.self, forKey: .updatedAt)
        self.sourceProvider = try container.decode(String.self, forKey: .sourceProvider)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.desc, forKey: .desc)
        try container.encode(self.stars, forKey: .stars)
        try container.encodeIfPresent(self.githubUrl, forKey: .githubUrl)
        try container.encode(self.updatedAt, forKey: .updatedAt)
        try container.encode(self.sourceProvider, forKey: .sourceProvider)
    }
    
    var description: String {
        return """
        id: \(id)
        name: \(name)
        description: \(desc)
        stars: \(stars)
        githubUrl: \(githubUrl ?? "")
        updateAt: \(updatedAt)
        sourceProvider: \(sourceProvider)
        """
    }
}
