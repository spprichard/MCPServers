import LibEmail
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "email",
        abstract: """
        MCP Server which provides access to your email.
        Capable of using 2 different transport layers
        1. Stdio
        ```bash
        App stdio
        ```
        2. HTTP Server-Sent Events
        ```bash
        App http
        """,
        subcommands: [
            StdioCommand.self,
            HTTPSSECommand.self
        ],
        defaultSubcommand: HTTPSSECommand.self
    )
}
