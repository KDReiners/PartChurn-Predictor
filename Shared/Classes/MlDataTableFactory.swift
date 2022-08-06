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
    var timeSeries: [Int]?
    
    func filterMlDataTable() {
        var result: MLDataTable!
        mergedColumns = selectedColumns == nil ? orderedColumns: selectedColumns
        if selectedColumns != nil {
            let additions = orderedColumns.filter { $0.ispartofprimarykey == 1 || $0.istimeseries == 1 || $0.istarget == 1}
            mergedColumns.append(contentsOf: additions)
        }
        let timeSeriesColumn = self.orderedColumns.filter { $0.istimeseries == 1 }
        let mlTimeSeriesColumn = mlDataTable[(timeSeriesColumn.first?.name!)!]
        if let timeSeries = timeSeries {
            for timeSlice in timeSeries {
                let timeSeriesMask = mlTimeSeriesColumn == timeSlice
                let newMlDataTable = self.mlDataTable[timeSeriesMask]
                if unionOfMlDataTables == nil {
                    unionOfMlDataTables = [newMlDataTable] } else {
                        unionOfMlDataTables?.append(newMlDataTable)
                    }
            }
            if var unionTables = unionOfMlDataTables {
                adjustTables(unionOfMlDataTables: &unionTables)
                let joinColumn = orderedColumns.first(where: { $0.ispartofprimarykey == 1 })
                for mlDataTableForUnion in unionTables {
                    if result == nil {
                        result = mlDataTableForUnion
                    } else {
                        result = result.join(with: mlDataTableForUnion, on: (joinColumn?.name!)!, type: .inner)
                    }
                }
            }
            self.mlDataTable = result
        }
    }
    func adjustTables(unionOfMlDataTables: inout [MLDataTable]) {
        let seriesDataModel = SeriesModel()
        seriesDataModel.deleteAllRecords(predicate: nil)
        /// extract non timeSeriesColumn from self.mlDataTable
        let timeSeriesColumns = self.orderedColumns.filter { $0.istimeseries == 1 }
        /// rename timeSeriesColumns from each mlDataTable in unionOfMlDataTables
        let timeDependantColumns = self.orderedColumns.filter { $0.istimeseries == 0 && $0.ispartoftimeseries == 1 }
        let timeInDependantColumns = self.orderedColumns.filter { $0.istimeseries == 0 && $0.ispartoftimeseries == 0 && $0.ispartofprimarykey == 0 }
        for i in 0..<unionOfMlDataTables.count {
            for column in timeSeriesColumns {
                unionOfMlDataTables[i].removeColumn(named: column.name!)
            }
            if i > 0 {
                for column in timeInDependantColumns {
                    unionOfMlDataTables[i].removeColumn(named: column.name!)
                }
            }
            for column in timeDependantColumns {
                if unionOfMlDataTables[i].columnNames.contains(column.name!) {
                    unionOfMlDataTables[i].renameColumn(named: column.name!, to: column.name! + " T-(\(i))")
                    let newSeries = SeriesModel().insertRecord()
                    newSeries.timeslice = Int16(i)
                    newSeries.alias = column.name! + " T-(\(i))"
                    newSeries.series2column = column
                    column.alias = column.name! + " T-(\(i))"
                }
            }
        }
    }
}
