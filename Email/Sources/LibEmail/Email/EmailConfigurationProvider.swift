//
//  EmailConfigurationProvider.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-25.
//

import Foundation
import SwiftDotenv

package enum EmailConfigurationProvider {
    package static func loadDotEnvConfiguration() throws(MCPEmailServer.Errors) -> MCPEmailServer.Configuration {
        guard case let .string(host) = Dotenv["IMAP_HOST"],
              case let .integer(port) = Dotenv["IMAP_PORT"],
              case let .string(username) = Dotenv["IMAP_USERNAME"],
              case let .string(password) = Dotenv["IMAP_PASSWORD"] else {
            print("❌ Missing or invalid IMAP credentials in .env file")
            throw .invalidConfiguration
        }
        
        return .init(
            host: host,
            username: username,
            password: password,
            port: port
        )
    }
}
