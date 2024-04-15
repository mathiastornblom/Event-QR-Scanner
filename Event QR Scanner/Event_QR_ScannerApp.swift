//
//  Event_QR_ScannerApp.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//

import SwiftUI
import SwiftData

@main
struct Event_QR_ScannerApp: App {
    // Shared model container to hold and manage your app's data model.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self, // Define the schema using the models your app will use.
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // Attempt to create a ModelContainer with the provided schema and configuration.
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView() // Set SplashView as the initial view.
        }
        .modelContainer(sharedModelContainer) // Inject the shared model container into the environment.
    }
}
