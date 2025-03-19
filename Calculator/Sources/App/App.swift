import Foundation
import LibCalculator
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "calculator",
        abstract: """
        MCP Server which provides basic calculator operations
        Currently only supports Stdio transport
        """,
        subcommands: [
            StdioCommand.self
        ],
        defaultSubcommand: StdioCommand.self
    )
}
