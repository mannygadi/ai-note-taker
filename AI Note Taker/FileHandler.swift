//
//  FileHandler.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class FileHandler: ObservableObject {
    @Published var selectedFile: URL?
    @Published var isImporting = false

    func importFile(from url: URL, modelContext: ModelContext) async -> Note? {
        isImporting = true

        defer { isImporting = false }

        do {
            // Create destination in app's documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = url.lastPathComponent
            let destinationURL = documentsPath.appendingPathComponent(fileName)

            // Copy file to app's documents
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }

                try FileManager.default.copyItem(at: url, to: destinationURL)

                // Get file size and attributes
                let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                // Create note from file
                let note = Note(
                    fileTitle: fileName.replacingOccurrences(of: "_", with: " ").components(separatedBy: ".").first ?? fileName,
                    fileURL: destinationURL,
                    fileName: fileName,
                    fileSize: fileSize
                )

                modelContext.insert(note)

                try modelContext.save()

                selectedFile = destinationURL
                return note
            }
        } catch {
            print("Failed to import file: \(error)")
        }

        return nil
    }

    func supportedFileTypes() -> [UTType] {
        [
            .audio,
            .mpeg4Audio,
            .wav,
            .mp3,
            .pdf,
            .text,
            .plainText,
            .rtf,
            .doc,
            .docx
        ]
    }

    func getDisplayName(for url: URL) -> String {
        let fileName = url.lastPathComponent
        let nameWithoutExtension = fileName.components(separatedBy: ".").first ?? fileName
        return nameWithoutExtension.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
    }

    func getFormattedFileSize(for url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } catch {
            return "Unknown size"
        }
    }

    func isAudioFile(_ url: URL) -> Bool {
        let audioTypes: [String] = [".m4a", ".mp3", ".wav", ".aac", ".caf"]
        return audioTypes.contains(url.pathExtension.lowercased())
    }

    func isPDFFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "pdf"
    }

    func isTextFile(_ url: URL) -> Bool {
        let textTypes: [String] = [".txt", ".rtf", ".md"]
        return textTypes.contains(url.pathExtension.lowercased())
    }
}

// File Importing View Modifier
struct FileImporter: ViewModifier {
    @StateObject private var fileHandler = FileHandler()
    @Environment(\.modelContext) private var modelContext
    let onFileImported: (Note?) -> Void

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: .constant(false),
                allowedContentTypes: fileHandler.supportedFileTypes(),
                allowsMultipleSelection: false
            ) { result in
                Task {
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        let note = await fileHandler.importFile(from: url, modelContext: modelContext)
                        await MainActor.run {
                            onFileImported(note)
                        }
                    case .failure(let error):
                        print("File import failed: \(error)")
                        await MainActor.run {
                            onFileImported(nil)
                        }
                    }
                }
            }
    }
}

extension View {
    func withFileImporter(onFileImported: @escaping (Note?) -> Void) -> some View {
        modifier(FileImporter(onFileImported: onFileImported))
    }
}