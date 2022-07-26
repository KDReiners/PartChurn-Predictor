//
//  Scenario.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 25.07.22.
//

import Foundation
import CreateML
import CoreML
struct Scenario {
    var includedColumns: [[Columns]]
    var timeSeries: [Int]
    var mlDataTable: MLDataTable
    init(includedColumns: [[Columns]], timeSeries: [Int], baseTable: MLDataTable) {
        self.includedColumns = includedColumns
        self.timeSeries = timeSeries
        self.mlDataTable = baseTable
    }
}
