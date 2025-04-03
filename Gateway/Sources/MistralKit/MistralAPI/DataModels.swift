//
//  DataModels.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-28.
//

import Foundation

typealias APIResponse = Decodable & Sendable

public enum MistralOCRType {
    case document(url: String)
    case image(url: String)
}


enum OCRModel: String, Codable {
    case latest = "mistral-ocr-latest"
}

enum OCRDocumentType: String, Codable {
    case documentURL = "document_url"
    case imageURL = "image_url"
}

struct OCRDocument: Codable {
    var type: OCRDocumentType
    var url: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case url = "document_url"
    }
}

struct OCRImage: Codable {
    var type: OCRDocumentType
    var url: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case url = "image_url"
    }
}

struct OCRDocumentRequest: Codable {
    var model: OCRModel
    var document: OCRDocument
}

struct OCRImageRequest: Codable {
    var model: OCRModel
    var document: OCRImage
}

public struct OCRResponse: APIResponse {
    public let pages: [OCRPage]
    public let model: String
    public let usage: UsageInfo
    
    enum CodingKeys: String, CodingKey {
        case pages
        case model
        case usage = "usage_info"
    }
}

public struct UsageInfo: APIResponse {
    public let pagesProcessed: Int
    public let docSizeBytes: Int
    
    enum CodingKeys: String, CodingKey {
        case pagesProcessed = "pages_processed"
        case docSizeBytes = "doc_size_bytes"
    }
}

public struct OCRPage: APIResponse {
    public let index: Int
    public let markdown: String
}

public struct UploadFileResponse: APIResponse {
    public let id: String
    public let object: String
    public let filename: String
    public let purpose: String
}
