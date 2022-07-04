//
//  ValuesTableProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 04.07.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML

class ValuesTableProvider: ObservableObject {
    var coreDataML: CoreDataML
    var mlDataTable: MLDataTable
    @Published var customColumns = [CustomColumn]()
    var gridItems = [GridItem]()
    var numCols: Int = 0
    var numRows: Int = 0
   
    init(file: Files) {
        self.coreDataML = CoreDataML(model: file.files2model!, files: file)
        self.mlDataTable = coreDataML.mlDataTable
        prepareView()
        numCols = customColumns.count
        numRows = customColumns[0].betterRows.count
    }
    struct model: Identifiable {
        let id = UUID()
        var model: MLModel
        var path: String
    }
    func prepareView() -> Void {
        var rows = [String]()
        for column in self.coreDataML.orderedColumns {
            var newCustomColumn = CustomColumn(title: column.name ?? "Unbekannt", alignment: .trailing)
            var newGridItem: GridItem?
            var newTargetColumn: CustomColumn?
            var newTargetGridItem: GridItem?
            if column.istarget == true {
                newTargetColumn = CustomColumn(title: column.name ?? "Unbekannt" + "_predicted", alignment: .trailing)
                newTargetGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
            }
            let valueType = mlDataTable[column.name!].type
            let mlDataValueFormatter = NumberFormatter()
            mlDataValueFormatter.numberStyle = column.decimalpoint == true ? .decimal : .none
            switch valueType {
            case MLDataValue.ValueType.int:
                rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
                newCustomColumn.alignment = .trailing
                newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
            case MLDataValue.ValueType.double:
                rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
                newCustomColumn.alignment = .trailing
                newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
            case MLDataValue.ValueType.string:
                rows = Array.init(mlDataTable[column.name!].map( { $0.stringValue! }))
                column.datatype = BaseServices.columnDataTypes.String.rawValue
                newCustomColumn.alignment = .leading
                newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
            default:
                print("error")
            }
            BaseServices.save()
            newCustomColumn.betterRows.append(contentsOf: rows)
            newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
            self.customColumns.append(newCustomColumn)
            self.gridItems.append(newGridItem!)
            if newTargetColumn != nil {
                self.customColumns.append(newTargetColumn!)
                self.gridItems.append(newTargetGridItem!)
            }
        }
    }
}
