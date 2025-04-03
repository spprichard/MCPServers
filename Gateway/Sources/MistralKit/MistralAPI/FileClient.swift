//
//  MistralAPI+FileClient.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-30.
//

import NIOCore
import Foundation
import MultipartKit
import ExtrasBase64
import NIOFoundationCompat
import Hummingbird

struct MultipartRequestDecoder: RequestDecoder {
    func decode<T>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T where T: Decodable {
        let decoder = FormDataDecoder()
        return try await decoder.decode(type, from: request, context: context)
    }
}



extension MistralClient {
    public struct FileClient: Sendable {
        private static var maxUploadSize: Int { 2 * 1024 * 1024 }
        private let baseURL: URL
        private let session: URLSession
        private var filesV1API: URL { baseURL.appending(path: "/v1/files") }
        let boundary = "----FileClientBoundary" + String(base32Encoding: (0..<4).map { _ in UInt8.random(in: 0...255) })
        
        public init(baseURL: URL, session: URLSession) {
            self.baseURL = baseURL
            self.session = session
        }
                
        public func upload(_ file: File) async throws -> UploadFileResponse {
            let request = createURLRequest(
                with: createMultipartRequest(
                    from: file
                )
            )
            
            let (responseData, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                print("@@ Error response: \(String(data: responseData, encoding: .utf8) ?? "No error message")")
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(UploadFileResponse.self, from: responseData)
        }
        
        private func createURLRequest(with payload: MultiPartRequest) -> URLRequest {
            var request = URLRequest(url: filesV1API)
            request.httpMethod = "POST"
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = payload.httpBody
            return request
        }
        
        private func createMultipartRequest(from file: File) -> MultiPartRequest {
            var payload = MultiPartRequest(boundary: boundary)
            payload.add(property: .ocr)
            payload.add(property: .file(details: file))
            return payload
        }

        public func signedURL(id: String) async throws -> SignedURLResponse {
            let signedURL = filesV1API
                .appending(
                    path: "\(id)/url"
                )
                .appending(queryItems: [
                    .init(name: "expiry", value: "24")
                ])
                
            var request = URLRequest(url: signedURL)
            request.httpMethod = "GET"
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                print("@@ Error response: \(String(data: data, encoding: .utf8) ?? "No error message")")
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(SignedURLResponse.self, from: data)
        }
    }
}

extension MistralClient.FileClient {
    public struct File: Sendable {
        let name: String
        let type: FileType
        let data: Data
        
        public init(
            name: String,
            type: FileType,
            data: Data
        ) {
            self.name = name
            self.type = type
            self.data = data
        }
    }
    
    public enum FileType: Sendable {
        case pdf
        
        var contentType: String {
            switch self {
            case .pdf:
                return "application/pdf"
            }
        }
    }
    
    struct FileUploadRequest: Codable {
        let purpose: String
        let file: Data
        
        enum CodingKeys: String, CodingKey {
            case purpose
            case file
        }
    }
}

extension MultiPartRequest {
    enum Purpose: String {
        case ocr
    }
    
    enum MultiPartRequestProperty: Sendable {
        case purpose(Purpose)
        case file(details: MistralClient.FileClient.File)
        
        struct File {
            let name: String
            let mimeType: String
            let data: Data
        }
        
        static let ocr = MultiPartRequestProperty.purpose(.ocr)
    }
    
    mutating func add(property: MultiPartRequestProperty) {
        switch property {
        case .purpose(let purpose):
            self.add(key: "purpose", value: purpose.rawValue)
        case .file(let file):
            self.add(
                key: "file",
                fileName: file.name,
                fileMimeType: file.type.contentType,
                fileData: file.data
            )
        }
    }
}

public struct SignedURLResponse: APIResponse {
    public var url: String
}

//import NIOCore
//import Hummingbird
//
//extension FormDataDecoder {
//    /// Extend JSONDecoder to decode from `HBRequest`.
//    /// - Parameters:
//    ///   - type: Type to decode
//    ///   - request: Request to decode from
//    public func decode<T: Decodable>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T {
//        guard let contentType = request.headers[.contentType],
//              let mediaType = MediaType(from: contentType),
//              let parameter = mediaType.parameter,
//              parameter.name == "boundary"
//        else {
//            throw HTTPError(.unsupportedMediaType)
//        }
//        let buffer = try await request.body.collect(upTo: context.maxUploadSize)
//        return try self.decode(T.self, from: buffer, boundary: parameter.value)
//    }
//}

extension FormDataEncoder {
    /// Extend JSONEncoder to support encoding `HBResponse`'s. Sets body and header values
    /// - Parameters:
    ///   - value: Value to encode
    ///   - request: Request used to generate response
    public func encode<T: Encodable>(_ value: T, from request: Request, context: some RequestContext) throws -> Response {
        var buffer = ByteBuffer()

        let boundary = "----HBFormBoundary" + String(base32Encoding: (0..<4).map { _ in UInt8.random(in: 0...255) })
        try self.encode(value, boundary: boundary, into: &buffer)
        return Response(
            status: .ok,
            headers: [.contentType: "multipart/form-data; boundary=\(boundary)"],
            body: .init(byteBuffer: buffer)
        )
    }
}

extension FormDataDecoder {
    /// Extend JSONDecoder to decode from `HBRequest`.
    /// - Parameters:
    ///   - type: Type to decode
    ///   - request: Request to decode from
    public func decode<T: Decodable>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T {
        guard let contentType = request.headers[.contentType],
              let mediaType = MediaType(from: contentType),
              let parameter = mediaType.parameter,
              parameter.name == "boundary"
        else {
            throw HTTPError(.unsupportedMediaType)
        }
        let buffer = try await request.body.collect(upTo: context.maxUploadSize)
        return try self.decode(T.self, from: buffer, boundary: parameter.value)
    }
}
