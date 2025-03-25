import LibEmail
import ArgumentParser

@main
struct App: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "email",
        abstract: """
        MCP Server which provides access to your email
        """,
        subcommands: [
            EmailCommand.self,
        ],
        defaultSubcommand: EmailCommand.self
    )
}


