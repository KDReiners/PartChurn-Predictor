//
//  directoryView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import SwiftUI
import CoreData
struct DirectoryView: View {
    @EnvironmentObject var managerModels: ManagerModels
    var modelsDataModel: ModelsModel
    @ObservedObject var filesDataModel: FilesModel
    @State var modelSelect: NSManagedObject?
    @State var predictionSelect: NSManagedObject?
    @State var fileSelect: NSManagedObjectID?
    var activate = false
    var body: some View {
        NavigationView {
            List {
                DisclosureGroup("Modelle") {
                    if modelsDataModel.items.count > 0 {
                        ForEach(modelsDataModel.items, id: \.self) { item in
                            NavigationLink(item.name ?? "unbenanntes Modell", destination: ScenarioView(model: item, modelSelect: $modelSelect.wrappedValue), tag: item, selection: $modelSelect)
                        }
                    } else {
                        Text("No models")
                    }
                }
                DisclosureGroup("Composition") {
                    if PredictionsModel().items.count > 0 {
                        ForEach(PredictionsModel().items, id: \.self) { item in
                            NavigationLink(item.groupingpattern!, destination: SimulatorView(prediction: $predictionSelect.wrappedValue as? Predictions), tag: item, selection: $predictionSelect)
                        }
                    }
                }
                DisclosureGroup("Files") {
                    if filesDataModel.items.count > 0 {
                        ForEach(filesDataModel.items, id: \.self) { item in
                            NavigationLink( item.name ?? "unbenanntes Modell", destination: FilesView(file: item, columnsDataModel: managerModels.columnsDataModel), tag: item, selection: $modelSelect)
                        }
                    } else {
                        Text("No files")
                    }

                }
                DisclosureGroup("Data Manager") {
                    NavigationLink("Steps Import", destination: ImportView())
                }
            }
//            AnalysisView(model: ModelsModel().items.first!).onDisappear {
//                BaseServices.save()
//            }
        }
    }
}

