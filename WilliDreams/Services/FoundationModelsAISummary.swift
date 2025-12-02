//
//  FoundationModelsAISummary.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/4/25.
//

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
@MainActor
struct AISummary: Sendable {
    static func summarizeDreams(dreamsToAnalyze: [Dream]) async throws -> String {
        var prompt: String = "Summarize the following dreams: \n"
        
        for dreamToAnalyze in dreamsToAnalyze {
            prompt += "Title: \(dreamToAnalyze.name) \n"
            prompt += "Description: \(dreamToAnalyze.dreamDescription) \n"
        }
        
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        
        return response.content
    }
}

#endif
