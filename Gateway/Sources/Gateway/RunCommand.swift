//
//  RunCommand.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-27.
//

import SwiftMCP
import LibGateway
import MistralKit
import SwiftDotenv
import ArgumentParser

struct RunCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "run"
    )
    
    @Option(name: .long, help: "The port to listen on")
    var port: Int = 8080
    
    @Option(name: .long, help: "Bearer token for authorization")
    var token: String?
    
    package init() {}
    
    package func run() async throws {
        let childServers = try await GatewayServer.ServerFactory.make()
        guard case let .string(mistralAPIKey) = Dotenv["MISTRAL_API_KEY"] else {
            print("❌ Missing or invalid IMAP credentials in .env file")
            throw Errors.invalidConfiguration
        }
        
        let mistralClient = MistralClient(apiKey: mistralAPIKey)
        let gateway = GatewayServer(
            servers: childServers,
            mistralClient: mistralClient
        )
        
        defer {
            // Not sure if firing a task he is best practice...
            Task {
                try await gateway.disconnect()
            }
        }
        
        let httpServer = HTTPSSETransport(server: gateway, port: port)
        httpServer.serveOpenAPI = true
        registerAuthentication(for: httpServer)
        
        let signalHandler = SignalHandler(transport: httpServer)
        await signalHandler.setup()
        
        try await httpServer.run()
    }
    
    private func registerAuthentication(for transport: HTTPSSETransport) {
        if let requiredToken = token {
            transport.authorizationHandler = { token in
                authorize(token: token, requiredToken: requiredToken)
            }
        }
    }
    
    private func authorize(token: String?, requiredToken: String) -> HTTPSSETransport.AuthorizationResult {
        guard let token else {
            return .unauthorized("Missing bearer token")
        }
        
        guard requiredToken == token else {
            return .unauthorized("Invalid bearer token")
        }
        
        return .authorized
    }
    
    enum Errors: Error {
        case invalidConfiguration
    }
}
