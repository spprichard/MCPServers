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

package struct EmailCommand: AsyncParsableCommand {
    package init() {}
    
    package func run() async throws {
        let serverConfiguration = try EmailConfigurationProvider.loadDotEnvConfiguration()
         
        let emailServer = MCPEmailServer(configuration: serverConfiguration)
        try await emailServer.setup()
        
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
