//
//  EmailComamnd.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-22.
//

import SwiftMCP
import SwiftIMAP
import Foundation
import SwiftDotenv
import ArgumentParser

package struct StdioCommand: AsyncParsableCommand {
    package static let configuration: CommandConfiguration = .init(
        commandName: "stdio"
    )
    
    package init() {}
    
    package func run() async throws {
        let emailServer = try await EmailServerFactory.make()
        
        defer {
            // Not sure if firing a task he is best practice...
            Task {
                try await emailServer.disconnect()
            }
        }
        
        let transport = StdioTransport(server: emailServer)
        try await transport.run()
    }
}
