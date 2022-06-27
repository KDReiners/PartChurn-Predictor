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
    @State var modelSelect: NSManagedObject?
    @State var fileSelect: NSManagedObjectID?
    var body: some View {
        NavigationView {
            List
            {
                DisclosureGroup("Modelle") {
                    ForEach(managerModels.modelsDataModel.items, id: \.self) { item in
                        NavigationLink(item.name ?? "unbenanntes Modell", destination: ModelsView(model: item, metric: Ml_MetricKPI(), mlTable: CoreDataML(model: item).mlDataTable), tag: item, selection: $modelSelect)
                    }
                }
                DisclosureGroup("Files") {
                    ForEach(managerModels.filesDataModel.items, id: \.self) { item in
                        NavigationLink(item.name ?? "unbenanntes Modell", destination: FilesView(file: item).environmentObject(managerModels), tag: item, selection: $modelSelect)
                    }
                }
                DisclosureGroup("Data Manager") {
                    NavigationLink("Steps Import", destination: ImportView())
                }
            }
        }.onAppear {
            managerModels.deinitAll()
            PersistenceController.shared.fixLooseRelations()
        }
    }
}

struct directoryView_Previews: PreviewProvider {
    static var previews: some View {
        DirectoryView()
    }
}
