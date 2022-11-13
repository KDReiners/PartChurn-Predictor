//
//  cluster.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 13.11.22.
//

import Foundation
import CreateML
class MLTableCluster {
    var columns: [Columns]
    var tables = [MLDataTable]()
    var columnsDataModel: ColumnsModel
    var model: Models
    var lastOrderno = -1
    var orderedColumns: [String] {
        get {
            var result = [String] ()
            result.append(columnsDataModel.primaryKeyColumn!.name!)
            
            for column in columnsDataModel.timelessInputColumns.sorted(by: { $0.orderno < $1.orderno }) {
                result.append(column.name!)
            }
            if columnsDataModel.timeStampColumn != nil {
                result.append(columnsDataModel.timeStampColumn!.name!)
            }
            for i in 0..<tables.count - 1 {
                let suffix = -tables.count + 1 + i
                for column in columnsDataModel.timedependantInputColums {
                    let newName = column.name! + String(suffix)
                    result.append(newName)
                }
            }
            for column in columnsDataModel.timedependantInputColums {
                result.append(column.name!)
            }
            for column in columnsDataModel.targetColumns.sorted(by: { $0.orderno < $1.orderno }) {
                result.append(column.name!)
            }
            
            return result
        }
    }
    init(columns: [Columns], model: Models) {
        self.columns = columns
        self.model = model
        columnsDataModel = ColumnsModel(columnsFilter: self.columns, model: self.model)
        print("columnsdataModel instatiated for table cluster")
    }
    internal func construct() -> MLDataTable {
        var prePeriodsTable: MLDataTable?
        var result: MLDataTable?
        let columnNames = columns.map({ $0.name! })
        for i in 0..<tables.count - 1 {
            
            let suffix = -tables.count + 1 + i
            for column in tables[i].columnNames {
                if !columnNames.contains(column) {
                    tables[i].removeColumn(named: column)
                }
            }
            for column in columnsDataModel.timedependantInputColums {
                let newName = column.name! + String(suffix)
                tables[i].renameColumn(named: column.name!, to: newName)
            }
            for column in columnsDataModel.timelessInputColumns {
                tables[i].removeColumn(named: column.name!)
            }
            for column in columnsDataModel.targetColumns {
                tables[i].removeColumn(named: column.name!)
            }
            if columnsDataModel.timeStampColumn != nil {
                tables[i].removeColumn(named: columnsDataModel.timeStampColumn!.name!)
            }
            if prePeriodsTable == nil {
                prePeriodsTable = tables[i]
            } else {
                prePeriodsTable = prePeriodsTable?.join(with: tables[i], on: (columnsDataModel.primaryKeyColumn?.name!)!, type: .inner)
            }
        }
        for column in tables[tables.count - 1].columnNames {
            if !columnNames.contains(column) {
                tables[tables.count - 1].removeColumn(named: column)
            }
        }
        result = prePeriodsTable?.join(with: tables[tables.count - 1], on: columnsDataModel.primaryKeyColumn!.name!, type: .inner)
        return result!
    }
}
