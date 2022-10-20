//
//  MlModelFactory.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.08.22.
//

import Foundation
import SwiftUI
import CreateML
import CoreData
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
    internal func sizeOfHeaders() -> Int {
        var result = 0
        for column in mlColumns! {
            result += column.count
        }
        return result
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
    internal func updateTableProviderForStatistics(completion: @escaping () ->()) {
        tableProvider(mlDataTable: mlDataTableRaw, orderedColums: mlColumns!, selectedColumns: mergedColumns, prediction: prediction, regressorName: regressorName) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                self.tableStatistics?.absolutRowCount = provider.mlDataTable.rows.count
                self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
                self.mlDataTableRaw = provider.mlDataTable
                self.mlDataTable = self.mlDataTableRaw
                self.mlColumns = provider.orderedColNames
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableFactory: self)
                }
                if provider.targetValues.count > 0 {
//                    self.ableStatistics?.targetStatistics =
                    self.updateStatisticsProvider(targetValues: provider.targetValues, predictedColumnName: provider.predictedColumnName)
                }
                completion()
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
//                    self.ableStatistics?.targetStatistics =
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
                    self.tableStatistics?.targetStatistics.append(provider)
                }
            }
        }
    }
    // MARK: - async call for statistics
    func statisticsProvider(targetValues: [String : Int], predictedColumnName: String, completion: @escaping (TargetStatistics) -> ()) {
        self.tableStatistics?.targetStatistics = [TargetStatistics]()
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                let result = self.resolveTargetValues(targetValues: targetValues, predictedColumnName: predictedColumnName)
                completion(result!)
            }
        }
    }
    // MARK: - related statistics provider
    func resolveTargetValues(targetValues: [String: Int], predictedColumnName: String) -> TargetStatistics? {
        let mlTargetColumn = mlDataTable[predictedColumnName.replacingOccurrences(of: predictionPrefix, with: "")]
        var targetStatistic = TargetStatistics()
        var predictionMask =  mlTargetColumn == 0
        var breakMask = mlTargetColumn != 0
        let  mlPredictionColumn = mlDataTable[predictedColumnName]
        let predictionTable = mlDataTable[predictionMask].sort(columnNamed: predictedColumnName, byIncreasingOrder: true)
        let targetCount = predictionTable.rows.count
        let threshold = (0.1 * Double(targetCount)).rounded()
        find(trial: (targetCount / 2), nearestHighValue: targetCount, targetStatistic: &targetStatistic)
        targetStatistic.targetPopulation = targetCount
        func find(trial: Int, nearestLowValue: Int = 0, nearestHighValue: Int = 0, bestRelationValue: Double = 0, bestRelationPredictionValue: Double = 0, targetStatistic: inout TargetStatistics ){
            let value =   predictionTable.rows[Int(trial)][predictedColumnName]?.doubleValue
            var relationValueAtOptimum = bestRelationValue
            ///  Values for Statistic
            var predictionValueAtOptimum = bestRelationPredictionValue
            var targetsAtOptimum = 0
            var dirtiesAtOptimum = 0
            var targetInstancesCount = 0
            let j = (value! * 10000).rounded() / 10000
            predictionMask = mlPredictionColumn <= j && mlTargetColumn == 0
            breakMask = mlPredictionColumn <= j && mlTargetColumn != 0
            targetInstancesCount = mlDataTable[predictionMask].rows.count
            let foundDirty = self.mlDataTable[breakMask].rows.count
            let devisor = foundDirty == 0 ? 1: foundDirty
            if Double(targetInstancesCount / devisor) > relationValueAtOptimum {
                targetsAtOptimum = targetInstancesCount
                dirtiesAtOptimum = foundDirty
                relationValueAtOptimum = Double(targetInstancesCount / devisor)
                predictionValueAtOptimum = j
            }
            if nearestHighValue - nearestLowValue > 1 {
                if foundDirty < Int(threshold) {
                    find(trial: (nearestHighValue + trial) / 2, nearestLowValue: trial, nearestHighValue: nearestHighValue, bestRelationValue: relationValueAtOptimum, bestRelationPredictionValue: predictionValueAtOptimum, targetStatistic: &targetStatistic)
                } else {
                    find(trial: (trial + nearestLowValue) / 2, nearestLowValue: nearestLowValue, nearestHighValue: trial, bestRelationValue: relationValueAtOptimum, bestRelationPredictionValue: predictionValueAtOptimum, targetStatistic: &targetStatistic)
                }
            } else {
                targetStatistic.targetValue = 0
                targetStatistic.targetsAtThreshold = targetInstancesCount
                targetStatistic.dirtiesAtThreshold = foundDirty
                targetStatistic.predictionValueAtThreshold = j
            }
            targetStatistic.targetInstancesCount = targetInstancesCount
            targetStatistic.threshold = threshold
            targetStatistic.predictionValueAtOptimum = predictionValueAtOptimum
            targetStatistic.targetsAtOptimum = targetsAtOptimum
            targetStatistic.dirtiesAtOptimum = dirtiesAtOptimum
        }
        store2PredictionMetrics(targetStatistic: targetStatistic)
        return targetStatistic
    }
    func store2PredictionMetrics(targetStatistic: TargetStatistics) -> Void {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = PersistenceController.shared.container.viewContext.persistentStoreCoordinator
        privateContext.perform {
            let m = Mirror(reflecting: targetStatistic)
            let properties = Array(m.children)
            var dictOfPredictionMetrics = Dictionary<String, Double> ()
            properties.forEach { prop in
                dictOfPredictionMetrics[(prop.label)!] = Double(0)
            }
            let predictionMetricsDataModel = PredictionMetricsModel()
            //        predictionMetricsDataModel.deleteAllRecords(predicate: nil)
            let predictionMetricValueDataModel = PredictionMetricValueModel()
            //        predictionMetricValueDataModel.deleteAllRecords(predicate: nil)
            let algorithmDataModel = AlgorithmsModel()
            dictOfPredictionMetrics.forEach { entry in
                var metric = predictionMetricsDataModel.items.filter { $0.name == entry.key }.first
                if metric == nil {
                    metric = predictionMetricsDataModel.insertRecord()
                    metric?.name = entry.key
                }
                let algorithm = algorithmDataModel.items.first(where: { $0.name == self.regressorName})
                var valueEntry = predictionMetricValueDataModel.items.filter { $0.predictionmetricvalue2predictionmetric?.name == entry.key && $0.predictionmetricvalue2algorithm?.name == self.regressorName && $0.predictionmetricvalue2prediction == self.prediction }.first
                if valueEntry == nil {
                    valueEntry = predictionMetricValueDataModel.insertRecord()
                    valueEntry?.predictionmetricvalue2algorithm = algorithm
                    valueEntry?.predictionmetricvalue2predictionmetric = metric
                    valueEntry?.predictionmetricvalue2prediction = self.prediction
                }
                let prop = properties.first(where: { $0.label == entry.key })
                if prop?.value is Int {
                    valueEntry?.value = Double(prop?.value as! Int)
                }
                if prop?.value is Double {
                    valueEntry?.value = Double(prop?.value as! Double)
                }
            }
            do {
                if privateContext.hasChanges {
                    try privateContext.save()
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }
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
        let mlFilterColumn =  mlDataTable[columnName]
        var formula: String = ""
        if value.count > 1 {
            let index = value.index(value.startIndex, offsetBy: 2)
            let formulaTest = value.prefix(upTo: index)
            let equalExtension = formulaTest.contains("=") ? "=": ""
            if formulaTest.contains(">") {
                formula = ">" + equalExtension
            }
            if formulaTest.contains("<") {
                formula = "<" + equalExtension
            }
        }
        switch column.type {
        case MLDataValue.ValueType.int:
            let filterMask = constructFilterMask(mlColumn: mlFilterColumn, formula: formula, value: Int.parse(from: value)!)
            result = mlDataTable[filterMask]
        case MLDataValue.ValueType.double:            let filterMask = constructFilterMask(mlColumn: mlFilterColumn, formula: formula, value: Double.parse(from: value)!)
            result = mlDataTable[filterMask]
        case MLDataValue.ValueType.string:
            result = mlDataTable[mlDataTable[columnName] == value]
        default:
            print("error")
        }
        
        return result
    }
    func constructFilterMask(mlColumn: MLUntypedColumn, formula: String, value: Any) -> MLUntypedColumn {
        var result: MLUntypedColumn!
        switch mlColumn.type {
        case MLDataValue.ValueType.int:
            if formula == ">" { result = mlColumn > value as! Int}
            if formula == ">=" { result = mlColumn >= value as! Int}
            if formula == "<" { result = mlColumn < value as! Int}
            if formula == "<=" { result = mlColumn <= value as! Int}
            if formula.isEmpty { result = mlColumn == value as! Int}
        case MLDataValue.ValueType.double:
            if formula == ">" { result = mlColumn > value as! Double}
            if formula == ">=" { result = mlColumn >= value as! Double}
            if formula == "<" { result = mlColumn < value as! Double}
            if formula == "<=" { result = mlColumn <= value as! Double}
            if formula.isEmpty { result = mlColumn == value as! Double}
            
        default: print("error setting table filter")
        }
        return result
    }
    
    struct TableStatistics {
        var absolutRowCount = 0
        var filteredRowCount = 0
        var targetStatistics = [TargetStatistics]()
        
    }
    class TargetStatistics {
        var targetValue = 0
        var targetPopulation = 0
        var targetInstancesCount = 0
        var threshold: Double = 0.00000
        var predictionValueAtOptimum: Double = 0
        var targetsAtOptimum: Int = 0
        var dirtiesAtOptimum: Int = 0
        var predictionValueAtThreshold: Double = 0
        var targetsAtThreshold = 0
        var dirtiesAtThreshold = 0
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
