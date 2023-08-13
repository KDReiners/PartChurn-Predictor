//
//  Combinator.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 24.07.22.
//

import Foundation
import CreateML
struct Combinator {
    var model: Models
    var columnCombinations: [[Columns]]!
    var timeSeriesCombinations: [[Int]]!
    var orderedColumns: [Columns]
    var includedColumns: [Columns]
    var timeSeriesColumns: [Columns]
    var series: [Int]?
    var mlDataTable: MLDataTable
    var seriesStart: Int!
    var seriesEnd: Int!
    var seriesLength: Int!
    var scenario: ScenarioProvider!
    init(model: Models, orderedColumns: [Columns], mlDataTable: MLDataTable) {
        self.model = model
        self.orderedColumns = orderedColumns
        self.includedColumns = orderedColumns.filter( { $0.isincluded == 1 && $0.istimeseries == 0})
        self.timeSeriesColumns = orderedColumns.filter({$0.istimeseries == 1 })
        self.mlDataTable = mlDataTable
        
        if timeSeriesColumns.count > 0 {
            seriesStart = self.mlDataTable[(timeSeriesColumns.first?.name)!].ints?.min()
            series = findNextSlice(start: seriesStart, columnName: (timeSeriesColumns.first?.name)!)
            seriesEnd = self.mlDataTable[(timeSeriesColumns.first?.name)!].ints?.max()
            timeSeriesCombinations = timeSeriesColumnCombinations()
        }

        columnCombinations = [[Columns]]()
        if includedColumns.count > 0 {
            for i in 1...includedColumns.count {
                let entry = includedColumnsCombinations(source: includedColumns, takenBy:  i)
                columnCombinations += entry
            }
            scenario = ScenarioProvider(includedColumns: columnCombinations, timeSeries: timeSeriesCombinations, baseTable: mlDataTable)
        }
    }
    func timeSeriesColumnCombinations(depth: Int? = 2) -> [[Int]] {
        var result: [[Int]] = []
        for i in 0...series!.count - 1 {
            var combination: [Int] = []
            let rangeTo = i + depth!
            if rangeTo <= series!.count {
                for j in stride(from: i, to: rangeTo, by: 1) {
                    combination.append(series![j])
                }
                result.append(combination)
            }
        }
        if series!.count >= depth! + 1 {
            let subCombos = timeSeriesColumnCombinations(depth: depth! + 1)
            result += subCombos.map { $0 }
        }
        return result
        
    }
    func includedColumnsCombinations<T>(source: [T], takenBy : Int) -> [[T]] {
        if(source.count == takenBy) {
            return [source]
        }
        
        if(source.isEmpty) {
            return []
        }
        
        if(takenBy == 0) {
            return []
        }
        
        if(takenBy == 1) {
            return source.map { [$0] }
        }
        
        var result : [[T]] = []
        
        let rest = Array(source.suffix(from: 1))
        let subCombos = includedColumnsCombinations(source: rest, takenBy: takenBy - 1)
        result += subCombos.map { [source[0]] + $0 }
        result += includedColumnsCombinations(source: rest, takenBy: takenBy)
        return result
    }
    private func findNextSlice(start: Int, columnName: String) -> [Int]? {
        var result = [Int]()
        var currentStart: Int?
        var postStartTable: MLDataTable
        result.append(start)
        currentStart = start
        while currentStart != nil {
            guard let timeSliceColumn = mlDataTable[columnName, Int.self] else {
                fatalError("Missing or invalid column in table.")
            }
            let timeSliceMask = timeSliceColumn > currentStart!
            postStartTable = mlDataTable[timeSliceMask == true].sort(columnNamed: columnName, byIncreasingOrder: true)
            if postStartTable.rows.count > 0 {
                let newSlice =  (postStartTable.rows.first![columnName]?.intValue)
                result.append(newSlice!)
                currentStart = newSlice
            } else {
                currentStart = nil
            }
        }
        return result
    }
    func getTimeSeriesEntries() -> Set<TimeSeriesEntry> {
        let timeSeriesDataModel = TimeSeriesModel()
        let timeSliceDataModel = TimeSliceModel()
        var result = Set<TimeSeriesEntry>()
        for series in self.timeSeriesCombinations {
            let predicate = NSPredicate(format: "from == %i and  to ==%i", Int32(series.min()!), Int32(series.max()!))
            var seriesEntry = timeSeriesDataModel.getExistingRecord(predicate: predicate)
            if seriesEntry == nil {
                seriesEntry = timeSeriesDataModel.insertRecord()
                seriesEntry!.from = Int32(series.min()!)
                seriesEntry!.to = Int32(series.max()!)
                for timeSlice in series {
                    let predicate = NSPredicate(format: "value == %i", Int32(timeSlice))
                    let found = timeSliceDataModel.getExistingRecord(predicate: predicate)
                    let timeSliceEntry = found == nil ? timeSliceDataModel.insertRecord(): found
                    timeSliceEntry!.value = Int32(timeSlice)
                    seriesEntry!.addToTimeseries2timeslices(timeSliceEntry!)
                }
            }
            var timeSeriesEntry = TimeSeriesEntry()
            timeSeriesEntry.timeSeries = seriesEntry
            result.insert(timeSeriesEntry)
        }
        BaseServices.save()
        return result
    }
}
struct TimeSeriesEntry: Hashable{
    var id = UUID()
    var timeSeries: Timeseries!
    
}
