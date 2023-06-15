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
    init() {
        setenv("PYTHONPATH", "/opt/homebrew/lib/python3.11/site-packages", 1)
        setenv("PYTHON_EXECUTABLE", "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3", 1)


//        setenv("PYTHON_LIBRARY", "/opt/homebrew/Cellar/python@3.9/3.9.16/Frameworks/Python.framework/Versions/3.9/Python", 1)
//        setenv("DYLD_LIBRARY_PATH", "/opt/homebrew/Cellar/python@3.9/3.9.16/Frameworks/Python.framework/Versions/3.9/Python", 1)


    }
    var body: some Scene {
        WindowGroup {
            DirectoryView(modelsDataModel: managerModels.modelsDataModel, filesDataModel: managerModels.filesDataModel)
                .environmentObject(ManagerModels())
                .environmentObject(SimulationController())
                .frame(minWidth: 1100)
        }.commands {
            SidebarCommands() // 1
        }
    }
}
