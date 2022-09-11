//
//  FilesView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI

struct FilesView: View {
    @EnvironmentObject var managerModels: ManagerModels
    @ObservedObject var columnsDataModel: ColumnsModel
    @ObservedObject var columnViewModel: ColumnsViewModel
    var file: Files
 
    init(file: Files, columnsDataModel: ColumnsModel) {
        self.file = file
        self.columnsDataModel = columnsDataModel
        self.columnViewModel = ColumnsViewModel(columns: columnsDataModel.items, file: file)
    }
    
    var body: some View {
        VStack {
            ColumnsView(file: file, columnsViewModel: self.columnViewModel).frame(minHeight: 100, idealHeight: 150, maxHeight: 200)
            Spacer()
            ValuesView(file: self.file)
            Spacer()
            Button("Delete") {
                eraseFileEntries(file: file)
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
        FilesView(file: ManagerModels().filesDataModel.items.first!, columnsDataModel: ManagerModels().columnsDataModel)
    }
}
