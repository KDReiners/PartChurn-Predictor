//
//  ColumnsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.06.22.
//

import SwiftUI
class ColumnsViewModel: ObservableObject {
    var filesDataModel = FilesModel()
    @Published var observedColumns = [ObservedColumn]()
    var cognitionType: BaseServices.cognitionTypes = .cognitionError
    class ObservedColumn: Hashable, ObservableObject {
        static func == (lhs: ColumnsViewModel.ObservedColumn, rhs: ColumnsViewModel.ObservedColumn) -> Bool {
            lhs.column.name == rhs.column.name
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(column.name)
        }
        var column: Columns { willSet
            {
                resolve()
            }
        }
        var cognitionType: BaseServices.cognitionTypes
        var columnInfoText: String!
        @Published var disable_ispartofprimarykey: Bool = false
        @Published var disable_istimeseries: Bool = false
        @Published var disable_isshown: Bool = false
        init(column: Columns, cognitionType: BaseServices.cognitionTypes) {
            self.column = column
            self.cognitionType = cognitionType
            resolve()
        }
        private var setInfoType: String {
            get {
                var result = ""
                if self.cognitionType == .cognitionSource {
                    result = self.column.ispartofprimarykey == 0 ? "Input" : "Explaination"
                    result = self.column.istimeseries == 1 ? result + " timeseries" : result
                    column.isincluded = column.ispartofprimarykey == 0 ? 1: 0
                    column.istarget = 0
                }
                if self.cognitionType == .cognitionObject {
                    result = self.column.ispartofprimarykey == 0 ? "Target" : "Explaination"
                    result = self.column.istimeseries == 1 ? result + " timeseries" : result
                    column.istarget = column.ispartofprimarykey == 0 ? 1: 0
                    column.isincluded = 0
                }
                return result
            }
        }
        
        private func resolve() {
            self.columnInfoText = setInfoType
            let pattern = column.istimeseries!.stringValue + column.ispartofprimarykey!.stringValue + column.isshown!.stringValue
            print("Pattern: \(pattern)")
            switch pattern {
                /// no values
            case "000":
                self.disable_istimeseries = false
                self.disable_ispartofprimarykey = false
                self.disable_isshown = false
                print("nothing is set")
            case "001":
                self.disable_istimeseries = false
                self.disable_ispartofprimarykey = false
                self.disable_isshown = false
                print("isShown")
            case "010":
                print("isPartOfPrimaryKey")
                self.disable_istimeseries = true
                self.disable_isshown = false
                self.disable_ispartofprimarykey = false
                
            case "011":
                print("isShown & isPartOfPrimaryKey")
                self.disable_istimeseries = true
                self.disable_isshown = false
                self.disable_ispartofprimarykey = false
            case "100":
                print("timeSeries")
                self.column.isshown = 1
                self.disable_ispartofprimarykey = true
                self.disable_isshown = true
                
            case "101":
                print("timeseries and is shown is set")
                self.disable_isshown = true
                self.disable_ispartofprimarykey = true
            case "110":
                print("timeseries and ispartofprimarykey")
            case "111":
                print("all is set")
                
            default: print("error")
            }
        }
    }
    
    init(columns: [Columns], file: Files) {
        self.cognitionType = filesDataModel.getCognitionType(file: file)
        
        for column in columns.filter( { $0.column2file == file }) {
            let newObservedColumn = ObservedColumn(column: column, cognitionType: self.cognitionType)
            self.observedColumns.append(newObservedColumn)
        }
    }
    
}
struct ColumnsView: View {
    var file: Files
    @ObservedObject var columnsViewModel: ColumnsViewModel
    @ObservedObject var columnsDataModel = ColumnsModel()
    init(file: Files, columnsViewModel: ColumnsViewModel) {
        self.file = file
        self.columnsViewModel = columnsViewModel
    }
    
    var body: some View {
        List {
            ForEach($columnsViewModel.observedColumns, id: \.self) { observedColumn in

                    HStack(alignment: .top, spacing: 20) {
                        Text(observedColumn.column.name.wrappedValue!).bold().frame(width: 150, alignment: .leading)
                        Toggle("isTimeSeries", isOn: observedColumn.column.istimeseries.boolBinding).disabled(observedColumn.disable_istimeseries.wrappedValue)
                        Toggle("isPartOfSeries", isOn: observedColumn.column.ispartoftimeseries.boolBinding)
                        Toggle("isPartOfPrimaryKey", isOn: observedColumn.column.ispartofprimarykey.boolBinding).disabled(observedColumn.disable_ispartofprimarykey.wrappedValue)
                        Toggle("isShown", isOn: observedColumn.column.isshown.boolBinding).disabled(observedColumn.disable_isshown.wrappedValue)
                        Text(observedColumn.columnInfoText.wrappedValue).frame(width: 150)
                        Text("OrderNo").bold()
                        TextField("", value: observedColumn.column.orderno, format: .number)
                    }
                }
        }.onDisappear {
            BaseServices.save()
        }
    }
}

struct ColumnsView_Previews: PreviewProvider {
    static var previews: some View {
        ColumnsView(file: ManagerModels().filesDataModel.items.first!, columnsViewModel: ColumnsViewModel(columns: ColumnsModel().items, file:  ManagerModels().filesDataModel.items.first!))
    }
}
