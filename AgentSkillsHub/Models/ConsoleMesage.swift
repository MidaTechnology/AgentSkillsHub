//
//  ConsoleMesage.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import Foundation

struct ConsoleMesage: Identifiable, Hashable,Codable {
    var id: UUID = UUID()
    var type: String
    var message: String
    
    var isError: Bool {
        type == "error"
    }
    
    enum CodingKeys: CodingKey {
        case id
        case type
        case message
    }
    
    init(id: UUID = UUID(), type: String, message: String) {
        self.id = id
        self.type = type
        self.message = message
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.type, forKey: .type)
        try container.encodeIfPresent(self.message, forKey: .message)
    }
}
