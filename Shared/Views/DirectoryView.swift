//
//  directoryView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import SwiftUI
import CoreData
struct DirectoryView: View {
    var modelsDataModel = ModelsModel()
    @State var select: NSManagedObject?
    var body: some View {
        NavigationView {
            List
            {
                DisclosureGroup("Modelle") {
                    ForEach(modelsDataModel.items, id: \.self) { item in
                        NavigationLink(item.name ?? "unbenanntes Modell", destination: ModelsView(model: item), tag: item, selection: $select)
                    }
                    
                }
                DisclosureGroup("Data Manager") {
                    NavigationLink("Steps Import", destination: ImportView())
                }
            }
        }
    }
}

struct directoryView_Previews: PreviewProvider {
    static var previews: some View {
        DirectoryView()
    }
}
