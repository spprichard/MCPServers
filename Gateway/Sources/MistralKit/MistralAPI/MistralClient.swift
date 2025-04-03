//
//  MistralAPI.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-30.
//

import Foundation

public protocol MistralAPI: Sendable {
    func ocr(type: MistralOCRType) async throws -> OCRResponse
    func upload(_ file: MistralClient.FileClient.File) async throws -> UploadFileResponse
    func signedURL(for resourceID: String) async throws -> SignedURLResponse
}

public struct MistralClient: MistralAPI {
    private var apiKey: String
    private let baseURL = URL(string: "https://api.mistral.ai/")!
    // Clients
    private let filesClient: FileClient
    private let ocrClient: OCRClient
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(apiKey)"]
        let session = URLSession(configuration: config)
        
        self.filesClient = FileClient(
            baseURL: baseURL,
            session: session
        )
        self.ocrClient = OCRClient(
            baseURL: baseURL,
            session: session
        )
    }
    
    public func ocr(type: MistralOCRType) async throws -> OCRResponse {
        try await ocrClient.ocr(type: type)
    }
    
    public func upload(_ file: FileClient.File) async throws -> UploadFileResponse {
        try await filesClient.upload(file)
    }
    
    public func signedURL(for resourceID: String) async throws -> SignedURLResponse {
        try await filesClient.signedURL(id: resourceID)
    }
}
