import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "gateway",
        abstract: """
        A `gateway` MCP Server, which aggregates access to other MCP servers.
        Transport: HTTP Server-Sent Events
        ```bash
        gateway run
        """,
        subcommands: [
            RunCommand.self
        ],
        defaultSubcommand: RunCommand.self
    )
}
