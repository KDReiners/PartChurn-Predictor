//
//  PartChurn_PredictorApp.swift
//  Shared
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import SwiftUI

@main
struct PartChurn_PredictorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
