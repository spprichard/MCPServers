//
//  StdioCommand.swift
//  Weather
//
//  Created by Steven Prichard on 2025-03-18.
//

import NIOCore
import SwiftMCP
import Foundation
import ArgumentParser

public struct StdioCommand: AsyncParsableCommand {
    public init() {}
    
    public func run() async throws {
        let weatherServer = WeatherMCPServer()
        let transport = StdioTransport(server: weatherServer)
        do {
            try await transport.run()
        }
        catch let error as IOError {
            let message = """
            I/O Error: \(error)
            Code: \(error.errnoCode)\n
            """
            fputs(message, stderr)
            Foundation.exit(1)
        }
        catch let error as ChannelError {
            let message = """
            Channel Error: \(error.localizedDescription)\n
            """
            fputs(message, stderr)
            Foundation.exit(1)
        }
        catch {
            let message = """
            Error: \(error.localizedDescription)\n
            """
            fputs(message, stderr)
            Foundation.exit(1)
        }
    }
}

