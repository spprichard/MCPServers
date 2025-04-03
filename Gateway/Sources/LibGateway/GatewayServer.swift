//
//  GatewayServer.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-27.
//

import SwiftMCP
import LibEmail
import Foundation
import MistralKit
import SwiftMail

@MCPServer(name: "gateway", version: "0.0.1")
public actor GatewayServer {
    let servers: Servers
    let mistralClient: MistralAPI
    
    public init(servers: Servers, mistralClient: MistralAPI) {
        self.servers = servers
        self.mistralClient = mistralClient
    }
    
    package func disconnect() async throws {
        return 
    }
    
    @MCPTool(description: "Ping the gateway")
    func ping() async throws -> String {
        return "pong"
    }
    
    @MCPTool(description: "Test conencting to email")
    func testEmail() async throws -> String {
        try await servers.email.setup()
        return "ok"
    }
    
    @MCPTool(description: "Test saving an email attachment")
    func testSaveEmailAttachemnt() async throws -> String {
        try await servers.email.setup()
        let emails = try await servers.email.fetchEmailsFromReceiptsMailbox()
        guard let latestEmail = emails.first else {
            throw Errors.emailNotFound
        }
        // Download the PDF attachment
        let savedURL = try await servers.email.downloadPDFAttachment(from: latestEmail)
        
        return "✅ Saved PDF attachment to: \(savedURL.path)"
    }
    
    @MCPTool(description: "Test image OCR")
    func testImageOCR() async throws -> String {
        return try await mistralClient
            .ocr(
                type: .image(
                    url: "https://raw.githubusercontent.com/mistralai/cookbook/refs/heads/main/mistral/ocr/receipt.png"
                )
            )
            .pages.map { $0.markdown }
            .joined()
    }
    
    @MCPTool(description: "Test document OCR")
    func testDocumentOCR() async throws -> String {
        return try await mistralClient
            .ocr(type: .document(url: "https://arxiv.org/pdf/2201.04234"))
            .pages.map { $0.markdown }
            .joined()
    }
    
    @MCPTool(description: "Test uploading file to Mistral")
    func testFileUpload() async throws {
        let fileName = "Visa-Statement-Feb-10-2025"
        guard let url = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appending(path: "/MCP/\(fileName).pdf") else {
            throw Errors.failedToLoadFile
        }

        
        let file = MistralClient.FileClient.File(
            name: fileName,
            type: .pdf,
            data: try Data(contentsOf: url)
        )
        
        let response = try await mistralClient.upload(file)
        print("ℹ️ Response: \(response)")
    }
    
    @MCPTool(description: "Test some magic (OCR, file upload, etc.)")
    func magic() async throws -> String {
        do {
            let response = try await performMagic()
            
            var markdownFile: String = ""
            
            for page in response.pages {
                markdownFile += "PAGE: \(page.index) \n"
                markdownFile += "\(page.markdown) \n"
            }
        
            let resultFileURL = URL.documentsDirectory.appending(path: "results.md")
            
            try markdownFile.write(
                to: resultFileURL,
                atomically: true,
                encoding: .utf8
            )
            
            return "✅ We did it!"
        } catch {
            return "❌ ERROR: \(error)"
        }
    }
    
    // Currently working on reciepts with PDF attachments
    // Next, will work on reciepts with no attachments, but HTML instead (Apple's recipets)
    private func performMagic() async throws -> OCRResponse {
        // 1. Get latest email with attachment (image or pdf)
        let latestEmail = try await getLatestReceipt()
        
        guard let pdfAttachment = latestEmail
            .attachments
            .filter({ $0.contentSubtype == "pdf" })
            .first else {
            throw Errors.missingAttachment
        }

        let decodedData = try GmailPDFMessagePartDecoder.decode(pdfAttachment)
        
        let fileName = pdfAttachment.filename ?? "attachment.pdf"
        // 3. Upload file to mistral, keeping URL
        let attachmentFile = MistralClient.FileClient.File(
            name: fileName,
            type: .pdf,
            data: decodedData
        )
        let uploadResult = try await mistralClient.upload(attachmentFile)
        print("ℹ️ Uploaded Result ID: \(uploadResult.id)")
        let signedURL = try await mistralClient.signedURL(for: uploadResult.id)
        // 4. Perform OCR on uploaded file
        return try await mistralClient.ocr(type: .document(url: signedURL.url))
    }
    
    func getLatestReceipt() async throws -> Message {
        try await servers.email.setup()
        
        let emails = try await servers.email.fetchEmailsFromReceiptsMailbox()
        print("ℹ️ @@ fetched email count: \(emails.count) ")
        guard let latestEmail = emails.first else {
            throw Errors.emailNotFound
        }
        
        return latestEmail
    }
    
}

extension GatewayServer {
    enum Errors: Error {
        case emailNotFound
        case missingAttachment
        case failedSavingFile
        case failedToLoadFile
    }
}

extension GatewayServer {
    public enum ServerFactory {
        public static func make() async throws -> Servers{
            let emailServer = try await EmailServerFactory.make()
            
            return .init(
                email: emailServer
            )
        }
    }
}

extension GatewayServer {
    public struct Servers {
        let email: MCPEmailServer
        
        public init(email: MCPEmailServer) {
            self.email = email
        }
    }
}
