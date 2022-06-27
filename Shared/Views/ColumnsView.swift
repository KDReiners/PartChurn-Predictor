//
//  ColumnsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI

struct ColumnsView: View {
    var file: Files
    @ObservedObject var columnsDataModel: ColumnsModel
    init(file: Files, columnsDataModel: ColumnsModel) {
        self.file = file
        self.columnsDataModel = columnsDataModel
    }
    
    var body: some View {
        List {
            ForEach($columnsDataModel.items, id: \.self) { column in
                if column.wrappedValue.column2file == file {
                    VStack(alignment: .leading) {
                        Text(column.name.wrappedValue!).font(.subheadline)
                        HStack {
                            Toggle("isIncluded", isOn: column.isincluded.boolBinding).toggleStyle(.checkbox)
                            Toggle("isShown", isOn: column.isshown.boolBinding)
                            Toggle("isTarget", isOn: column.istarget.boolBinding)
                            Text("orderNo")
                            TextField("orderNo", value: column.orderno, formatter: NumberFormatter())
                        }.padding(.bottom, 10)
                    }
                }
            }
        }.onDisappear {
            BaseServices.save()
        }
    }
}

struct ColumnsView_Previews: PreviewProvider {
    static var previews: some View {
        ColumnsView(file: ManagerModels().filesDataModel.items.first!, columnsDataModel: ManagerModels().columnssDataModel)
    }
}
