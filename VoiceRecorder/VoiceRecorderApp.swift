//
//  VoiceRecorderApp.swift
//  VoiceRecorder
//
//  Created by Ky Nguyen on 3/11/25.
//

import SwiftUI
import SwiftData

@main
struct VoiceRecorderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AudioNote.self
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
            AudioNotesView()
        }
        .modelContainer(sharedModelContainer)
    }
}
