//
//  WebLinkView.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import SwiftData
import WebKit

struct WebLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var urlString = ""
    @State private var showingSaveAlert = false
    @State private var isFetching = false
    @State private var fetchedContent = ""
    @State private var showingPreview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // URL Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Web Link")
                            .font(.headline)

                        TextField("https://example.com", text: $urlString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onSubmit {
                                fetchWebContent()
                            }

                        Button(action: fetchWebContent) {
                            HStack {
                                if isFetching {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text(isFetching ? "Fetching..." : "Fetch Content")
                            }
                        }
                        .disabled(urlString.isEmpty || isFetching)
                        .buttonStyle(.borderedProminent)
                    }

                    // Preview Section
                    if !fetchedContent.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Preview")
                                    .font(.headline)

                                Spacer()

                                Button(showingPreview ? "Hide" : "Show") {
                                    showingPreview.toggle()
                                }
                                .font(.subheadline)
                            }

                            if showingPreview {
                                Text(fetchedContent)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .lineLimit(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Tap 'Show' to display content preview")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)

                        TextField("Enter note title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onAppear {
                                if title.isEmpty && !urlString.isEmpty {
                                    generateTitleFromURL()
                                }
                            }
                    }

                    Spacer(minLength: 20)
                }
            .padding()
            .navigationTitle("Web Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWebLinkNote()
                    }
                    .disabled(urlString.isEmpty || title.isEmpty || isFetching)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Link Saved", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your web link has been saved successfully.")
        }
    }

    func fetchWebContent() {
        guard let url = URL(string: urlString), urlString.isValidURL else { return }

        isFetching = true
        fetchedContent = ""

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                if let html = String(data: data, encoding: .utf8) {
                    // Simple HTML tag removal for content extraction
                    let content = html
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "&[^;]+;", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .prefix(500) // Limit to first 500 characters

                    await MainActor.run {
                        self.fetchedContent = String(content)
                        self.isFetching = false
                    }
                }
            } catch {
                print("Failed to fetch content: \(error)")
                await MainActor.run {
                    self.fetchedContent = "Failed to fetch content from this URL."
                    self.isFetching = false
                }
            }
        }
    }

    func generateTitleFromURL() {
        let cleanURL = urlString.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")

        if let urlComponents = URLComponents(string: "https://" + cleanURL),
           let host = urlComponents.host {
            title = host.replacingOccurrences(of: ".", with: " ").capitalized
        }
    }

    func saveWebLinkNote() {
        guard let url = URL(string: urlString) else { return }

        let content = fetchedContent.isEmpty ? "Web link: \(urlString)" : fetchedContent
        let note = Note(webLinkTitle: title, webURL: url, content: content)
        modelContext.insert(note)

        do {
            try modelContext.save()
            showingSaveAlert = true
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

}

extension String {
    var isValidURL: Bool {
        let urlRegEx = "^(https?://)?(([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,})|(localhost)|((\\d{1,3}\\.){3}\\d{1,3}))(\\:\\d+)?(\\/[-a-zA-Z0-9%._~+]*)*(\\?[;&a-zA-Z0-9%_~+=-]*)?(#[-a-zA-Z0-9%_~+=-]*)?$"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: self)
    }
}

#Preview {
    WebLinkView()
        .modelContainer(for: Note.self, inMemory: true)
}