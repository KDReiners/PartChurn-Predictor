//
//  directoryView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import SwiftUI
import CoreData
import PythonKit

struct DirectoryView: View {
    @State private var activeLink: ActiveLink? = DirectoryView.ActiveLink.none
    @EnvironmentObject var managerModels: ManagerModels
    var modelsDataModel: ModelsModel
    @ObservedObject var filesDataModel: FilesModel
    @State var modelSelect: NSManagedObject?
    @State var predictionSelect: NSManagedObject?
    @State var fileSelect: NSManagedObjectID?
    public enum ActiveLink {
            case none
            case configuration
            case playground
            case predictions
            case files
            case dataManager
    }
    var activate = false
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .opacity(1)
                    .ignoresSafeArea()
                List {
                    ForEach(modelsDataModel.items, id: \.self) { model in
                        DisclosureGroup(model.name!) {
                            NavigationLink("Settings", destination: ModelsView(model: model))
                            if model == modelSelect {
                                NavigationLink("Laboratory", destination: ScenarioView(model: model, modelSelect: $modelSelect.wrappedValue), tag: model, selection: $modelSelect)
                            } else {
                                NavigationLink("Laboratory", destination: Text(model.name!), tag: model, selection: $modelSelect)
                            }
                            NavigationLink("Predictions", destination: PredictionsView(model: model))
                            DisclosureGroup("Environment") {
                                NavigationLink("Databases", destination: SourcesView(selectedModel: model))
                                DisclosureGroup("Files") {
                                    let files =  model.model2files?.allObjects as! [Files]
                                    if filesDataModel.items.count > 0 {
                                        ForEach(files, id: \.self) { file in
                                            NavigationLink( file.name!, destination: FilesView(file: file, columnsDataModel: managerModels.columnsDataModel), tag: file, selection: $modelSelect)
                                        }
                                    } else {
                                        Text("No files")
                                    }
                                    
                                }
                            }
//                            NavigationLink("Automator", destination: AnalysisView(model: model))
                        }
                    }
                }
            }
        }
        .onAppear {
            
//            // Create a Python object representing the sys module
//            let sys = Python.import("sys")
//            print(sys.executable)
//            let numpy = Python.import("numpy")

            // Print the version of Python being used by PythonKit
//            print(sys.version)
        }
    }
}

