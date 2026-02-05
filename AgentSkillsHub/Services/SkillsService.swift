//
//  SkillsService.swift
//  AgentSkillHub
//
//  Created by ZhiYou on 2026/2/2.
//

import Foundation

enum SkillsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from Skills API"
        case .notFound: return "Skill not found"
        case .installationFailed(let msg): return "Installation failed: \(msg)"
        }
    }
}

struct SkillsMPResponse<T: Codable>: Codable {
    var success: Bool
    var data: T?
}

struct SkillsMPSearchResponse: Codable {
    let skills: [SkillsMPSkill]
}

struct SkillsMPSkill: Codable {
    let id: String
    let name: String
    let description: String
    let stars: Int64
    let githubUrl: String?
    let updatedAt: Int64
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, stars, updatedAt
        case githubUrl = "githubUrl"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.stars = try container.decodeIfPresent(Int64.self, forKey: .stars) ?? 0
        self.githubUrl = try container.decodeIfPresent(String.self, forKey: .githubUrl)
        self.updatedAt = try container.decode(Int64.self, forKey: .updatedAt)
    }
    
    func toAgentSkill() -> AgentSkill {
        AgentSkill(
            id: id,
            name: name,
            desc: description,
            stars: stars,
            githubUrl: githubUrl,
            updatedAt: updatedAt,
            sourceProvider: "skillsmp.com"
        )
    }
}

class SkillsService {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    
    // Cache
    private var cachedSkills: [AgentSkill] = []
    private var hasFetched = false
    
    init(baseURL: URL, apiKey: String) {
        self.session = .shared
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    /// Search for skills by query
    func searchSkills(query: String, page: Int = 1, limit: Int = 50, sortBy: String = "stars") async throws -> [AgentSkill] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&page=\(page)&limit=\(limit)&sortBy=\(sortBy)") else {
            throw SkillsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SkillsError.invalidResponse
        }
        
        let searchResponse = try JSONDecoder().decode(SkillsMPResponse<SkillsMPSearchResponse>.self, from: data)
        guard let skills = searchResponse.data?.skills else {
            return []
        }
        return skills.map { $0.toAgentSkill() }
    }
    
    /// Fetch popular skills
    func fetchPopularSkills() async throws -> [AgentSkill] {
        guard !hasFetched else { return cachedSkills }
        
        print("🎯 SkillsMPService: Fetching popular skills...")
        
        var allSkills: [String: AgentSkill] = [:]
        
        // Fetch with different queries
        let popularQueries = ["ai"]
        for query in popularQueries {
            do {
                let skills = try await searchSkills(query: query, limit: 100)
                for skill in skills {
                    allSkills[skill.id] = skill
                }
            } catch {
                print("⚠️ SkillsMPService: Query '\(query)' failed: \(error.localizedDescription)")
            }
        }
        
        cachedSkills = Array(allSkills.values).sorted { $0.stars > $1.stars }
        hasFetched = true
        
        print("✅ SkillsMPService: Loaded \(cachedSkills.count) skills")
        
        return cachedSkills
    }
    
    func getAllSkills() -> [AgentSkill] {
        return cachedSkills
    }
    
    func clearCache() {
        cachedSkills.removeAll()
        hasFetched = false
    }
}
