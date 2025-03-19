import Foundation
import LibWeather
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "App",
        abstract: """
        MCP Server which provides weather forcasts
        Currently only supports Stdio transport
        Example: Mesa, Arizona - Latitude: 33.415184, Longitude: -111.831474
        """,
        subcommands: [
            StdioCommand.self
        ],
        defaultSubcommand: StdioCommand.self
    )
}
