//
//  FilesView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI

struct FilesView: View {
    var file: Files
    @EnvironmentObject var managerModels: ManagerModels
    init(file: Files) {
        self.file = file

    }
    
    var body: some View {
        ColumnsView(file: file, columnsDataModel: managerModels.columnssDataModel)
        Spacer()
        Button("Delete") {
            eraseFileEntries(file: file)
        }
    }
    public func eraseFileEntries(file: Files) {
        var predicate = NSPredicate(format: "column2file == %@", file)
        managerModels.columnssDataModel.deleteAllRecords(predicate: predicate)
        predicate = NSPredicate(format: "self == %@", file)
        managerModels.filesDataModel.deleteAllRecords(predicate: predicate)
        predicate = NSPredicate(format: "value2file == %@", file)
        managerModels.valuessDataModel.deleteAllRecords(predicate: predicate)
    }
}

struct FilesView_Previews: PreviewProvider {
    static var previews: some View {
        FilesView(file: ManagerModels().filesDataModel.items.first!)
    }
}
