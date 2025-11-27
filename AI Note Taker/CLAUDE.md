# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS AI Note Taker application built with SwiftUI and SwiftData that allows users to create and manage different types of notes including audio recordings, uploaded files, text input, and web links.

## Technology Stack

- **Platform**: iOS (SwiftUI)
- **Language**: Swift
- **Data Persistence**: SwiftData (iOS 17+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI with NavigationSplitView
- **Project File**: `AI Note Taker.xcodeproj`

## Core Architecture

### Data Models
- **`Item.swift`**: Current basic SwiftData model with only `timestamp` property
- **Future models needed**: AudioNote, FileNote, TextNote, WebLinkNote (should extend or replace Item)

### Key Components
- **`AI_Note_TakerApp.swift`**: Main app entry point with SwiftData ModelContainer configuration
- **`ContentView.swift`**: Main UI with NavigationSplitView showing note list and detail view
- **ModelContainer**: Configured for persistent storage (not in-memory)

### Planned Note Types
Based on requirements and mockups in `MockUI/`:
1. **Audio recordings** - created using device microphone
2. **Uploaded audio files** - from device storage
3. **PDF/text files** - document uploads
4. **Text input** - manual text entry
5. **Web links** - YouTube videos and website content fetching

## Development Workflow

### Project Setup
- Open `AI Note Taker.xcodeproj` in Xcode
- Target iOS 17+ (required for SwiftData)
- Uses SwiftData ModelContainer for local iPhone storage

### Git Workflow
- Create git checkpoints after each milestone completion
- Current branch: main
- Recent commits tracked with milestone markers

### Current Implementation Status
- **Phase 1**: Basic SwiftData app structure ✅
  - SwiftData ModelContainer configured
  - Basic note list with add/delete functionality
  - NavigationSplitView layout
  - Simple Item model with timestamp

- **Next Phase**: Implement note type system and UI mockups

## Mock UI Designs
Reference mockups in `MockUI/` folder:
- `Main.PNG`: Main note list screen with filters
- `Record-Audio.PNG`: Audio recording interface
- `Input-Text.PNG`: Text input interface
- `PDF-Text.PNG`: Document upload interface
- `Web-Link.PNG`: Web link integration interface

## Key Requirements from Planning

1. **Main Screen**: Filterable list of all note types
2. **Content Handling**: Use appropriate tools to open each note type
3. **Local Storage**: All notes stored locally on iPhone using SwiftData
4. **Web Integration**: Fetch and display web content for YouTube/websites
5. **Milestones**: Checkpoint in git after each major feature completion

## Development Considerations

- **SwiftData Evolution**: Current `Item` model needs significant expansion to support multiple note types
- **File Handling**: Will need proper file management system for audio/PDF uploads
- **Web Content**: Implement web scraping/content fetching for link processing
- **UI Implementation**: Match mockup designs in MockUI folder
- **Testing**: Test with various file types and content sources