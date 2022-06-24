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
    init() {
        persistenceController.fixLooseRelations()
    }
    var body: some Scene {
        WindowGroup {
            DirectoryView()
        }
    }
}
