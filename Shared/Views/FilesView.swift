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
    var columnsModelData: ColumnsModel?
    init(file: Files) {
        self.file = file
        
    }
    
    var body: some View {
        ColumnsView(file: file, columnsDataModel: managerModels.columnssDataModel)
    }
}

struct FilesView_Previews: PreviewProvider {
    static var previews: some View {
        FilesView(file: ManagerModels().filesDataModel.items.first!)
    }
}
