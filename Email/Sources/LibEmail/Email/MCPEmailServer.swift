//
//  IMAPEmailServer.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-22.
//

import SwiftMCP
import SwiftMail
import Foundation


@MCPServer(name: "Email Server", version: "0.0.1")
public actor MCPEmailServer {
    private let configuration: Configuration
    private let server: IMAPServer
        
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.server = IMAPServer(
            host: configuration.host,
            port: configuration.port,
            numberOfThreads: 1
        )
    }
    
    public func setup() async throws {
        try await conenct()
        try await login()
    }
    
    public func conenct() async throws {
        try await server.connect()
    }
    
    public func disconnect() async throws {
        try await server.disconnect()
    }
    
    public func login() async throws {
        try await server.login(
            username: configuration.username,
            password: configuration.password
        )
    }
        
    @MCPTool(description: "Fetches the subject line of your last email")
    public func fetchLastEmail() async throws -> String {
        let specialFolders = try await server.listSpecialUseMailboxes()
        
        guard let inbox = specialFolders.inbox else {
            throw MCPEmailServer.Errors.failedToFetchInbox
        }
        
        let mailboxStatus = try await selectInbox(from: inbox)
        
        return try await fetchLatestSubject(from: mailboxStatus)
    }
    
    
    @MCPTool(description: "Fetch unseen emails with pdf attachments from receipts mailbox")
    public func fetchEmailsFromReceiptsMailbox() async throws -> [Message] {
        guard let receiptsMailbox = try await server.listMailboxes().receipts else {
            throw MCPEmailServer.Errors.failedToFetchReceiptsMailbox
        }
            
        let status = try await selectInbox(from: receiptsMailbox)
        return try await self
            .getEmailsWithAttachments(from: status)
//            .map {
//                .init(message: $0)
//            }
    }
    
    public func downloadPDFAttachment(from email: Message) async throws -> URL {
        // Find the PDF attachment in the email parts
        guard let pdfPart = email.parts.first(where: { part in
            part.filename?.hasSuffix(".pdf") == true
        }) else {
            throw Errors.missingAttachment
        }
        
        // Get the documents directory URL
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw Errors.failedToLoadFile
        }
        
        // Create the destination URL with the attachment's filename
        let destinationURL = documentsURL.appending(path: pdfPart.filename ?? "attachment.pdf")

        let decoded = try GmailPDFMessagePartDecoder.decode(pdfPart)
        try decoded.write(to: destinationURL, options: [.atomic])
        
        return destinationURL
    }
    
    // Is utf8 the right encoding?
//    let pdfDataString = String(data: pdfPart.data, encoding: .utf8)!
//    pdfDataString
//        .replacingOccurrences(of: "+", with: "-")
//        .replacingOccurrences(of: "_", with: "/")
//        .data(using: .utf8)
//        
//    let decoded = Data(base64Encoded: pdfDataString,  options: .ignoreUnknownCharacters)!
//    
//    // Write the attachment data to the file
//    // try pdfPart.data.write(to: destinationURL, options: [.atomic])
//    try decoded.write(to: destinationURL, options: [.atomic])
    
    // MARK: Search Tools
//    @MCPTool(description: "Searches your inbox for unseen emails from a given sender in the last number of days (defaults to 7)")
//    package func search(from sender: String, inLastNumberOfDays: Int = 7) async throws -> [EmailMessage] {
//        var criteria: [SearchCriteria] = [
//            .unseen,
//            .from(sender),
//        ]
//        
//        if let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -inLastNumberOfDays, to: .now) {
//            criteria.append(.since(sevenDaysAgo))
//        }
//        
//        return try await performSearchOnSpecialUseMailBoxes(
//            on: "inbox",
//            with: .init(criterias: criteria)
//        )
//        .map { .init(message: $0) }
//    }
    
//    private func performSearchOnSpecialUseMailBoxes(on name: String, with criteria: SearchableCriteria) async throws -> [Message] {
//        let specialFolders = try await server.listSpecialUseMailboxes()
//        guard let mailbox = specialFolders.first(where: { $0.name.localizedStandardContains(name) }) else {
//            throw MCPEmailServer.Errors.failedToFetchRequestedMailbox(name)
//        }
//        
//        _ = try await server.selectMailbox(mailbox.name)
//        let messagesSet: MessageIdentifierSet<SequenceNumber> = try await server.search(
//            criteria: criteria.criterias
//        )
//        
//        return try await server.fetchMessages(using: messagesSet)
//    }
        
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
    public struct EmailMessage: Sendable, Codable {
        public struct Attachment: Codable, Sendable {
            public enum FileType: Codable, Sendable {
                case pdf
            }
            
            public var filename: String
            public var type: FileType
            public var data: Data
        }
        
        public let subject: String
        public let rawText: String?
        public let htmlText: String?
        public let attachment: Attachment?
        
        public init(message: Message) {
            self.subject = message.subject
            self.rawText = message.textBody
            self.htmlText = message.htmlBody
            self.attachment = message
                .attachments
                .filter { $0.contentType == "application" && $0.contentSubtype == "pdf" }
                .map { part in
                    return Attachment(
                        filename: part.suggestedFilename(),
                        type: .pdf,
                        data: part.data
                    )
                }
                .first
        }
    }
}

extension MCPEmailServer {
    // NOTE: This is needed becuase `SearchCriteria` is not sendable based on the current SwiftMail package version
//    struct SearchableCriteria: Sendable {
//        let criterias: [SwiftMail.SearchCriteria]
//    }
    
    private func getEmailsWithAttachments(from mailbox: Mailbox.Status) async throws(Errors) -> [Message] {
        guard let latest = mailbox.latest(10) else {
            throw .failedToFetchLatest
        }
        
        do {
            return try await server
                .fetchMessages(using: latest)
                .filter {
                    $0.attachments.count > 0 &&
                    $0.attachments.contains { $0.contentType == "application" && $0.contentSubtype == "pdf" }
                }
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
    public struct Configuration {
        var host: String
        var username: String
        var password: String
        var port: Int
    }
    
    public enum Errors: Error {
        case failedToLoadFile
        case missingAttachment
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
