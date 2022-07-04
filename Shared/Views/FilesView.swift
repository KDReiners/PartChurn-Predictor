//
//  FilesView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI

struct FilesView: View {
    @EnvironmentObject var managerModels: ManagerModels
    var file: Files
    @State var valuesView: ValuesView?
    var coreDataML: CoreDataML {
        CoreDataML(model: file.files2model!, files: file)
    }
    init(file: Files) {
        self.file = file

    }
    
    var body: some View {
        VStack {
            ColumnsView(file: file, columnsDataModel: managerModels.columnsDataModel)
            Spacer()
            valuesView
            Spacer()
            Button("Delete") {
                eraseFileEntries(file: file)
            }
        }.task {
            let file = self.file
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                let result =  ValuesTableProvider(file: file)
                DispatchQueue.main.async {
                    valuesView = ValuesView(valuesTableProvider: result)
                }
            }
        }
    }
    public func eraseFileEntries(file: Files) {
        var predicate = NSPredicate(format: "column2file == %@", file)
        managerModels.columnsDataModel.deleteAllRecords(predicate: predicate)
        predicate = NSPredicate(format: "value2file == %@", file)
        managerModels.valuesDataModel.deleteAllRecords(predicate: predicate)
        predicate = NSPredicate(format: "self == %@", file)
        managerModels.filesDataModel.deleteAllRecords(predicate: predicate)
    }
}

struct FilesView_Previews: PreviewProvider {
    static var previews: some View {
        FilesView(file: ManagerModels().filesDataModel.items.first!)
    }
}
