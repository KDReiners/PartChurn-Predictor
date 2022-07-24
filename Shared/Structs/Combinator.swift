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
    var columnCombinations: [Columns]?
    var orderedColumns: [Columns]
    var includedColumns: [Columns]
    var timeSeriesColumns: [Columns]
    var series: [Int]?
    var mlDataTable: MLDataTable
    var seriesStart: Int!
    var seriesEnd: Int!
    var seriesLength: Int!
    init(model: Models, orderedColumns: [Columns], mlDataTable: MLDataTable) {
        self.model = model
        self.orderedColumns = orderedColumns
        self.includedColumns = orderedColumns.filter( { $0.isincluded == 1})
        self.timeSeriesColumns = orderedColumns.filter({$0.ispartoftimeseries == 1 })
        self.mlDataTable = mlDataTable
        seriesStart = self.mlDataTable[(timeSeriesColumns.first?.name)!].ints?.min()
        series = findNextSlice(start: seriesStart, columnName: (timeSeriesColumns.first?.name)!)
        seriesEnd = self.mlDataTable[(timeSeriesColumns.first?.name)!].ints?.max()
        for i in 0...includedColumns.count {
            let test = combinations(source: includedColumns, takenBy:  i)
            print("level: \(i)")
            for row in test {
                print(row.map({$0.name}))
                print("new line")
            }
        }
    }
    func combinations<T>(source: [T], takenBy : Int) -> [[T]] {
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
        let subCombos = combinations(source: rest, takenBy: takenBy - 1)
        result += subCombos.map { [source[0]] + $0 }
        result += combinations(source: rest, takenBy: takenBy)
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
}
