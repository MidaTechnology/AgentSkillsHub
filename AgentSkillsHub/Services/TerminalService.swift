//
//  TerminalService.swift
//  AgentSkillsHub
//
//  Created by ZhiYou on 2026/2/2.
//

import Foundation

class TerminalService {
    private var url: URL
    private var apiKey: String
    private var process: Process?
    
    var skillsURL: URL { url.appending(path: ".claude/skills") }
    
    init(url: URL, apiKey: String) {
        self.url = url
        self.apiKey = apiKey
    }
    
    private func parseSkillMarkdown(_ content: String) -> AgentSkill? {
        guard content.hasPrefix("---") else { return nil }
        let components = content.components(separatedBy: "---")
        guard components.count >= 3 else { return nil }
        
        let metadataContent = components[1]
        var nameOpt: String?
        var descriptionOpt: String?
        metadataContent.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { return }
            
            if trimmed.hasPrefix("name:") {
                nameOpt = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .init(charactersIn: "\"'"))
            } else if trimmed.hasPrefix("description:") {
                descriptionOpt = String(trimmed.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .init(charactersIn: "\"'"))
            }
        }
        guard let name = nameOpt, let desc = descriptionOpt else {
            return nil
        }
        return AgentSkill(
            id: UUID().uuidString,
            name: name,
            desc: desc,
            stars: 0,
            githubUrl: nil,
            updatedAt: 0
        )
    }
    
    func installedSkills() -> [AgentSkill] {
        guard FileManager.default.fileExists(atPath: skillsURL.path()) else {
            return []
        }
        do {
            let skills = try FileManager.default.contentsOfDirectory(
                at: skillsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ).compactMap {
                let mdPath = $0.appending(path: "SKILL.md")
                if FileManager.default.fileExists(atPath: mdPath.path()),
                   let content = try? String(contentsOfFile: mdPath.path(), encoding: .utf8)
                {
                    return parseSkillMarkdown(content)
                }
                return nil
            }
            return skills
        } catch let error {
            debugPrint(error)
            return []
        }
    }
    
    func input(_ input: String) async throws {
        guard let inputData = input.data(using: .utf8) else {
            return
        }
        if let inputPipe = self.process?.standardInput as? Pipe {
            try inputPipe.fileHandleForWriting.write(contentsOf: inputData)
            try inputPipe.fileHandleForWriting.close()
        }
    }
    
    func execute(_ prompt: String, onMessage: ((_ message: ConsoleMesage) -> Void)? = nil) async throws {
        let executableURL = url.appending(path: ".venv/bin/python")
        let arguments = ["-u", "main.py", "\(prompt)"]
        
        var newEnvironment = ProcessInfo.processInfo.environment
        newEnvironment["PYTHONIOENCODING"] = "utf-8"
        newEnvironment["ANTHROPIC_API_KEY"] = self.apiKey
        if let envPath = newEnvironment["PATH"] {
            newEnvironment["PATH"] = "\(envPath):\(url.appending(path: ".venv/bin").path())"
        } else {
            newEnvironment["PATH"] = url.appending(path: ".venv/bin").path()
        }
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let inputPipe = Pipe()
        
        let process = Process()
        process.environment = newEnvironment
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = url
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.standardInput = inputPipe
        
        // Pipe
        let outputStream = createAsyncStream(from: outputPipe)
        let errorStream = createAsyncStream(from: errorPipe)
        // Run
        try process.run()
        self.process = process
        // Steam
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.processStream(outputStream, isError: false, onMessage: onMessage)
            }
            group.addTask {
                await self.processStream(errorStream, isError: true, onMessage: onMessage)
            }
        }
        // End
        process.waitUntilExit()
    }
    
    private func createAsyncStream(from pipe: Pipe) -> AsyncStream<String> {
        AsyncStream { continuation in
            pipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.isEmpty {
                    fileHandle.readabilityHandler = nil
                    continuation.finish()
                    return
                }
                
                if let string = String(data: data, encoding: .utf8) {
                    continuation.yield(string)
                }
            }
        }
    }
    
    private func processStream(_ stream: AsyncStream<String>, isError: Bool, onMessage: ((_ message: ConsoleMesage) -> Void)? = nil) async {
        for await output in stream {
            let type = isError ? "error: " : "output: "
            debugPrint("\(type)\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            DispatchQueue.main.async {
                onMessage?(ConsoleMesage(type: type, message: output.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
    }
}
