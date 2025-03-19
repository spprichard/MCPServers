//
//  CalculatorCommand.swift
//  Calculator
//
//  Created by Steven Prichard on 2025-03-19.
//

import SwiftMCP
import Foundation
import ArgumentParser

public struct StdioCommand: AsyncParsableCommand {
    public init() {}
    
    public func run() async throws {
        let calculator = BasicCalculator()
        
        fputs("MCP Server \(calculator.serverName) (\(calculator.serverVersion)) started with Stdio transport\n", stderr)
        let transport = StdioTransport(server: calculator)
        
        try await transport.run()
    }
}
