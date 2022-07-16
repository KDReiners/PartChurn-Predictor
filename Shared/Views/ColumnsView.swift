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
    
    init(columns: [Columns], file: Files) {
        self.cognitionType = filesDataModel.getCognitionType(file: file)
       
        for column in columns.filter( { $0.column2file == file }) {
            let newObservedColumn = ObservedColumn(column: column)
            self.observedColumns.append(newObservedColumn)
        }
    }
    
}
struct ColumnsView: View {
    var file: Files
    @ObservedObject var columnsViewModel: ColumnsViewModel
    init(file: Files, columnsViewModel: ColumnsViewModel) {
        self.file = file
        self.columnsViewModel = columnsViewModel
    }
    
    var body: some View {
        List {
            ForEach($columnsViewModel.observedColumns, id: \.self) { observedColumn in
                Text(observedColumn.column.name.wrappedValue!)
                HStack {
                    Toggle("isPartOfTimeseries", isOn: observedColumn.column.ispartoftimeseries.boolBinding).disabled(observedColumn.disable_ispartoftimeseries.wrappedValue)
                    Toggle("isPartOfPrimaryKey", isOn: observedColumn.column.ispartofprimarykey.boolBinding).disabled(observedColumn.disable_ispartofprimarykey.wrappedValue)
                    Toggle("isShown", isOn: observedColumn.column.isshown.boolBinding).disabled(observedColumn.disable_isshown.wrappedValue)
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
