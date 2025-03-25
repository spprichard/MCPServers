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

extension Array where Element == Mailbox.Info {
    /// Find the first mailbox matching the string `receipts`
    public var receipts: Element? {
        guard let mailbox = first(where: { $0.name.lowercased() == "receipts" }) else {
            return nil
        }
        
        return mailbox
    }
}

@MCPServer(name: "Email Server", version: "0.0.1")
package actor MCPEmailServer {
    private let configuration: Configuration
    private let emailServer: IMAPServer
        
    package init(configuration: Configuration) {
        self.configuration = configuration
        self.emailServer = IMAPServer(
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
        try await emailServer.connect()
    }
    
    package func disconnect() async throws {
        try await emailServer.disconnect()
    }
    
    package func login() async throws {
        try await emailServer.login(
            username: configuration.username,
            password: configuration.password
        )
    }
        
    @MCPTool(description: "Fetches the subject line of your last email")
    package func fetchLastEmail() async throws(MCPEmailServer.Errors) -> String {
        let specialFolders = try await getMailBoxInfo()
        
        guard let inbox = specialFolders.inbox else {
            throw .failedToFetchInbox
        }
        
        let mailboxStatus = try await selectInbox(from: inbox)
        
        return try await fetchLatestSubject(from: mailboxStatus)
    }
    
    @MCPTool(description: "Searches your inbox for unseen emails from a given sender")
    package func search(sender: String) async throws -> String {
        let specialFolders = try await getMailBoxInfo()
        guard let inbox = specialFolders.inbox else {
            return "Failed to fetch inbox"
        }
        
        let _ = try await emailServer.selectMailbox(inbox.name)
        let unreadMessagesSet: MessageIdentifierSet<SequenceNumber> = try await emailServer.search(
            criteria: [
                .unseen,
                .from(sender)
            ]
        )
        return "Found \(unreadMessagesSet.count) unread messages"
    }
    
    @MCPTool(description: "Fetch unseen emails with pdf attachments from receipts mailbox")
    func fetchEmailsFromReceiptsMailbox() async throws -> [EmailMessage] {
        guard let receiptsMailbox = try await emailServer.listMailboxes().receipts else {
            throw MCPEmailServer.Errors.failedToFetchReceiptsMailbox
        }
            
        let status = try await selectInbox(from: receiptsMailbox)
        return try await self
            .getEmailsWithAttachments(from: status)
            .map { .init(message: $0) }
    }
    
    struct EmailMessage: Sendable, Codable {
        enum Attachment: Codable {
            case pdf(Data)
        }
        
        let subject: String
        let rawText: String?
        let htmlText: String?
        let attachment: Attachment?
        
        init(message: Message) {
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

    
    // NOTE: This is needed becuase `SearchCriteria` is not sendable based on the current SwiftMail package version
    struct SearhableCriteria: Sendable {
        let criterias: [SwiftIMAP.SearchCriteria]
    }
    
    private func getEmailsWithAttachments(from mailbox: Mailbox.Status) async throws(Errors) -> [Message] {
        guard let latest = mailbox.latest(10) else {
            throw .failedToFetchLatest
        }
        
        do {
            return try await emailServer
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
            let latestHeader = try await emailServer.fetchHeaders(using: latestMessageSet)
            guard let latest = latestHeader.first else {
                throw MCPEmailServer.Errors.failedToFetchLatestMessageSubject
            }
            
            return latest.subject
        }
        
        throw MCPEmailServer.Errors.failedToFetchLatestMessageSubject
    }
    
    private func search(for criteria: SearhableCriteria) async throws -> [Message] {
        let ids: MessageIdentifierSet<UID> = try await emailServer.search(
            criteria: criteria.criterias
        )
        
        if !ids.isEmpty {
            return  try await emailServer
                .fetchMessages(using: ids)
        }
        
        return []
    }
    
    
    private func selectInbox(from info: Mailbox.Info) async throws(MCPEmailServer.Errors) -> Mailbox.Status {
        do {
            return try await emailServer.selectMailbox(info.name)
        } catch {
            throw .failedToSelectInbox(error)
        }
    }
    
    private func getMailBoxInfo() async throws(MCPEmailServer.Errors) -> [Mailbox.Info] {
        do {
            return try await emailServer.listSpecialUseMailboxes()
        } catch {
            throw .failedToListSpecialUseMailboxes(error)
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
    }
}
