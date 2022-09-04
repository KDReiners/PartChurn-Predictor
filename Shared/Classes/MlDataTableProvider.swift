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
    @Published var valuesTableProvider: ValuesTableProvider?
    var filterViewProvider: FilterViewProvider!
    var prediction: Predictions?
    var regressorName: String?
    @Published var tableStatistics: TableStatistics?
    
    init() {
        self.tableStatistics = TableStatistics()
    }
    internal func updateTableProviderForFiltering() {
        tableProvider(mlDataTable: self.mlDataTable, orderedColums: mlColumns!, selectedColumns: mergedColumns) { provider in
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
                self.mlDataTableRaw = provider.mlDataTable
                self.mlDataTable = self.mlDataTableRaw
                self.mlColumns = provider.orderedColNames
                if self.filterViewProvider == nil {
                    self.filterViewProvider = FilterViewProvider(mlDataTableFactory: self)
                }
                self.loaded = true
            }
        }
    }
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
        let unionResult = UnionResult(mlDataTable: self.mlDataTable, mlColumns:self.mlColumns!)
        self.mlDataTableRaw = mlDataTableRaw == nil ? mlDataTable: self.mlDataTableRaw
        updateTableProvider()
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
    func tableProvider(mlDataTable: MLDataTable, orderedColums: [String], selectedColumns: [Columns]?, prediction: Predictions? = nil, regressorName: String? = nil , returnCompletion: @escaping (ValuesTableProvider) -> () ) {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(mlDataTable: mlDataTable, orderedColNames: orderedColums, selectedColumns: selectedColumns,  prediction: prediction, regressorName: regressorName)
                DispatchQueue.main.async {
                    self.gridItems = result.gridItems
                    self.customColumns = result.customColumns
                    self.numRows = self.customColumns.count > 0 ? self.customColumns[0].rows.count:0
                    returnCompletion(result as ValuesTableProvider)
                }
            }
        }
    }
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
    struct TableStatistics {
        var absolutRowCount = 0
        var filteredRowCount = 0
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
