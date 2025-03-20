//
//  ClientApp.swift
//  SSEExample
//
//  Created by Steven Prichard on 2025-03-20.
//

import Client
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

@main
struct ClientApp {
    static func main() async throws {
        let client = Client(
            serverURL: URL(string: "http://localhost:8080")!,
            transport: URLSessionTransport()
        )
        
        let response = try await client.ping(.init(body: .json(.init())))
        print("ℹ️ Response: \(response)")
    }
}
