import Logging
import SwiftMCP
import Foundation

@main
struct App {
    static func main() {
        stdio()
    }
    
    static func stdio() {
        let notesServer = FilesServer()
        var logger = Logger(label: "mcp.server.Notes")
        logger.logLevel = .debug
    
        do {
            while true {
                if let input = readLine(),
                   !input.isEmpty,
                   let data = input.data(using: .utf8)
                {
                    let request = try JSONDecoder().decode(SwiftMCP.JSONRPCRequest.self, from: data)
                    logger.debug("Recived request method: \n\(String(describing: request.method))")
    
                    // Handle the request
                    if let response = notesServer.handleRequest(request) {
    
                        let data = try JSONEncoder().encode(response)
                        let json = String(data: data, encoding: .utf8)!
    
                        // Print the response and flush immediately
                        print(json)
                        fflush(stdout)
                    }
                } else {
                    // If no input is available, sleep briefly and try again
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
        catch {
            fputs("\(error.localizedDescription)\n", stderr)
        }
    }
}



