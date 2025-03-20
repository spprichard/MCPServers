import LibServer
import ArgumentParser

@main
struct ServerCommand: AsyncParsableCommand {    
    static let configuration: CommandConfiguration = .init(
        commandName: "server",
        abstract: "Start an HTTP server with Server-Sent Events (SSE) support",
        subcommands: [
            SSEServerCommand.self
        ],
        defaultSubcommand: SSEServerCommand.self
    )
}
