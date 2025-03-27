//
//  IMAPEmailServer.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-22.
//

import SwiftMCP
import Foundation
@preconcurrency import SwiftIMAP
@preconcurrency import SwiftMailCore

@_exported import SwiftIMAP

@MCPServer(name: "Email Server", version: "0.0.1")
package actor MCPEmailServer {
    private let configuration: Configuration
    private let server: IMAPServer
        
    package init(configuration: Configuration) {
        self.configuration = configuration
        self.server = IMAPServer(
            host: configuration.host,
            port: configuration.port,
            numberOfThreads: 1
        )
    }
    
    package func setup() async throws {
        try await conenct()
        try await login()
    }
    
    package func conenct() async throws {
        try await server.connect()
    }
    
    package func disconnect() async throws {
        try await server.disconnect()
    }
    
    package func login() async throws {
        try await server.login(
            username: configuration.username,
            password: configuration.password
        )
    }
        
    @MCPTool(description: "Fetches the subject line of your last email")
    package func fetchLastEmail() async throws -> String {
        let specialFolders = try await server.listSpecialUseMailboxes()
        
        guard let inbox = specialFolders.inbox else {
            throw MCPEmailServer.Errors.failedToFetchInbox
        }
        
        let mailboxStatus = try await selectInbox(from: inbox)
        
        return try await fetchLatestSubject(from: mailboxStatus)
    }
    
    
    @MCPTool(description: "Fetch unseen emails with pdf attachments from receipts mailbox")
    func fetchEmailsFromReceiptsMailbox() async throws -> [EmailMessage] {
        guard let receiptsMailbox = try await server.listMailboxes().receipts else {
            throw MCPEmailServer.Errors.failedToFetchReceiptsMailbox
        }
            
        let status = try await selectInbox(from: receiptsMailbox)
        return try await self
            .getEmailsWithAttachments(from: status)
            .map { .init(message: $0) }
    }
    
    // MARK: Search Tools
    @MCPTool(description: "Searches your inbox for unseen emails from a given sender in the last number of days (defaults to 7)")
    package func search(from sender: String, inLastNumberOfDays: Int = 7) async throws -> [EmailMessage] {
        var criteria: [SearchCriteria] = [
            .unseen,
            .from(sender),
        ]
        
        if let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -inLastNumberOfDays, to: .now) {
            criteria.append(.since(sevenDaysAgo))
        }
        
        return try await performSearchOnSpecialUseMailBoxes(
            on: "inbox",
            with: .init(criterias: criteria)
        )
        .map { .init(message: $0) }
    }
    
    private func performSearchOnSpecialUseMailBoxes(on name: String, with criteria: SearchableCriteria) async throws -> [Message] {
        let specialFolders = try await server.listSpecialUseMailboxes()
        guard let mailbox = specialFolders.first(where: { $0.name.localizedStandardContains(name) }) else {
            throw MCPEmailServer.Errors.failedToFetchRequestedMailbox(name)
        }
        
        _ = try await server.selectMailbox(mailbox.name)
        let messagesSet: MessageIdentifierSet<SequenceNumber> = try await server.search(
            criteria: criteria.criterias
        )
        
        return try await server.fetchMessages(using: messagesSet)
    }
        
    // Currently only throws a `BAD` error
//    @MCPTool(description: "Searches recent unseen emails for subjects containing provided string")
//    package func searchEmail(subject: String) async throws -> [Message] {
//        try await self.search(
//            for: .init(
//                criterias: [
//                    .recent,
//                    .unseen,
//                    .subject(subject)
//                ]
//            )
//        )
//    }
    
//    // Currently only throws a `BAD` error
//    @MCPTool(description: "Searched all emails for a provided term")
//    package func searchEmailByTerm(term: String) async throws -> [Message] {
//        try await self.search(
//            for: .init(
//                criterias: [
//                    .recent,
//                    .unseen,
//                    .keyword(term)
//                ]
//            )
//        )
//    }
}

extension MCPEmailServer {
    package struct EmailMessage: Sendable, Codable {
        enum Attachment: Codable {
            case pdf(Data)
        }
        
        let subject: String
        let rawText: String?
        let htmlText: String?
        let attachment: Attachment?
        
        package init(message: Message) {
            self.subject = message.subject
            self.rawText = message.textBody
            self.htmlText = message.htmlBody
            self.attachment = message
                .attachments
                .filter { $0.contentType == "application" && $0.contentSubtype == "pdf" }
                .map { part in
                    return Attachment.pdf(part.decodedContent())
                }
                .first
        }
    }
}

extension MCPEmailServer {
    // NOTE: This is needed becuase `SearchCriteria` is not sendable based on the current SwiftMail package version
    struct SearchableCriteria: Sendable {
        let criterias: [SwiftIMAP.SearchCriteria]
    }
    
    private func getEmailsWithAttachments(from mailbox: Mailbox.Status) async throws(Errors) -> [Message] {
        guard let latest = mailbox.latest(10) else {
            throw .failedToFetchLatest
        }
        
        do {
            return try await server
                .fetchMessages(using: latest)
                // .filter { $0.attachments.count > 0 && $0.attachments.contains { $0.contentType == "application/pdf" } }
                .filter { $0.attachments.count > 0 }
        } catch {
            throw .unknown(error)
        }
    }
    
    private func fetchLatestSubject(from mailboxStatus: Mailbox.Status) async throws(MCPEmailServer.Errors) -> String {
        do {
            return try await fetchLatest(with: mailboxStatus)
        } catch {
            throw .failedToFetchLatestMessageSubject
        }
    }
    
    // TODO: Refactor to return more than just subject
    private func fetchLatest(_ count: Int = 1, with mailboxStatus: Mailbox.Status) async throws -> String {
        if let latestMessageSet = mailboxStatus.latest(count) {
            let latestHeader = try await server.fetchHeaders(using: latestMessageSet)
            guard let latest = latestHeader.first else {
                throw MCPEmailServer.Errors.failedToFetchLatestMessageSubject
            }
            
            return latest.subject
        }
        
        throw MCPEmailServer.Errors.failedToFetchLatestMessageSubject
    }

    
    private func selectInbox(from info: Mailbox.Info) async throws(MCPEmailServer.Errors) -> Mailbox.Status {
        do {
            return try await server.selectMailbox(info.name)
        } catch {
            throw .failedToSelectInbox(error)
        }
    }
}

extension MCPEmailServer {
    package struct Configuration {
        var host: String
        var username: String
        var password: String
        var port: Int
    }
    
    package enum Errors: Error {
        case unknown(Error)
        case failedToFetchLatest
        case invalidConfiguration
        case failedToConnect(Error)
        case failedToLogin(Error)
        case failedToFetchInbox
        case failedToListSpecialUseMailboxes(Error)
        case failedToSelectInbox(Error)
        case failedToFetchLatestMessageSubject
        case failedToFetchHeaders(Error)
        case failedToFetchReceiptsMailbox
        case failedToFetchRequestedMailbox(String)
    }
}
