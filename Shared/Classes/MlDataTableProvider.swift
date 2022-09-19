//
//  MlModelFactory.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.08.22.
//

import Foundation
import SwiftUI
import CreateML
class MlDataTableProvider: ObservableObject {
    // MARK: Init
    @Published var loaded = false
    @Published var gridItems: [GridItem]!
    @Published var valuesTableProvider: ValuesTableProvider?
    @Published var tableStatistics: TableStatistics?
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
    var model: Models?
    var filterViewProvider: FilterViewProvider!
    var prediction: Predictions?
    var regressorName: String?
    
    init() {
        self.tableStatistics = TableStatistics()
    }
    // MARK: - Async Calls for CoreMl
    internal func updateTableProviderForFiltering() {
        tableProvider(mlDataTable: self.mlDataTable, orderedColums: mlColumns!, selectedColumns: mergedColumns, filter: true) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableFactory: self)
                }
                self.loaded = true
            }
        }
    }
    internal func updateTableProvider() {
        tableProvider(mlDataTable: mlDataTableRaw, orderedColums: mlColumns!, selectedColumns: mergedColumns, prediction: prediction, regressorName: regressorName) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                self.tableStatistics?.absolutRowCount = provider.mlDataTable.rows.count
                self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
                self.mlDataTableRaw = provider.mlDataTable
                self.mlDataTable = self.mlDataTableRaw
                if provider.targetValues.count > 0 {
//                    self.tableStatistics?.targetStatistics =
                    self.updateStatisticsProvider(targetValues: provider.targetValues, predictedColumnName: provider.predictedColumnName)
                }
                self.mlColumns = provider.orderedColNames
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableFactory: self)
                }
                self.loaded = true
            }
        }
    }
    // MARK: - related TableProvider coreMl
    func tableProvider(mlDataTable: MLDataTable, orderedColums: [String], selectedColumns: [Columns]?, prediction: Predictions? = nil, regressorName: String? = nil, filter: Bool? = false , returnCompletion: @escaping (ValuesTableProvider) -> () ) {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(mlDataTable: mlDataTable, orderedColNames: orderedColums, selectedColumns: selectedColumns,  prediction: prediction, regressorName: regressorName, filter: filter)
                DispatchQueue.main.async {
                    self.gridItems = result.gridItems
                    self.customColumns = result.customColumns
                    self.numRows = self.customColumns.count > 0 ? self.customColumns[0].rows.count:0
                    returnCompletion(result as ValuesTableProvider)
                }
            }
        }
    }
    // MARK: - Async call for file inspection
    func updateTableProvider(file: Files) {
        let columns = file.file2columns
        self.mlColumns = (columns?.allObjects as! [Columns]).sorted(by: { $0.orderno < $1.orderno }).map({ $0.name! })
        tableProvider(file: file ) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                self.tableStatistics?.absolutRowCount = provider.mlDataTable.rows.count
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableFactory: self)
                }
                self.loaded = true
            }
        }
    }
    // MARK: - related Tableprovider file
    func tableProvider(file: Files, returnCompletion: @escaping (ValuesTableProvider) -> () ) {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(file: file)
                DispatchQueue.main.async {
                    self.mlDataTable = result.mlDataTable
                    self.gridItems = result.gridItems
                    self.customColumns = result.customColumns
                    self.numRows = self.customColumns.count > 0 ? self.customColumns[0].rows.count:0
                    self.mlDataTableRaw = self.mlDataTableRaw == nil ? self.mlDataTable: self.mlDataTableRaw
                    returnCompletion(result as ValuesTableProvider)
                }
            }
        }
    }
    func updateStatisticsProvider(targetValues: [String : Int], predictedColumnName: String) {
        if self.regressorName != nil {
            statisticsProvider(targetValues: targetValues, predictedColumnName: predictedColumnName) { provider in
                DispatchQueue.main.async { [self] in
                    self.tableStatistics?.absolutRowCount = provider
                }
            }
        }
    }
    // MARK: - async call for statistics
    func statisticsProvider(targetValues: [String : Int], predictedColumnName: String, completion: @escaping (Int) -> ()) {
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                self.resolveTargetValues(targetValues: targetValues, predictedColumnName: predictedColumnName)
                completion(22)
            }
        }
    }
    // MARK: - related statistics provider
    func resolveTargetValues(targetValues: [String: Int], predictedColumnName: String) -> [TargetStatistics]? {
        let mlTargetColumn = mlDataTable["ALIVE"]
        var predictionMask =  mlTargetColumn == 0
        var breakMask = mlTargetColumn != 0
        let  mlPredictionColumn = mlDataTable[predictedColumnName]
        let predictionTable = mlDataTable[predictionMask].sort(columnNamed: predictedColumnName, byIncreasingOrder: true)
        let targetCount = predictionTable.rows.count
        let otherCount = self.mlDataTable.rows.count - targetCount
        let threshold = (0.1 * Double(targetCount)).rounded()
        find(trial: (targetCount / 2), nearestHighValue: targetCount)
        func find(trial: Int, nearestLowValue: Int = 0, nearestHighValue: Int = 0, bestRelationValue: Double = 0, bestRelationPredictionValue: Double = 0 ) {
            var value =   predictionTable.rows[Int(trial)][predictedColumnName]?.doubleValue
            var lastBestRelationValue = bestRelationValue
            var lastBestPredictionValue = bestRelationPredictionValue
            let j = (value! * 10000).rounded() / 10000
            predictionMask = mlPredictionColumn <= j && mlTargetColumn == 0
            breakMask = mlPredictionColumn <= j && mlTargetColumn != 0
            let foundClean = mlDataTable[predictionMask].rows.count
            let foundDirty = self.mlDataTable[breakMask].rows.count
            print("nearestLowValue: " + String(nearestLowValue))
            print("nearestHighValue: " + String(nearestHighValue))
            if Double(foundClean / foundDirty) > lastBestRelationValue {
                lastBestRelationValue = Double(foundClean / foundDirty)
                lastBestPredictionValue = j
            }
            print("lastBestRelation: " + String(lastBestRelationValue))
            if nearestHighValue - nearestLowValue > 1 {
                if foundDirty < Int(threshold) {
                    find(trial: (nearestHighValue + trial) / 2, nearestLowValue: trial, nearestHighValue: nearestHighValue, bestRelationValue: lastBestRelationValue, bestRelationPredictionValue: lastBestPredictionValue)
                } else {
                    find(trial: (trial + nearestLowValue) / 2, nearestLowValue: nearestLowValue, nearestHighValue: trial, bestRelationValue: lastBestRelationValue, bestRelationPredictionValue: lastBestPredictionValue)
                }
            }
            breakMask = mlPredictionColumn <= lastBestPredictionValue && mlTargetColumn != 0
            let bestPredictionValuePollution = self.mlDataTable[breakMask].rows.count
            print(nearestLowValue)
        }
        return nil
    }
    func buildMlDataTable() -> UnionResult {
        var result: MLDataTable?
        self.filterViewProvider = nil
        mergedColumns = selectedColumns == nil ? orderedColumns: selectedColumns
        if selectedColumns != nil {
            let additions = orderedColumns.filter { $0.ispartofprimarykey == 1 || $0.istimeseries == 1 || $0.istarget == 1}
            mergedColumns.append(contentsOf: additions)
        }
        self.mlColumns = mergedColumns.map { $0.name!}
        let timeSeriesColumn = self.orderedColumns.filter { $0.istimeseries == 1 }
        if timeSeriesColumn.count > 0 {
            let  mlTimeSeriesColumn = mlDataTable[(timeSeriesColumn.first?.name)!]
            if let timeSeries = timeSeries {
                for timeSlices in timeSeries {
                    let newCluster = MLTableCluster(columns: mergedColumns)
                    for timeSlice in timeSlices.sorted(by: { $0 < $1 }) {
                        
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
                self.mlDataTable = result?.dropMissing()
            }
        }
        let unionResult = UnionResult(mlDataTable: self.mlDataTable, mlColumns:self.mlColumns!)
        self.mlDataTableRaw = mlDataTableRaw == nil ? mlDataTable: self.mlDataTableRaw
        return unionResult
    }
    func filterMlDataTable(filterDict: Dictionary<String, String>) {
        self.mlDataTable = mlDataTableRaw
        if filterDict.count > 0 {
            for key in filterDict.keys {
                self.mlDataTable = setFilterForColumn(mlDataTable: self.mlDataTable, columnName: key, value: filterDict[key]!)
            }
        } else {
            self.mlDataTable = mlDataTableRaw
        }
        updateTableProviderForFiltering()
    }
    func setFilterForColumn(mlDataTable: MLDataTable, columnName: String, value: String) ->MLDataTable {
        var result = mlDataTable
        let column = mlDataTable[columnName]
        switch column.type {
        case MLDataValue.ValueType.int:
            result = mlDataTable[mlDataTable[columnName] == Int(value)!]
        case MLDataValue.ValueType.double:
            result = mlDataTable[mlDataTable[columnName] > Double(value)! - 0.01]
            result = result[result[columnName] < Double(value)! + 0.01]
        case MLDataValue.ValueType.string:
            result = mlDataTable[mlDataTable[columnName] == value]
        default:
            print("error")
        }
        
        return result
    }
    struct TableStatistics {
        var absolutRowCount = 0
        var filteredRowCount = 0
        var targetStatistics: [TargetStatistics]?
        
    }
    struct TargetStatistics {
        var targetValue = 0
        var instancesCount = 0
        var threshold: Float = 0.00000
        
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
class MLTableCluster {
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
    var columns: [Columns]
    var tables = [MLDataTable]()
    var columnsDataModel: ColumnsModel!
    var model: Models!
    init(columns: [Columns]) {
        self.columns = columns
        self.model = columns.first?.column2model
        columnsDataModel = ColumnsModel(columnsFilter: self.columns)
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
                prePeriodsTable = prePeriodsTable?.join(with: tables[i], on: (columnsDataModel!.primaryKeyColumn?.name)!, type: .inner)
            }
        }
        for column in tables[tables.count - 1].columnNames {
            if !columnNames.contains(column) {
                tables[tables.count - 1].removeColumn(named: column)
            }
        }
        result = prePeriodsTable?.join(with: tables[tables.count - 1], on: columnsDataModel!.primaryKeyColumn!.name!, type: .inner)
        return result!
    }
}
