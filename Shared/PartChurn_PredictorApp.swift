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
    @StateObject var managerModels = ManagerModels()
    var body: some Scene {
        WindowGroup {
            DirectoryView(modelsDataModel: managerModels.modelsDataModel, filesDataModel: managerModels.filesDataModel)
                .environmentObject(managerModels)
        }
    }
}
