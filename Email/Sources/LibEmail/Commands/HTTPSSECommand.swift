//
//  HTTPSSECommand.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-22.
//

import SwiftMCP
import SwiftIMAP
import Foundation
import SwiftDotenv
import ArgumentParser

package struct HTTPSSECommand: AsyncParsableCommand {
    package static let configuration: CommandConfiguration = .init(
        commandName: "http"
    )
    
    @Option(name: .long, help: "The port to listen on")
    var port: Int = 8080
    
    @Option(name: .long, help: "Bearer token for authorization")
    var token: String?
    
    package init() {}
    
    package func run() async throws {
        let emailServer = try await EmailServerFactory.make()
        
        defer {
            // Not sure if firing a task he is best practice...
            Task {
                try await emailServer.disconnect()
            }
        }
        
        let httpServer = HTTPSSETransport(server: emailServer, port: port)
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
}
