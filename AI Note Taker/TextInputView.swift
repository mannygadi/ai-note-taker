//
//  TextInputView.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import SwiftData

struct TextInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var content = ""
    @State private var showingSaveAlert = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)

                    TextField("Enter note title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onAppear {
                            if title.isEmpty {
                                title = "Note \(Date().formatted(date: .abbreviated, time: .shortened))"
                            }
                        }
                }

                // Content Editor
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Content")
                            .font(.headline)

                        Spacer()

                        Text("\(content.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Text Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTextNote()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Note Saved", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your text note has been saved successfully.")
        }
        .overlay {
            if isSaving {
                ProgressView("Saving...")
                    .scaleEffect(1.2)
                    .frame(width: 150, height: 150)
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }
        }
    }

    private func saveTextNote() {
        isSaving = true

        let note = Note(textTitle: title, textContent: content)
        modelContext.insert(note)

        do {
            try modelContext.save()
            isSaving = false
            showingSaveAlert = true
        } catch {
            print("Failed to save note: \(error)")
            isSaving = false
        }
    }
}

#Preview {
    TextInputView()
        .modelContainer(for: Note.self, inMemory: true)
}