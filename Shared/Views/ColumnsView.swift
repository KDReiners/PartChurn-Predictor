//
//  ColumnsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI
class ViewModel: ObservableObject {
    var filesDataModel = FilesModel()
    @ObservedObject var columnsDataModel: ColumnsModel
    @Published var observedColumns = [ObservedColumn]()
    var cognitionType: BaseServices.cognitionTypes = .cognitionError
    class ObservedColumn: Hashable, ObservableObject {
        static func == (lhs: ViewModel.ObservedColumn, rhs: ViewModel.ObservedColumn) -> Bool {
            lhs.column.name == rhs.column.name
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(column.name)
        }
        var column: Columns
        @Published var isOn_isshown: Bool = true
        @Published var isOn_ispartoftimeseries: Bool = true
        @Published var isOn_ispartofprimarykey: Bool = true
        
        @Published var disable_ispartofprimarykey: Bool = false
        @Published var disable_ispartoftimeseries: Bool = false
        @Published var disable_isshown: Bool = false
        init(column: Columns) {
            self.column = column
            resolve()
        }
        private func resolve() {
            let pattern = column.ispartoftimeseries!.stringValue + column.ispartofprimarykey!.stringValue + column.isshown!.stringValue
            print("Pattern: \(pattern)")
            switch pattern {
                /// no values
            case "000":
                print("nothing is set")
            case "001":
                print("only is shown was set")
            case "010":
                print("only isPartOfPrimaryKey is set")
            case "011":
                print("is shown and isPartOfPrimaryKey is set")
            case "100":
                print("timeseries is set")
            case "101":
                print("timeseries and is shown is set")
            case "110":
                print("timeseries and ispartofprimarykey")
            case "111":
                print("all is set")
                
            default: print("error")
            }
        }
    }
    
    init(columns: [Columns], file: Files, columnsDataModel: ColumnsModel) {
        self.cognitionType = filesDataModel.getCognitionType(file: file)
        self.columnsDataModel = columnsDataModel
        for column in columns.filter( { $0.column2file == file }) {
            let newObservedColumn = ObservedColumn(column: column)
            self.observedColumns.append(newObservedColumn)
        }
    }
    
}
struct ColumnsView: View {
    var file: Files
    @ObservedObject var columnsDataModel : ColumnsModel
    @ObservedObject var viewModel: ViewModel
    init(file: Files, columnsDataModel: ColumnsModel, columnsViewModel: ViewModel) {
        self.file = file
        self.columnsDataModel = columnsDataModel
        self.viewModel = columnsViewModel
    }
    
    var body: some View {
        List {
            ForEach($viewModel.observedColumns, id: \.self) { observedColumn in
                Text(observedColumn.column.name.wrappedValue!)
                HStack {
                    Toggle("isPartOfTimeseries", isOn: observedColumn.column.ispartoftimeseries.boolBinding).disabled(observedColumn.disable_ispartoftimeseries.wrappedValue)
                    Toggle("isPartOfPrimaryKey", isOn: observedColumn.column.ispartofprimarykey.boolBinding).disabled(observedColumn.disable_ispartofprimarykey.wrappedValue)
                    Toggle("isShown", isOn: observedColumn.column.isshown.boolBinding).disabled(observedColumn.disable_isshown.wrappedValue)
                }
            }
            //            ForEach($columnsDataModel.items, id: \.self) { column in
            //                if column.wrappedValue.column2file == file {
            //                    VStack(alignment: .leading) {
            //                        Text(column.name.wrappedValue!).font(.subheadline)
            //                        HStack {
            //                            /// DataType User Setting perhaps later
            ////                            dataTypePicker(selectedDataType: column.datatype.wrappedValue, selectedColumn: column.wrappedValue)
            //                            Toggle("isPartOfPrimaryKey", isOn: column.ispartofprimarykey.boolBinding)
            //                            Toggle("isIncluded", isOn: column.isincluded.boolBinding)
            //                            Toggle("isShown", isOn: column.isshown.boolBinding)
            //                            Toggle("withDecimalPoint", isOn: column.decimalpoint.boolBinding).disabled(column.datatype.wrappedValue == BaseServices.columnDataTypes.String.rawValue)
            //                            Toggle("isTarget", isOn: column.istarget.boolBinding)
            //                            Text("orderNo")
            //                            TextField("orderNo", value: column.orderno, formatter: NumberFormatter())
            //                        }.padding(.bottom, 10)
            //                    }
            //                }
            //            }
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

//struct ColumnsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ColumnsView(file: ManagerModels().filesDataModel.items.first!, columnsDataModel: ManagerModels().columnsDataModel)
//    }
//}
