//
//  BasicCalculator.swift
//  Calculator
//
//  Created by Steven Prichard on 2025-03-19.
//

import SwiftMCP
import Foundation

@MCPServer(name: "BasicCalculator", version: "0.0.2")
public class BasicCalculator {
    public init() {}
    
    @MCPTool(description: "Adds two integers together")
    public func add(a: Int, b: Int) -> Int {
        a + b
    }
}
