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
    var coreDataML: CoreDataML!
    var mlDataTable: MLDataTable!
    var customColumns = [CustomColumn]()
    var gridItems = [GridItem]()
    var numCols: Int = 0
    var numRows: Int = 0
    init(mlDataTable: MLDataTable, orderedColumns: [Columns]) {
        self.mlDataTable = mlDataTable
        prepareView(orderedColumns: orderedColumns)
    }
    init(file: Files?) {
        self.coreDataML = CoreDataML(model: file?.files2model, files: file)
        self.mlDataTable = coreDataML.mlDataTable
        prepareView()
        numCols = customColumns.count
        numRows = numCols > 0 ?customColumns[0].betterRows.count : 0
    }
    struct model: Identifiable {
        let id = UUID()
        var model: MLModel
        var path: String
    }
    func prepareView(orderedColumns: [Columns]) -> Void {
        var rows = [String]()
        for column in  orderedColumns {
            let columnName = column.alias!
            var newCustomColumn = CustomColumn(title: columnName, alignment: .trailing)
            var newGridItem: GridItem?
            let valueType = mlDataTable[columnName].type
            let mlDataValueFormatter = NumberFormatter()
            switch valueType {
            case MLDataValue.ValueType.int:
                rows = Array.init(mlDataTable[columnName].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
                newCustomColumn.alignment = .trailing
                newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
            case MLDataValue.ValueType.double:
                rows = Array.init(mlDataTable[columnName].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
                newCustomColumn.alignment = .trailing
                newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
            case MLDataValue.ValueType.string:
                rows = Array.init(mlDataTable[columnName].map( { $0.stringValue! }))
                newCustomColumn.alignment = .leading
                newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
            default:
                print("error")
            }
            newCustomColumn.betterRows.append(contentsOf: rows)
            newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
            self.customColumns.append(newCustomColumn)
            self.gridItems.append(newGridItem!)
        }
    }
    func prepareView() -> Void {
        var rows = [String]()
        for column in self.coreDataML.orderedColumns {
            if column.isshown! == 1 {
                var newCustomColumn = CustomColumn(title: column.name ?? "Unbekannt", alignment: .trailing)
                var newGridItem: GridItem?
                let valueType = mlDataTable[column.name!].type
                let mlDataValueFormatter = NumberFormatter()
                mlDataValueFormatter.numberStyle = column.decimalpoint == true ? .decimal : .none
                switch valueType {
                case MLDataValue.ValueType.int:
                    rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
                    newCustomColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                    column.datatype = BaseServices.columnDataTypes.Int.rawValue
                case MLDataValue.ValueType.double:
                    rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
                    newCustomColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
                    column.datatype = BaseServices.columnDataTypes.Double.rawValue
                case MLDataValue.ValueType.string:
                    rows = Array.init(mlDataTable[column.name!].map( { $0.stringValue! }))
                    newCustomColumn.alignment = .leading
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
                    column.datatype = BaseServices.columnDataTypes.String.rawValue
                default:
                    print("error")
                }
                newCustomColumn.betterRows.append(contentsOf: rows)
                newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                self.customColumns.append(newCustomColumn)
                self.gridItems.append(newGridItem!)
            }
        }
    }
}
