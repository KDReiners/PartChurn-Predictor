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
    @Published var gridItems: [GridItem]!
    var numRows: Int = 0
    var customColumns = [CustomColumn]()
    var mlDataTable: MLDataTable!
    var mlDataTableRaw: MLDataTable!
    var unionOfMlDataTables: [MLDataTable]?
    var orderedColumns: [Columns]!
    var selectedColumns: [Columns]?
    var mergedColumns: [Columns]!
    var timeSeries: [[Int]]?
    var mlColumns: [String]?
    var valuesTableProvider: ValuesTableProvider!
    var filterViewProvider: FilterViewProvider!
    func updateTableProvider() {
        tableProvider(mlDataTable: mlDataTable, orderedColums: mlColumns!) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableFactory: self)
                }
                self.loaded = true
            }
        }
    }
    
    func buildMlDataTable() -> UnionResult {
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
        updateTableProvider()
        let unionResult = UnionResult(mlDataTable: self.mlDataTable, mlColumns:self.mlColumns!)
        self.mlDataTableRaw = mlDataTableRaw == nil ? mlDataTable: self.mlDataTableRaw
        return unionResult
    }
    func filterMlDataTable(filterDict: Dictionary<String, String>) {
        if filterDict.count > 0 {
            self.mlDataTable = mlDataTable[mlDataTable["S_CUSTNO"] == 1010180]
        } else {
            self.mlDataTable = mlDataTableRaw
        }
        updateTableProvider()
    }
    func tableProvider(mlDataTable: MLDataTable, orderedColums: [String], returnCompletion: @escaping (ValuesTableProvider) -> () ) {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(mlDataTable: mlDataTable, orderedColumns: orderedColums)
                DispatchQueue.main.async {
                    self.gridItems = result.gridItems
                    self.customColumns = result.customColumns
                    self.numRows = self.customColumns.count > 0 ? self.customColumns[0].rows.count:0
                    returnCompletion(result as ValuesTableProvider)
                }
            }
        }
    }
}
struct UnionResult {
    var mlDataTable: MLDataTable!
    var orderedColumns: [String]!
    init(mlDataTable: MLDataTable, mlColumns: [String]) {
        self.mlDataTable = mlDataTable
        self.orderedColumns = mlColumns
    }
}
