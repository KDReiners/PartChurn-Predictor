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
    var loaded = false
    @Published var gridItems: [GridItem]!
    @Published var valuesTableProvider: ValuesTableProvider?
    @Published var tableStatistics: TableStatistics?
    @Published var selectedRowIndex: Int?
    @Published var mlRowDictionary = [String: MLDataValueConvertible]()
    @Published var updateRequest = false
    
    weak var delegate: AsyncOperationDelegate?
    var numRows: Int = 0
    var columnsDataModel: ColumnsModel!
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
    var lookAhead: Int!
    var observations: [Observations] = []
    
    init(model: Models? = nil) {
        self.tableStatistics = TableStatistics()
        guard let model = model else {
            return
        }
        self.model = model
        self.columnsDataModel = ColumnsModel(model: self.model)
    }
    internal func sizeOfHeaders() -> Int {
        var result = 0
        for column in mlColumns! {
            result += column.count
        }
        return result
    }
    internal var distinctTimeStamps: [Int]? {
        get {
            guard let timeStampColumn = columnsDataModel.timeStampColumn else {
                return nil
            }
            return Array(self.mlDataTable[(timeStampColumn.name)!].ints!).reduce(into: Set<Int>()) { $0.insert($1) }.sorted(by: { $0 < $1})
        }
    }
    internal var minTimeSlice: Int? {
        get {
            guard let result = distinctTimeStamps else {
                return nil
            }
            return result.min()
        }
    }
    internal var maxTimeSlice: Int? {
        get {
            guard let result = distinctTimeStamps else {
                return nil
            }
            return result.max()
        }
    }
    // MARK: - Async Calls for CoreMl
    internal func updateTableProviderForFiltering() {
        tableProvider(mlDataTable: self.mlDataTable, orderedColums: self.customColumns.map { $0.title}, selectedColumns: mergedColumns, filter: true, lookAhead: self.lookAhead) { provider in
            DispatchQueue.main.async {
                provider.predictionModel = self.valuesTableProvider?.predictionModel
                self.valuesTableProvider = provider
                self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableProvider: self)
                }
                self.delegate?.asyncOperationDidFinish(withResult: provider)
                self.loaded = true
            }
        }
    }
    internal func updateTableProviderForStatistics(completion: @escaping () ->()) {
        tableProvider(mlDataTable: mlDataTableRaw, orderedColums: mlColumns!, selectedColumns: mergedColumns, prediction: prediction, regressorName: regressorName, lookAhead: self.lookAhead) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                self.tableStatistics?.absolutRowCount = provider.mlDataTable.rows.count
                self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
                self.mlDataTableRaw = provider.mlDataTable
                self.mlDataTable = self.mlDataTableRaw
                self.mlColumns = provider.orderedColNames
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableProvider: self)
                }
                if provider.targetValues.count > 0 {
                    self.updateStatisticsProvider(targetValues: provider.targetValues, predictedColumnName: provider.predictedColumnName)
                }
                completion()
            }
        }
    }
    internal func syncUpdateTableProvider(callingFunction: String, className: String, lookAhead: Int) {
        print("updateTableProvider called from \(callingFunction) in \(className)")
        let provider = syncTableProvider(mlDataTable: mlDataTableRaw, orderedColumns: mlColumns!, selectedColumns: mergedColumns, prediction: prediction, regressorName: regressorName, lookAhead: self.lookAhead)
        self.valuesTableProvider = provider
        self.tableStatistics?.absolutRowCount = provider.mlDataTable.rows.count
        self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
        self.mlDataTableRaw = provider.mlDataTable
        self.mlDataTable = self.mlDataTableRaw
        if provider.targetValues.count > 0 {
            self.syncUpdateStatisticsProvider(targetValues: provider.targetValues, predictedColumnName: provider.predictedColumnName)
        }
        self.mlColumns = provider.orderedColNames
        if self.filterViewProvider == nil {
            self.filterViewProvider = FilterViewProvider(mlDataTableProvider: self)
        }
        self.loaded = true
        self.delegate?.asyncOperationDidFinish(withResult: self)
            
    
    }
    func syncUpdateStatisticsProvider(targetValues: [String : Int], predictedColumnName: String) {
        if self.regressorName != nil && self.mlDataTable.columnNames.contains(predictedColumnName) {
            guard let provider = syncStatisticsProvider(targetValues: targetValues, predictedColumnName: predictedColumnName) else {
                fatalError("StatisticProvider did not return results")
            }
            self.tableStatistics?.targetStatistics.append(provider)
            self.delegate?.asyncOperationDidFinish(withResult: provider)
        }
    }
    

    internal func updateTableProvider(callingFunction: String, className: String, lookAhead: Int) {
        print("updateTableProvider called from \(callingFunction) in \(className)")
        tableProvider(mlDataTable: mlDataTableRaw, orderedColums: mlColumns!, selectedColumns: mergedColumns, prediction: prediction, regressorName: regressorName, lookAhead: self.lookAhead) { provider in
            DispatchQueue.main.async {
                self.valuesTableProvider = provider
                self.tableStatistics?.absolutRowCount = provider.mlDataTable.rows.count
                self.tableStatistics?.filteredRowCount = provider.mlDataTable.rows.count
                self.mlDataTableRaw = provider.mlDataTable
                self.mlDataTable = self.mlDataTableRaw
                if provider.targetValues.count > 0 {
                    self.updateStatisticsProvider(targetValues: provider.targetValues, predictedColumnName: provider.predictedColumnName)
                }
                self.mlColumns = provider.orderedColNames
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableProvider: self)
                }
                self.loaded = true
                self.delegate?.asyncOperationDidFinish(withResult: self)
            }
        }
    }
    // MARK: - related TableProvider coreMl
    func tableProvider(mlDataTable: MLDataTable, orderedColums: [String], selectedColumns: [Columns]?, prediction: Predictions? = nil, regressorName: String? = nil, filter: Bool? = false, lookAhead: Int? , returnCompletion: @escaping (ValuesTableProvider) -> () ) {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(mlDataTable: mlDataTable, orderedColNames: orderedColums, selectedColumns: selectedColumns,  prediction: prediction, regressorName: regressorName, filter: filter, lookAhead: lookAhead)
                DispatchQueue.main.async {
                    self.gridItems = result.gridItems
                    self.customColumns = result.customColumns
                    self.numRows = self.customColumns.count > 0 ? self.customColumns[0].rows.count:0
                    returnCompletion(result as ValuesTableProvider)
                }
            }
        }
    }
    func syncTableProvider(mlDataTable: MLDataTable, orderedColumns: [String], selectedColumns: [Columns]?, prediction: Predictions? = nil, regressorName: String? = nil, filter: Bool? = false, lookAhead: Int?) -> ValuesTableProvider {
        let result = ValuesTableProvider(mlDataTable: mlDataTable, orderedColNames: orderedColumns, selectedColumns: selectedColumns, prediction: prediction, regressorName: regressorName, filter: filter, lookAhead: lookAhead)
        
        self.gridItems = result.gridItems
        self.customColumns = result.customColumns
        self.numRows = self.customColumns.count > 0 ? self.customColumns[0].rows.count : 0
        
        return result
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
                    self.filterViewProvider = FilterViewProvider(mlDataTableProvider: self)
                }
                self.loaded = true
                self.delegate?.asyncOperationDidFinish(withResult: self)
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
        if self.regressorName != nil && self.mlDataTable.columnNames.contains(predictedColumnName) {
            statisticsProvider(targetValues: targetValues, predictedColumnName: predictedColumnName) { provider in
                DispatchQueue.main.async { [self] in
                    self.tableStatistics?.targetStatistics.append(provider)
                    self.delegate?.asyncOperationDidFinish(withResult: provider)
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
    func syncStatisticsProvider(targetValues: [String : Int], predictedColumnName: String) -> TargetStatistics?  {
        self.tableStatistics?.targetStatistics = [TargetStatistics]()
        return self.resolveTargetValues(targetValues: targetValues, predictedColumnName: predictedColumnName)
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
        enhanceTargetStatistics()
        func enhanceTargetStatistics() {
            let truePositivesMask = mlPredictionColumn <= targetStatistic.predictionValueAtThreshold && mlTargetColumn == targetStatistic.targetValue
            let falsePositivesMask = mlPredictionColumn <= targetStatistic.predictionValueAtThreshold && mlTargetColumn != targetStatistic.targetValue
            let trueNegativesMask = mlPredictionColumn > targetStatistic.predictionValueAtThreshold && mlTargetColumn != targetStatistic.targetValue
            let falseNegativesMask = mlPredictionColumn > targetStatistic.predictionValueAtThreshold && mlTargetColumn == targetStatistic.targetValue
            targetStatistic.truePositives = mlDataTable[truePositivesMask].rows.count
            targetStatistic.falsePositives = mlDataTable[falsePositivesMask].rows.count
            targetStatistic.trueNegatives = mlDataTable[trueNegativesMask].rows.count
            targetStatistic.falseNegatives = mlDataTable[falseNegativesMask].rows.count
            targetStatistic.lookAhead =  self.lookAhead
            targetStatistic.timeSliceFrom = distinctTimeStamps?.first ?? 0
            targetStatistic.timeSliceTo = distinctTimeStamps?.last ?? 0
            
        }
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
            targetStatistic.threshold = threshold
            targetStatistic.predictionValueAtOptimum = predictionValueAtOptimum
            targetStatistic.targetsAtOptimum = targetsAtOptimum
            targetStatistic.dirtiesAtOptimum = dirtiesAtOptimum
        }
        store2PredictionMetrics(targetStatistic: targetStatistic)
        self.tableStatistics?.targetStatistics.append(targetStatistic)
        return targetStatistic
    }
    func store2PredictionMetrics(targetStatistic: TargetStatistics) -> Void {
        let lookAheadItem = PredictionsModel(model: self.model!).returnLookAhead(prediction: self.prediction!, lookAhead: self.lookAhead)
        let m = Mirror(reflecting: targetStatistic)
        let properties = Array(m.children)
        var dictOfPredictionMetrics = Dictionary<String, Double> ()
        properties.forEach { prop in
            dictOfPredictionMetrics[(prop.label)!] = Double(0)
        }
        let observationsDataModel = ObservationsModel()
        let predictionMetricsDataModel = PredictionMetricsModel()
//                predictionMetricsDataModel.deleteAllRecords(predicate: nil)
        let predictionMetricValueDataModel = PredictionMetricValueModel()
//                predictionMetricValueDataModel.deleteAllRecords(predicate: nil)
        let timeSlicesDataModel = TimeSlicesModel()
        let algorithmDataModel = AlgorithmsModel()
        let algorithm = algorithmDataModel.items.first(where: { $0.name == self.regressorName})
        algorithm?.addToAlgorithm2predictions(self.prediction!)
        for entry in dictOfPredictionMetrics {
            var metric = predictionMetricsDataModel.items.filter { $0.name == entry.key }.first
            if metric == nil {
                metric = predictionMetricsDataModel.insertRecord()
                metric?.name = entry.key
            }
            if let timeSliceFrom = timeSlicesDataModel.getTimeSlice(timeSliceInt: (distinctTimeStamps?.first)!), let timeSliceTo = timeSlicesDataModel.getTimeSlice(timeSliceInt: (distinctTimeStamps?.last)!) {
                let defaultObservationEntry = observationsDataModel.items.filter { $0.observation2prediction == nil && $0.observation2timesliceto == nil && $0.observation2timeslicefrom == nil  && $0.observation2model == self.model}.first
                var observationEntry = observationsDataModel.items.filter { $0.observation2prediction == prediction && $0.observation2timesliceto == timeSliceTo && $0.observation2timeslicefrom == timeSliceFrom && $0.observation2model == self.model && $0.observation2lookahead == lookAheadItem}.first
                observationEntry = defaultObservationEntry != nil ? defaultObservationEntry: observationEntry
                if observationEntry == nil {
                    observationEntry = observationsDataModel.insertRecord()
                }
                observationEntry?.observation2model = model
                observationEntry?.observation2timesliceto = timeSliceTo
                observationEntry?.observation2timeslicefrom = timeSliceFrom
                observationEntry?.observation2prediction = self.prediction
                observationEntry?.observation2lookahead = lookAheadItem
                observationEntry?.observation2algorithm = algorithm
                self.observations.append(observationEntry!)
                var valueEntry = predictionMetricValueDataModel.items.filter { $0.predictionmetricvalue2predictionmetric?.name == entry.key && $0.predictionmetricvalue2algorithm?.name == self.regressorName && $0.predictionmetricvalue2prediction == self.prediction &&
                    $0.predictionmetricvalue2lookahead == lookAheadItem && $0.predictionmetricvalue2observation == observationEntry}.first
                if valueEntry == nil {
                    valueEntry = predictionMetricValueDataModel.insertRecord()
                    valueEntry?.predictionmetricvalue2algorithm = algorithm
                    valueEntry?.predictionmetricvalue2predictionmetric = metric
                    valueEntry?.predictionmetricvalue2prediction = self.prediction
                    valueEntry?.predictionmetricvalue2lookahead = lookAheadItem
                    valueEntry?.predictionmetricvalue2observation = observationEntry
                    
                }
                guard let prop = properties.first(where: { $0.label == entry.key }) else {
                    fatalError("cannot assign property to key")
                }
                if prop.value is Int {
                    print("Set \(entry.key) to: \(prop.value)")
                    valueEntry?.value = Double(prop.value as! Int)
                }
                if prop.value is Double {
                    print("Set \(entry.key) to: \(prop.value)")
                    valueEntry?.value = Double(prop.value as! Double)
                }
                BaseServices.save()
            }
        }
    }
    func getIndexOfMergedColumn( colName: String) -> Int {
        let index = -1
        var suffix = 1
        let allowedCharset = CharacterSet
            .decimalDigits
            .union(CharacterSet(charactersIn: "+"))
        let testString = colName.suffix(suffix)
        var test = String(testString.unicodeScalars.filter(allowedCharset.contains))
        while test.count > 0 {
            suffix += 1
            test = String(testString.unicodeScalars.filter(allowedCharset.contains))
        }
        return index
    }
    func zipArrays<T>(_ arrays: [[T]]) -> AnySequence<[T]> {
        let maxLength = arrays.map { $0.count }.max() ?? 0
        return AnySequence((0..<maxLength).map { index in
            return arrays.compactMap { $0.indices.contains(index) ? $0[index] : nil }
        })
    }
    func buildMlDataTable(lookAhead: Int = 0) throws -> UnionResult {
        var result: MLDataTable?
        var loadedTable: MLDataTable?
        var predictionURL: URL!
        self.filterViewProvider = nil
        self.lookAhead = lookAhead
        mergedColumns = selectedColumns == nil ? orderedColumns: selectedColumns
        if selectedColumns != nil {
            let additions = orderedColumns.filter { $0.ispartofprimarykey == 1 || $0.istimeseries == 1 || $0.istarget == 1}
            for col in additions {
                _ = getIndexOfMergedColumn(colName: col.name!)
            }
            mergedColumns.append(contentsOf: additions)
        }
        self.mlColumns = mergedColumns.map { $0.name!}
        
        let timeSeriesColumn = self.orderedColumns.filter { $0.istimeseries == 1 }
        if timeSeriesColumn.count > 0 {
            let  mlTimeSeriesColumn = mlDataTable[(timeSeriesColumn.first?.name)!]
            if let prediction = prediction {
                let lookAhead = PredictionsModel(model: self.model!).returnLookAhead(prediction: prediction, lookAhead: lookAhead)
                predictionURL = BaseServices.sandBoxDataPath.appendingPathComponent((prediction.prediction2model?.name)!).appendingPathComponent(prediction.objectID.uriRepresentation().lastPathComponent).appendingPathComponent(lookAhead.objectID.uriRepresentation().lastPathComponent);
                loadedTable = BaseServices.loadMLDataTableFromJson(filePath: predictionURL);
            }
            if let timeSeries = timeSeries {
                
                if loadedTable == nil {
                    for timeSlices in timeSeries {
                        let newCluster = MLTableCluster(columns: mergedColumns, model: self.model!)
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
                            if newCluster.columnsDataModel.model != nil {
                                result = newCluster.construct()
                                self.mlColumns = newCluster.orderedColumns
                            } else {
                                print("newClusters columnsdataMode not correctly instantiated")
                            }
                        } else {
                            result?.append(contentsOf: newCluster.construct())
                        }
                    }
                    self.mlDataTable = result?.dropMissing()
                    //                    var columnsArray: [[PackedValue]] = []
                    
                    //                    for originalName in self.orderedColumns.map({ $0.name }) {
                    //                        let filteredColumnsUnsorted = self.mlDataTable.columnNames.filter { $0.hasPrefix(originalName!) }
                    //                        let filteredColumns = filteredColumnsUnsorted.sorted { (str1, str2) -> Bool in
                    //                            let suffix1 = str1.components(separatedBy: "-").last ?? ""
                    //                            let suffix2 = str2.components(separatedBy: "-").last ?? ""
                    //                            if suffix1 == suffix2 {
                    //                                    return str1 > str2 // If the suffix is the same, sort lexicographically
                    //                                }
                    //
                    //                                if suffix1 == "" {
                    //                                    return true // Empty suffix comes first
                    //                                } else if suffix2 == "" {
                    //                                    return false // Empty suffix comes first
                    //                                }
                    //
                    //                                return suffix1 > suffix2
                    //                        }
                    //                        if filteredColumns.count > 1 {
                    //                            var packedColumnName: String = ""
                    //                            for i in 0..<filteredColumns.count {
                    //                                if filteredColumns.count > 1 {
                    //                                    packedColumnName = filteredColumns[i]
                    //                                    let packColumn = mlDataTable[packedColumnName]
                    //                                    let packValues = (0..<packColumn.count).compactMap { index -> PackedValue? in
                    //                                        return PackedValue(from: packColumn[index])
                    //                                    }
                    //                                    columnsArray.append(packValues)
                    //                                }
                    //                            }
                    //                            if filteredColumns.count > 1 {
                    ////                                mlDataTable.removeColumn(named: packedColumnName)
                    //                                let result = zipArrays(columnsArray)
                    //                                let newColumn = MLDataColumn(result)
                    //                                self.mlDataTable.addColumn(newColumn, named: "\(originalName!).Packed")
                    //                                columnsArray.removeAll()
                    //                            }
                    //
                    //
                    //                        }
                    //                    }
                    if prediction != nil {
                        BaseServices.saveMLDataTableToJson(mlDataTable: self.mlDataTable, filePath: predictionURL)
                    }
                    
                } else {
                    self.mlDataTable = loadedTable;
                    self.mlColumns = self.mlDataTable.columnNames.map { $0 };
                }
            }
        }
        if let mlColumns = self.mlColumns, let selectedColumns = self.selectedColumns, let prediction = self.prediction, let regressorName = self.regressorName {
            let predictor = PredictionsProvider(mlDataTable: self.mlDataTable, orderedColNames: mlColumns, selectedColumns: selectedColumns, prediction: prediction, regressorName: regressorName, lookAhead: lookAhead)
            self.mlDataTable = predictor.mlDataTable
            self.mlColumns = predictor.orderedColNames
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
        case MLDataValue.ValueType.double:
            let filterMask = constructFilterMask(mlColumn: mlFilterColumn, formula: formula, value: Double.parse(from: value)!)
            result = mlDataTable[filterMask]
        case MLDataValue.ValueType.string:
            result = mlDataTable[mlDataTable[columnName] == value]
        default:
            print("unknown columnType.")
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
    func mlDataTable2Dictionary() -> [[String: Any]] {
        var result = [[String: Any]]()
        for row in self.mlDataTable.rows {
            var rowDictionary: [String: Any] = [:]
            for (columnIndex, columnName) in self.mlDataTable.columnNames.enumerated() {
                let value = row[columnIndex]
                rowDictionary[columnName] = value
            }
            result.append(rowDictionary)
        }
        return result
    }
    struct TableStatistics {
        var absolutRowCount = 0
        var filteredRowCount = 0
        var targetStatistics = [TargetStatistics]()
        
    }
    class TargetStatistics: NSObject{
        @objc var targetValue = 0
        @objc var targetPopulation = 0
        @objc var threshold: Double = 0.00000
        @objc var predictionValueAtOptimum: Double = 0
        @objc var targetsAtOptimum: Int = 0
        @objc var dirtiesAtOptimum: Int = 0
        @objc var predictionValueAtThreshold: Double = 0
        @objc var targetsAtThreshold = 0
        @objc var dirtiesAtThreshold = 0
        @objc var truePositives = 0
        @objc var falsePositives = 0
        @objc var trueNegatives = 0
        @objc var falseNegatives = 0
        @objc var lookAhead = 0
        @objc var timeSliceFrom: Int = 0
        @objc var timeSliceTo: Int = 0
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
