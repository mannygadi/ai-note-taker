//
//  Item.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import Foundation
import SwiftData

enum NoteType: String, CaseIterable, Codable {
    case audio = "Audio"
    case file = "File"
    case text = "Text"
    case webLink = "Web Link"
    case pdf = "PDF"
}

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String?
    var timestamp: Date
    var type: NoteType
    var audioURL: URL?
    var fileURL: URL?
    var webURL: URL?
    var duration: Double?
    var fileName: String?
    var fileSize: Int64?

    init(title: String, type: NoteType, content: String? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.timestamp = Date()
        self.type = type
    }

    // Convenience initializers for different note types
    convenience init(audioTitle: String, audioURL: URL, duration: Double) {
        self.init(title: audioTitle, type: .audio)
        self.audioURL = audioURL
        self.duration = duration
    }

    convenience init(fileTitle: String, fileURL: URL, fileName: String, fileSize: Int64) {
        self.init(title: fileTitle, type: .file)
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
    }

    convenience init(textTitle: String, textContent: String) {
        self.init(title: textTitle, type: .text, content: textContent)
    }

    convenience init(webLinkTitle: String, webURL: URL, content: String? = nil) {
        self.init(title: webLinkTitle, type: .webLink, content: content)
        self.webURL = webURL
    }
}
