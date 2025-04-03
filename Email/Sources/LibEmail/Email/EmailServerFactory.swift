//
//  EmailServerFactory.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-27.
//


public enum EmailServerFactory {
    public static func make() async throws -> MCPEmailServer {
        let serverConfiguration = try EmailConfigurationProvider.loadDotEnvConfiguration()
         
        let emailServer = MCPEmailServer(configuration: serverConfiguration)
        try await emailServer.setup()
        return emailServer
    }
}
