//
//  ContentView.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [NoteItem]
    @State private var selectedFilter: NoteType? = nil
    @State private var showingAddNoteSheet = false

    var filteredNotes: [Note] {
        if let selectedFilter = selectedFilter {
            return notes.filter { $0.type == selectedFilter }
        }
        return notes
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with title
                VStack(spacing: 16) {
                    HStack {
                        Text("AI Note Taker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { showingAddNoteSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(title: "All", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }

                            FilterButton(title: "Audio", isSelected: selectedFilter == .audio) {
                                selectedFilter = .audio
                            }

                            FilterButton(title: "Files", isSelected: selectedFilter == .file) {
                                selectedFilter = .file
                            }

                            FilterButton(title: "Text", isSelected: selectedFilter == .text) {
                                selectedFilter = .text
                            }

                            FilterButton(title: "Links", isSelected: selectedFilter == .webLink) {
                                selectedFilter = .webLink
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                .background(Color(.systemGroupedBackground))

                // Notes list
                List {
                    if filteredNotes.isEmpty {
                        ContentUnavailableView {
                            Label("No Notes", systemImage: "note.text")
                        } description: {
                            Text("Start adding notes to see them here")
                        }
                    } else {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(note: note)) {
                                NoteRowView(note: note)
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddNoteSheet) {
            AddNoteView()
        }
    }

    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredNotes[index])
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct NoteRowView: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on note type
            Image(systemName: note.type.systemImage)
                .font(.title2)
                .foregroundColor(note.type.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Preview text based on note type
                Text(note.previewText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Additional info based on note type
                if let duration = note.duration, note.type == .audio {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let fileName = note.fileName, note.type == .file {
                    Text(fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let webURL = note.webURL, note.type == .webLink {
                    Text(webURL.absoluteString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Timestamp
            Text(note.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Placeholder views - will be implemented in next milestones
struct NoteDetailView: View {
    let note: Note

    var body: some View {
        VStack {
            Text("Note Detail")
                .font(.largeTitle)
            Text(note.title)
                .font(.headline)
            Text("Type: \(note.type.rawValue)")
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNoteType: NoteType? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("Add New Note")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose a note type to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Note Type Options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), spacing: 16) {
                    NoteTypeButton(
                        type: .audio,
                        title: "Record Audio",
                        description: "Record audio using your microphone",
                        icon: "waveform",
                        color: .orange
                    ) {
                        selectedNoteType = .audio
                    }

                    NoteTypeButton(
                        type: .file,
                        title: "Upload File",
                        description: "Upload audio, PDF, or text files",
                        icon: "doc.fill",
                        color: .blue
                    ) {
                        selectedNoteType = .file
                    }

                    NoteTypeButton(
                        type: .text,
                        title: "Create Text Note",
                        description: "Type or paste text content",
                        icon: "text.alignleft",
                        color: .green
                    ) {
                        selectedNoteType = .text
                    }

                    NoteTypeButton(
                        type: .webLink,
                        title: "Add Web Link",
                        description: "Save YouTube videos or webpages",
                        icon: "link",
                        color: .purple
                    ) {
                        selectedNoteType = .webLink
                    }
                }

                Spacer()
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedNoteType) { noteType in
            switch noteType {
            case .audio:
                AudioRecordingView()
            case .file, .pdf:
                FileUploadView()
            case .text:
                TextInputView()
            case .webLink:
                WebLinkView()
            }
        }
    }
}

struct NoteTypeButton: View {
    let type: NoteType
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension NoteType {
    var systemImage: String {
        switch self {
        case .audio: return "waveform"
        case .file: return "doc.fill"
        case .text: return "text.alignleft"
        case .webLink: return "link"
        case .pdf: return "doc.richtext"
        }
    }

    var color: Color {
        switch self {
        case .audio: return .orange
        case .file: return .blue
        case .text: return .green
        case .webLink: return .purple
        case .pdf: return .red
        }
    }
}

extension Note {
    var previewText: String {
        switch type {
        case .audio:
            return duration != nil ? "Audio recording" : "Audio note"
        case .file:
            return fileName ?? "File attachment"
        case .text:
            return content ?? "Text note"
        case .webLink:
            return content ?? "Web link"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}
