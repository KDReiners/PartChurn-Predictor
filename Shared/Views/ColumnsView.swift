//
//  ColumnsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI

struct ColumnsView: View {
    var file: Files
    @ObservedObject var columnsDataModel : ColumnsModel
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
                            /// DataType User Setting perhaps later
//                            dataTypePicker(selectedDataType: column.datatype.wrappedValue, selectedColumn: column.wrappedValue)
                            Toggle("isIncluded", isOn: column.isincluded.boolBinding)
                            Toggle("isShown", isOn: column.isshown.boolBinding)
                            Toggle("withDecimalPoint", isOn: column.decimalpoint.boolBinding).disabled(column.datatype.wrappedValue == BaseServices.columnDataTypes.String.rawValue)
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
/// datatype user setting perhaps later
//struct dataTypePicker: View {
//    @State var selectedDataType: Int16
//    @State var selectedColumn: Columns
//
//    var body: some View {
//        Picker(selection: $selectedDataType, label: Text("DataType")) {
//            ForEach(Array(BaseServices.columnDataTypes.allCases), id: \.self) { dataType in
//                Text(String(describing: dataType)).tag(dataType.rawValue)
//            }
//        }.onChange(of: selectedDataType) { tag in selectedColumn.datatype = tag
//            selectedColumn.isuserdefined = true
//        }
//    }
//}

struct ColumnsView_Previews: PreviewProvider {
    static var previews: some View {
        ColumnsView(file: ManagerModels().filesDataModel.items.first!, columnsDataModel: ManagerModels().columnsDataModel)
    }
}
