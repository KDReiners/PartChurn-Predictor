//
//  Scenario.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 25.07.22.
//

import Foundation
import CreateML
import CoreML
import SwiftUI
struct Scenario: Hashable {
    static func == (lhs: Scenario, rhs: Scenario) -> Bool {
        lhs.includedColumns == rhs.includedColumns    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(includedColumns)
    }
    var columNames: String!
    var includedColumns: [[Columns]]
    var timeSeries: [[Int]]
    var mlDataTable: MLDataTable
    init(includedColumns: [[Columns]], timeSeries: [[Int]], baseTable: MLDataTable) {
        self.includedColumns = includedColumns
        self.timeSeries = timeSeries
        self.mlDataTable = baseTable
    }
    internal func levelIncludedColumns() -> Int
    {
        let result = includedColumns.first == nil ? 0 : includedColumns.first!.count
        return result
    }
    internal func levelTimeSeries() -> Int
    {
        let result = timeSeries.first == nil ? 0 : timeSeries.first!.count
        return result
    }
    internal func listOfTimeSeriesCombinations() -> [String] {
        var result = [String]()
        for timeSeriesElements in timeSeries {
            var names = ""
            for slice in timeSeriesElements {
                names += names.isEmpty ? String(slice) : ", " + String(slice)
            }
            result.append(names)
        }
        return result
        
    }
    internal func listOfColumnNames() -> [String] {
        var result = [String]()
        
        for columnArray in includedColumns {
            var names = ""
            for column in columnArray {
                names += names.isEmpty ? column.name! : ", " + column.name!
            }
            result.append(names)
        }
        return result
    }
}
