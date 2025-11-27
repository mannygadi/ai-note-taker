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
    @Query private var notes: [Note]
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
                    HStack(spacing: 12) {
                        FilterButton(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }

                        ForEach(NoteType.allCases, id: \.self) { type in
                            FilterButton(title: type.rawValue, isSelected: selectedFilter == type) {
                                selectedFilter = type
                            }
                        }
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
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Note - Coming Soon!")
                    .font(.headline)
                Text("Audio recording, file upload, text input, and web link features will be implemented in the next milestones.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension NoteType {
    var systemImage: String {
        switch self {
        case .audio: return "waveform"
        case .file: return "doc.fill"
        case .text: return "text.alignleft"
        case .webLink: return "link"
        }
    }

    var color: Color {
        switch self {
        case .audio: return .orange
        case .file: return .blue
        case .text: return .green
        case .webLink: return .purple
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
