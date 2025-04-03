//
//  GmailPDFAttachmentDecoder.swift
//  Gateway
//
//  Created by Steven Prichard on 2025-04-03.
//

import SwiftMail
import Foundation

public struct GmailPDFMessagePartDecoder {
    /// Decodes provded data based on how Gmail encodes PDF attachments
    /// - Parameter data: Email attachment data
    /// - Returns: Decoded PDF data
    public static func decode(_ message: MessagePart) throws(Errors) -> Data {
        guard let encodedUTF8 = String(data: message.data, encoding: .utf8) else {
            throw .inputEncodingFailure
        }
        
        encodedUTF8
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "_", with: "/")
            
        guard let decodedData = Data(
            base64Encoded: encodedUTF8,
            options: [.ignoreUnknownCharacters]
        ) else {
            throw .base64DecodingFailure
        }
        
        return decodedData
    }
        
    public enum Errors: Error, CustomStringConvertible {
        public var description: String {
            switch self {
            case .inputEncodingFailure:
                return "Failed to encode input data into UTF8"
            case .preparationEncodingFailure:
                return "Falied to prepare provided data"
            case .base64DecodingFailure:
                return "Failed to decode prepared data into Base64"
            }
        }
        
        case inputEncodingFailure
        case preparationEncodingFailure
        case base64DecodingFailure
    }
}
