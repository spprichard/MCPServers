//
//  EmailSearchTests.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-25.
//
import Testing
import SwiftDotenv
@testable import LibEmail

@Suite("Tests for searching emails")
struct EmailSearchTests {
    @Test func canPerformSearch() async throws {
        let serverConfiguration = try EmailConfigurationProvider.loadDotEnvConfiguration()
        let emailServer = MCPEmailServer(configuration: serverConfiguration)
        try await emailServer.setup()
        
        defer {
            // Not sure if firing a task he is best practice...
            Task {
                try await emailServer.disconnect()
            }
        }

        let result = try await emailServer.callTool(
            "search",
            arguments: [
                "sender" : "Github"
            ]
        )
        
        #expect(result as? String != "")
    }
}

