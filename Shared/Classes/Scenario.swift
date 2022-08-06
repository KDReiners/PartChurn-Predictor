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
class Scenario: Hashable {
    static func == (lhs: Scenario, rhs: Scenario) -> Bool {
        Set(lhs.includedColumns) == Set(rhs.includedColumns) && Set(lhs.timeSeries) == Set(rhs.timeSeries)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(includedColumns)
    }
    var columnSections = [ColumnSection]()
    var timeSeriesSections = [TimeSeriesSection]()
    var includedColumns: [[Columns]]
    var timeSeries: [[Int]]
    var mlDataTable: MLDataTable
    init(includedColumns: [[Columns]], timeSeries: [[Int]], baseTable: MLDataTable) {
        self.includedColumns = includedColumns
        self.timeSeries = timeSeries
        self.mlDataTable = baseTable
        fillColumnSections()
        fillTimeSeriesSections()
    }
    internal func fillColumnSections() {
        var currentColumnSection: ColumnSection
        for columnArray in includedColumns {
            if (columnSections.first(where: { $0.level == columnArray.count}) != nil) {
                currentColumnSection  = columnSections.first(where: { $0.level == columnArray.count})!
               
            } else {
                currentColumnSection = ColumnSection()
                currentColumnSection.level = columnArray.count
                columnSections.append(currentColumnSection)
            }
            currentColumnSection.columns.append(columnArray)
        }
    }
    internal func fillTimeSeriesSections() {
        var currentTimeSeriesSection: TimeSeriesSection
        for columnArray in timeSeries {
            if (timeSeriesSections.first(where: { $0.level == columnArray.count}) != nil) {
                currentTimeSeriesSection  = timeSeriesSections.first(where: { $0.level == columnArray.count})!
            } else {
                currentTimeSeriesSection = TimeSeriesSection()
                currentTimeSeriesSection.level = columnArray.count
                timeSeriesSections.append(currentTimeSeriesSection)
            }
            currentTimeSeriesSection.timeSeries.append(columnArray)
        }
    }
    class ColumnSection: Hashable {
        static func == (lhs: Scenario.ColumnSection, rhs: Scenario.ColumnSection) -> Bool {
            Set(lhs.columns) == Set(rhs.columns)
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(columns)
        }
        var id = UUID()
        var level: Int!
        var columns = [[Columns]]()
    }
    class TimeSeriesSection: Hashable {
        static func == (lhs: Scenario.TimeSeriesSection, rhs: Scenario.TimeSeriesSection) -> Bool {
            Set(lhs.timeSeries) == Set(rhs.timeSeries)
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(timeSeries)
        }
        var id = UUID()
        var level: Int!
        var timeSeries = [[Int]]()
        var rows: Array<String> {
            get {
                var result = [String]()
                for series in timeSeries {
                    result.append(series.map { String($0) }.joined(separator: ", "))
                }
                return result
            }
        }
        
    }
}
