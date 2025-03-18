//
//  NotesServer.swift
//  Notes
//
//  Created by Steven Prichard on 2025-03-18.
//

import SwiftMCP
import Foundation

@MCPServer(name: "Files", version: "0.0.1")
final class FilesServer {
    init() {}
    
    // MARK: Currently pulls from a `MCP` folder within your documents directory.
    // NOTE: file names can not contain spaces.
    var mcpResources: [any MCPResource] {
        guard let downloadURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appending(path: "MCP") else {
            logToStderr("Unable to get Downloads folder ")
            return []
        }
        
        do {
            // List all resources
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: downloadURL,
                includingPropertiesForKeys: [
                    .isRegularFileKey,
                    .nameKey,
                    .fileSizeKey
                ],
                options: [.skipsHiddenFiles]
            )
            
            // Filter only regular files
            let regularFileURLs = fileURLs.filter { url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])
                    return resourceValues.isRegularFile ?? false
                } catch {
                    return false
                }
            }
            
            return regularFileURLs.map { url in
                let fileAttributes: String
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path())
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
                    let modifiedString = formatter.string(from: modificationDate)
                    fileAttributes = "Size: \(sizeString), Modified: \(modifiedString)"
                } catch {
                    fileAttributes = "File in downloads folder"
                }
                
                return FileResource(
                    uri: url,
                    name: url.lastPathComponent,
                    description: fileAttributes,
                    mimeType: String.mimeType(for: url.pathExtension)
                )
            }
            
        } catch {
            logToStderr(error.localizedDescription)
            return []
        }
        
    }
    
    func getResource(uri: URL) throws -> (any MCPResourceContent)? {
        guard FileManager.default.fileExists(atPath: uri.path()) else {
            return nil
        }
        
        return try FileResource.Content.from(url: uri)
    }
}
