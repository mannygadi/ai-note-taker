//
//  AudioRecordingView.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import SwiftData
import Combine

struct AudioRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var title = ""
    @State private var showingSaveAlert = false
    @State private var recordingSaved = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("Record Audio")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tap the microphone to start recording")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                Spacer()

                // Audio Waveform Visualization (placeholder)
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 120)
                        .overlay {
                            if audioRecorder.isRecording {
                                // Simulated waveform
                                HStack(alignment: .center, spacing: 2) {
                                    ForEach(0..<30, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.orange)
                                            .frame(width: 3, height: CGFloat.random(in: 20...80))
                                            .animation(.easeInOut(duration: 0.1).repeatForever(), value: audioRecorder.recordingTime)
                                    }
                                }
                            } else {
                                Image(systemName: "waveform")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                            }
                        }

                    // Recording Timer
                    Text(audioRecorder.formatDuration(audioRecorder.recordingTime))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }

                Spacer()

                // Recording Controls
                VStack(spacing: 24) {
                    // Record/Stop Button
                    Button(action: {
                        if audioRecorder.isRecording {
                            audioRecorder.stopRecording()
                        } else {
                            audioRecorder.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(audioRecorder.isRecording ? Color.red : Color.orange)
                                .frame(width: 80, height: 80)

                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Recording Status Text
                    Text(audioRecorder.isRecording ? "Recording..." : "Tap to Record")
                        .font(.headline)
                        .foregroundColor(audioRecorder.isRecording ? .red : .primary)
                }

                Spacer()

                // Title Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recording Title")
                        .font(.headline)

                    TextField("Enter recording title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(audioRecorder.isRecording)
                }
                .padding(.horizontal)

                // Action Buttons
                HStack(spacing: 20) {
                    // Cancel Button
                    Button("Cancel") {
                        audioRecorder.cancelRecording()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .disabled(audioRecorder.isRecording)

                    // Save Button
                    Button("Save") {
                        saveRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || audioRecorder.isRecording || audioRecorder.audioURL == nil)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Audio Recording")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(audioRecorder.isRecording)
                }
            }
        }
        .alert("Recording Saved", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your audio recording has been saved successfully.")
        }
        .onChange(of: recordingSaved) { saved in
            if saved {
                showingSaveAlert = true
            }
        }
    }

    private func saveRecording() {
        guard let note = audioRecorder.saveRecording(modelContext: modelContext, title: title) else {
            return
        }

        do {
            try modelContext.save()
            recordingSaved = true
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}

#Preview {
    AudioRecordingView()
        .modelContainer(for: Note.self, inMemory: true)
}