//
//  File.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-03-30.
//

import Foundation

extension MistralClient {
    public struct OCRClient: Sendable {
        private let baseURL: URL
        private let session: URLSession
        private var ocrV1API: URL { baseURL.appending(path: "v1/ocr") }
        
        public init(
            baseURL: URL,
            session: URLSession
        ) {
            self.baseURL = baseURL
            self.session = session
        }
        
        private func buildPayload(for type: MistralOCRType) -> Codable {
            switch type {
            case .document(let documentURL):
                OCRDocumentRequest(
                    model: .latest,
                    document: .init(
                        type: .documentURL,
                        url: documentURL
                    )
                )
            case .image(let imageURL):
                OCRImageRequest(
                    model: .latest,
                    document: .init(
                        type: .imageURL,
                        url: imageURL
                    )
                )
            }
        }
        
        public func ocr(type: MistralOCRType) async throws -> OCRResponse {
            var request = URLRequest(url: ocrV1API)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(buildPayload(for: type))
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode(OCRResponse.self, from: data)
        }
    }
}
