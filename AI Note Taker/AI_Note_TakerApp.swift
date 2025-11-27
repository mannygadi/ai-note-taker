//
//  AI_Note_TakerApp.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
//

import SwiftUI
import SwiftData

@main
struct AI_Note_TakerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NoteItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
