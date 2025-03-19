import Foundation
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "App",
        abstract: """
        MCP Server which provides weather forcasts
        Currently only supports Stdio transport
        """,
        subcommands: [
            StdioCommand.self
        ],
        defaultSubcommand: StdioCommand.self
    )
}
