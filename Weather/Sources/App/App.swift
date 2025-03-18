import SwiftMCP
import Foundation
import Hummingbird

@main
struct App {
    static func main() throws {
        let weather = WeatherMCPServer()
        
        do {
            while true {
                // Add signal handler for SIGINT (Ctrl+C)
                signal(SIGINT) { _ in
                    print("\nShutting down server...")
                    Foundation.exit(0)
                }
                
                guard let input = extractInput() else { continue }
                let request = try decode(input: input)
                if let response = weather.handleRequest(request) {
                    let data = try JSONEncoder().encode(response)
                    let json = String(data: data, encoding: .utf8)!
                    print(json)
                    fflush(stdout)
                }
            }
        } catch {
            fputs("ERROR: \(error.localizedDescription)", stderr)
        }
    }
    
    static func extractInput() -> Data? {
        guard let input = readLine(), !input.isEmpty, let data = input.data(using: .utf8) else { return nil }
        return data
    }
    
    static func decode(input data: Data) throws -> JSONRPCRequest {
        try JSONDecoder().decode(JSONRPCRequest.self, from: data)
    }
}
