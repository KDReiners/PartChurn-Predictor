//
//  mlTableSection.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 07.08.22.
//

import Foundation
import CoreML
import CreateML
class MLTableCluster {
    var lastOrderno = -1
    var orderedColumns: [String] {
        get {
            var result = [String] ()
            result.append(joinColumn.name!)
            
            for column in timelessInputColumns.sorted(by: { $0.orderno < $1.orderno }) {
                result.append(column.name!)
            }
            result.append(timeStampColumn.name!)
            for i in 0..<tables.count - 1 {
                let suffix = -tables.count + 1 + i
                for column in timedependantInputColums {
                    let newName = column.name! + String(suffix)
                    result.append(newName)
                }
            }
            for column in timedependantInputColums {
                result.append(column.name!)
            }
            for column in targetColumns.sorted(by: { $0.orderno < $1.orderno }) {
                result.append(column.name!)
            }
            
            return result
        }
    }
    var columns: [Columns]
    
    var timelessInputColumns: [Columns] {
        get {
            return self.columns.filter { $0.ispartofprimarykey == 0 && $0.istimeseries == 0 && $0.ispartoftimeseries == 0 && $0.istarget == 0}
        }
    }
    
    var timedependantInputColums: [Columns] {
        get {
            return self.columns.filter { $0.ispartofprimarykey == 0 &&  $0.istimeseries == 0 && $0.ispartoftimeseries == 1 && $0.istarget == 0}
        }
    }
    
    var targetColumns: [Columns] {
        get {
            return self.columns.filter { $0.istarget == 1}
        }
    }
    
    var timelessTargetColumns: [Columns] {
        get {
            return self.columns.filter { $0.ispartofprimarykey == 0 && $0.istimeseries == 0 && $0.ispartoftimeseries == 0 && $0.istarget == 1}
        }
    }
    
    var timedependantTargetColums: [Columns] {
        get {
            return self.columns.filter { $0.ispartofprimarykey == 0 &&  $0.istimeseries == 0 && $0.ispartoftimeseries == 1 && $0.istarget == 1}
        }
    }
    
    var joinColumn: Columns {
        get {
            return self.columns.first(where: { $0.ispartofprimarykey == 1 })!
        }
    }
    
    var timeStampColumn: Columns {
        get {
            let result = self.columns.filter { $0.istimeseries == 1}
            if result.count == 1 {
                return result.first!
            } else {
                print("There must be only one timeSeries column in mlDataTable")
                fatalError()
            }
        }
    }
    var tables = [MLDataTable]()
    init(columns: [Columns]) {
        self.columns = columns
    }
    internal func construct() -> MLDataTable {
        var prePeriodsTable: MLDataTable?
        var result: MLDataTable?
        for i in 0..<tables.count - 1 {
            let suffix = -tables.count + 1 + i
            for column in timedependantInputColums {
                let newName = column.name! + String(suffix)
                tables[i].renameColumn(named: column.name!, to: newName)
            }
            for column in timelessInputColumns {
                tables[i].removeColumn(named: column.name!)
            }
            for column in targetColumns {
                tables[i].removeColumn(named: column.name!)
            }
            tables[i].removeColumn(named: timeStampColumn.name!)
            if prePeriodsTable == nil {
                prePeriodsTable = tables[i]
            } else {
                prePeriodsTable = prePeriodsTable?.join(with: tables[i], on: joinColumn.name!, type: .inner)
            }
        }
        result = prePeriodsTable?.join(with: tables[tables.count - 1], on: joinColumn.name!, type: .inner)
        return result!
    }
}
