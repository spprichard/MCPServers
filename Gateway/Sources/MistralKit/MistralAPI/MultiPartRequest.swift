//
//  MultiPartRequest.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-30.
//

import Foundation

struct MultiPartRequest: Sendable {
    public let boundary: String
    private let separator = "\r\n"
    private var data: Data
    
    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
        self.data = .init()
    }
    
    private mutating func appendBoundarySeparator() {
        data.append("--\(boundary)\(separator)".data(using: .utf8)!)
    }
    
    private mutating func appendSeparator() {
        data.append(separator.data(using: .utf8)!)
    }
    
    public mutating func add(key: String, value: String) {
        appendBoundarySeparator()
        data.append("Content-Disposition: form-data; name=\"\(key)\"\(separator)\(separator)".data(using: .utf8)!)
        data.append((value + separator).data(using: .utf8)!)
    }
    
    public mutating func add(
        key: String,
        fileName: String,
        fileMimeType: String,
        fileData: Data
    ) {
        appendBoundarySeparator()
        data.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\(separator)".data(using: .utf8)!)
        data.append("Content-Type: \(fileMimeType)\(separator)\(separator)".data(using: .utf8)!)
        data.append(fileData)
        appendSeparator()
    }
    
    public var httpContentTypeHeaderValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    public var httpBody: Data {
        var bodyData = data
        bodyData.append("--\(boundary)--\(separator)".data(using: .utf8)!)
        return bodyData
    }
}
