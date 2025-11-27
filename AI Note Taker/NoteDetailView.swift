//
//  NoteDetailView.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import AVFoundation
import WebKit
import QuickLook

struct NoteDetailView: View {
    let note: Note
    @Environment(\.modelContext) private var modelContext
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: TimeInterval = 0
    @State private var playbackDuration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                noteHeaderSection

                // Content Section based on note type
                contentSection

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        deleteNote()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }

    @ViewBuilder
    private var noteHeaderSection: some View {
        HStack(spacing: 12) {
            // Type Icon
            RoundedRectangle(cornerRadius: 12)
                .fill(note.type.color)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: note.type.systemImage)
                        .font(.title2)
                        .foregroundColor(.white)
                }

            // Note Info
            VStack(alignment: .leading, spacing: 4) {
                Text(note.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(note.type.color)

                Text(note.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var contentSection: some View {
        switch note.type {
        case .audio:
            audioContentView
        case .file, .pdf:
            fileContentView
        case .text:
            textContentView
        case .webLink:
            webLinkContentView
        }
    }

    private var audioContentView: some View {
        VStack(spacing: 16) {
            // Audio Waveform Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay {
                    VStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        if let duration = note.duration {
                            Text(formatDuration(duration))
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                }

            // Playback Controls
            VStack(spacing: 12) {
                // Progress Bar
                if playbackDuration > 0 {
                    VStack(spacing: 4) {
                        ProgressView(value: playbackProgress, total: playbackDuration)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))

                        HStack {
                            Text(formatDuration(playbackProgress))
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(formatDuration(playbackDuration))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Control Buttons
                HStack(spacing: 20) {
                    Button(action: seekBackward) {
                        Image(systemName: "gobackward.15")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .disabled(audioPlayer == nil)

                    Button(action: togglePlayback) {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.orange)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                    }
                    .disabled(audioPlayer == nil)

                    Button(action: seekForward) {
                        Image(systemName: "goforward.15")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .disabled(audioPlayer == nil)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var fileContentView: some View {
        VStack(spacing: 16) {
            // File Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.fill")
                        .font(.title2)
                        .foregroundColor(note.type.color)

                    Text(note.fileName ?? "Unknown File")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                if let fileSize = note.fileSize {
                    Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // File Actions
            VStack(spacing: 12) {
                if let fileURL = note.fileURL {
                    Button(action: {
                        shareFile(url: fileURL)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                            Text("Share")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        openFile(url: fileURL)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.right")
                                .font(.title3)
                            Text("Open")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var textContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(note.content ?? "")
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var webLinkContentView: some View {
        VStack(spacing: 16) {
            // URL Display
            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.headline)

                if let webURL = note.webURL {
                    Text(webURL.absoluteString)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                        .lineLimit(2)

                    Button(action: {
                        openURL(webURL)
                    }) {
                        HStack {
                            Image(systemName: "safari")
                                .font(.title3)
                            Text("Open in Safari")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Content Display
            if let content = note.content, !content.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)

                    Text(content)
                        .font(.body)
                        .textSelection(.enabled)
                        .lineLimit(nil)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func setupPlayer() {
        guard let audioURL = note.audioURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            playbackDuration = audioPlayer?.duration ?? 0
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }

    private func cleanupPlayer() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func togglePlayback() {
        guard let player = audioPlayer else { return }

        if isPlaying {
            player.pause()
            timer?.invalidate()
            timer = nil
        } else {
            player.play()
            startTimer()
        }
        isPlaying = player.isPlaying
    }

    private func seekBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(player.currentTime - 15, 0)
        player.currentTime = newTime
        playbackProgress = newTime
    }

    private func seekForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(player.currentTime + 15, player.duration)
        player.currentTime = newTime
        playbackProgress = newTime
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if let player = self.audioPlayer {
                    self.playbackProgress = player.currentTime
                    self.isPlaying = player.isPlaying
                }
            }
        }
    }

    private func shareFile(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }

    private func openFile(url: URL) {
        let controller = QLPreviewController()
        controller.dataSource = self
        controller.delegate = self

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(controller, animated: true)
        }
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func deleteNote() {
        modelContext.delete(note)

        do {
            try modelContext.save()

            // Dismiss the detail view
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let navController = window.rootViewController as? UINavigationController {
                navController.popViewController(animated: true)
            }
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension NoteDetailView: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            timer?.invalidate()
            timer = nil
            playbackProgress = 0
        }
    }
}

// MARK: - QLPreviewControllerDataSource
extension NoteDetailView: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        note.fileURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return note.fileURL! as QLPreviewItem
    }
}

// MARK: - QLPreviewControllerDelegate
extension NoteDetailView: QLPreviewControllerDelegate {
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        controller.dismiss(animated: true)
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(note: Note(textTitle: "Sample Text Note", textContent: "This is a sample text note for preview."))
    }
    .modelContainer(for: Note.self, inMemory: true)
}