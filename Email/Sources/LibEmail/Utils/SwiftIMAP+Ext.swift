//
//  SwiftIMAP+Ext.swift
//  Email
//
//  Created by Steven Prichard on 2025-03-25.
//

import SwiftMail
import Foundation

extension Array where Element == Mailbox.Info {
    /// Find the first mailbox matching the string `receipts`
    public var receipts: Element? {
        guard let mailbox = first(where: { $0.name.lowercased() == "receipts" }) else {
            return nil
        }
        
        return mailbox
    }
}
