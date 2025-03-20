//
//  SSEServer.swift
//  SSEExample
//
//  Created by Steven Prichard on 2025-03-20.
//

import ArgumentParser
@preconcurrency import SwiftMCP

@MCPServer(name: "SSEServer", version: "0.0.1")
actor SSEServer {
    init() {}
    
    @MCPTool(description: "A tool to test if this is working")
    func ping() -> String {
        return "pong"
    }

    
}

public struct SSEServerCommand: AsyncParsableCommand {
    public init() {}
    
    @Option(name: .long, help: "The hostname to listen on")
    var hostname: String = "127.0.0.1"
    
    @Option(name: .long, help: "The port to listen on")
    var port: Int = 8080
    
    @Option(name: .long, help: "Bearer token for authorization")
    var token: String?
    
    public func run() async throws {
        let server = SSEServer()
        
        let transport = HTTPSSETransport(
            server: server,
            host: hostname,
            port: port
        )
        transport.serveOpenAPI = true // TODO: Accept this as a flag
        
        try await transport.run()
    }
}
