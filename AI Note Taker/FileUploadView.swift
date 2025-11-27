//
//  FileUploadView.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import SwiftData

struct FileUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingFileImporter = false
    @State private var importedNote: Note?
    @State private var showingSaveAlert = false
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("Upload File")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose a file from your device to add as a note")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                Spacer()

                // File Upload Area
                VStack(spacing: 24) {
                    if isImporting {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Importing file...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Upload Button
                        Button(action: {
                            showingFileImporter = true
                        }) {
                            VStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 200, height: 200)
                                    .overlay {
                                        VStack(spacing: 16) {
                                            Image(systemName: "doc.badge.plus")
                                                .font(.system(size: 50))
                                                .foregroundColor(.blue)

                                            Text("Choose File")
                                                .font(.headline)
                                                .foregroundColor(.blue)

                                            Text("Tap to browse")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Supported File Types
                        VStack(spacing: 12) {
                            Text("Supported File Types")
                                .font(.headline)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                FileTypeIcon(type: .audio, label: "Audio")
                                FileTypeIcon(type: .pdf, label: "PDF")
                                FileTypeIcon(type: .text, label: "Text")
                                FileTypeIcon(type: .document, label: "Document")
                            }
                        }
                    }

                    if let note = importedNote {
                        // Successfully Imported File
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)

                                Text("File Imported Successfully")
                                    .font(.headline)
                            }

                            // File Info Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: note.type.systemImage)
                                        .foregroundColor(note.type.color)

                                    Text(note.fileName ?? "Unknown")
                                        .font(.headline)
                                        .lineLimit(1)

                                    Spacer()
                                }

                                if let fileSize = note.fileSize {
                                    Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImporting)

                    Button("Save") {
                        saveAndDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(importedNote == nil || isImporting)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Upload File")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [
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
            ],
            allowsMultipleSelection: false
        ) { result in
            isImporting = true

            Task {
                switch result {
                case .success(let urls):
                    guard let url = urls.first else {
                        isImporting = false
                        return
                    }

                    await importFile(from: url)

                case .failure(let error):
                    print("File import failed: \(error)")
                    isImporting = false
                }
            }
        }
        .alert("File Saved", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your file has been saved successfully.")
        }
    }

    private func importFile(from url: URL) async {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = url.lastPathComponent
            let destinationURL = documentsPath.appendingPathComponent(fileName)

            // Copy file to app's documents directory
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }

                try FileManager.default.copyItem(at: url, to: destinationURL)

                // Get file size and attributes
                let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                // Determine file type
                let fileExtension = url.pathExtension.lowercased()
                var noteType: NoteType

                if ["m4a", "mp3", "wav", "aac", "caf"].contains(fileExtension) {
                    noteType = .audio
                } else if fileExtension == "pdf" {
                    noteType = .pdf
                } else if ["txt", "rtf", "md"].contains(fileExtension) {
                    noteType = .text
                } else {
                    noteType = .file
                }

                // Create note from file
                let displayName = fileName.replacingOccurrences(of: "_", with: " ")
                    .components(separatedBy: ".").first ?? fileName

                let note = Note(
                    fileTitle: displayName,
                    fileURL: destinationURL,
                    fileName: fileName,
                    fileSize: fileSize
                )

                await MainActor.run {
                    importedNote = note
                    isImporting = false
                }
            }
        } catch {
            print("Failed to import file: \(error)")
            await MainActor.run {
                isImporting = false
            }
        }
    }

    private func saveAndDismiss() {
        guard let note = importedNote else { return }

        modelContext.insert(note)

        do {
            try modelContext.save()
            showingSaveAlert = true
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

struct FileTypeIcon: View {
    let type: FileType
    let label: String

    enum FileType {
        case audio, pdf, text, document
    }

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorForType)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: iconForType)
                        .font(.title3)
                        .foregroundColor(.white)
                }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var iconForType: String {
        switch type {
        case .audio: return "waveform"
        case .pdf: return "doc.fill"
        case .text: return "text.alignleft"
        case .document: return "doc"
        }
    }

    private var colorForType: Color {
        switch type {
        case .audio: return .orange
        case .pdf: return .red
        case .text: return .green
        case .document: return .blue
        }
    }
}

#Preview {
    FileUploadView()
        .modelContainer(for: Note.self, inMemory: true)
}