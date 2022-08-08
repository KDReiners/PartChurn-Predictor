//
//  MlModelFactory.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.08.22.
//

import Foundation
import SwiftUI
import CreateML
class MlDataTableFactory: ObservableObject {
    @Published var loaded = false
    var gridItems: [GridItem]!
    var numRows: Int = 0
    var customColumns = [CustomColumn]()
    var mlDataTable: MLDataTable!
    var unionOfMlDataTables: [MLDataTable]?
    var orderedColumns: [Columns]!
    var selectedColumns: [Columns]?
    var mergedColumns: [Columns]!
    var timeSeries: [[Int]]?
    var mlColumns: [String]?
    
    func filterMlDataTable() -> UnionResult {
        var result: MLDataTable?
        mergedColumns = selectedColumns == nil ? orderedColumns: selectedColumns
        if selectedColumns != nil {
            let additions = orderedColumns.filter { $0.ispartofprimarykey == 1 || $0.istimeseries == 1 || $0.istarget == 1}
            mergedColumns.append(contentsOf: additions)
        }
        self.mlColumns = mergedColumns.map { $0.name!}
        let timeSeriesColumn = self.orderedColumns.filter { $0.istimeseries == 1 }
        let mlTimeSeriesColumn = mlDataTable[(timeSeriesColumn.first?.name!)!]
        if let timeSeries = timeSeries {
            for timeSlices in timeSeries {
                let newCluster = MLTableCluster(columns: mergedColumns)
                for timeSlice in timeSlices {
                    
                    let timeSeriesMask = mlTimeSeriesColumn == timeSlice
                    let newMlDataTable = self.mlDataTable[timeSeriesMask]
                    newCluster.tables.append(newMlDataTable)
                    
                    if unionOfMlDataTables == nil {
                        unionOfMlDataTables = [newMlDataTable] } else {
                            unionOfMlDataTables?.append(newMlDataTable)
                        }
                }
                if result == nil {
                    result = newCluster.construct()
                    self.mlColumns = newCluster.orderedColumns
                } else {
                    result?.append(contentsOf: newCluster.construct())
                }
            }
            self.mlDataTable = result
        }
        let unionResult = UnionResult(mlDataTable: self.mlDataTable, mlColumns:self.mlColumns!)
        return unionResult
    }
    struct UnionResult {
        var mlDataTable: MLDataTable!
        var orderedColumns: [String]!
        init(mlDataTable: MLDataTable, mlColumns: [String]) {
            self.mlDataTable = mlDataTable
            self.orderedColumns = mlColumns
        }
    }
}
