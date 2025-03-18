//
//  FileResource.swift
//  Notes
//
//  Created by Steven Prichard on 2025-03-18.
//

import SwiftMCP
import Foundation

struct FileResource: MCPResource {
    var uri: URL
    var name: String
    var description: String
    var mimeType: String
}

extension FileResource {
    struct Content: MCPResourceContent {
        var uri: URL
        var mimeType: String?
        // Text content if applicable
        var text: String?
        // Binary data if applicable
        var blob: Data?
        
        static func from(url: URL, mimeType: String? = nil) throws -> Content {
            let determinedMimeType = mimeType ?? String.mimeType(for: url.pathExtension)
            
            let isText = determinedMimeType.hasPrefix("text/")
            
            if isText {
                let text = try String(contentsOf: url, encoding: .utf8)
                return Content(
                    uri: url,
                    mimeType: determinedMimeType,
                    text: text
                )
            } else {
                let data = try Data(contentsOf: url)
                return Content(
                    uri: url,
                    mimeType: determinedMimeType,
                    blob: data
                )
            }
        }
    }
}
