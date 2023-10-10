//
//  SMOTE.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 08.10.23.
//

import CreateML
import CoreML
import Foundation
class Smote {
    var mlDataTable: MLDataTable
    var columnsDataModel: ColumnsModel
    var majorityTable: MLDataTable
    var minorityTable: MLDataTable
    var minorityValue: Int
    var targetColumn: Columns
    var syntheticDataTable = MLDataTable()
    var newEntries = [String: MLDataValueConvertible]()
    var model: Models
    
    init(mlDataTable: MLDataTable, model: Models) {
        self.mlDataTable = mlDataTable
        self.model = model
        self.columnsDataModel = ColumnsModel(model: model)
        // Define the target column and the minority class label
        targetColumn = columnsDataModel.targetColumns.first!
        minorityValue = 0
        
        // Separate the minority and majority class samples
        let minorityMask = mlDataTable[targetColumn.name!] == minorityValue
        let majorityMask = mlDataTable[targetColumn.name!] != minorityValue
        self.minorityTable = mlDataTable[minorityMask]
        let (majorityTable, _ ) =  mlDataTable[majorityMask].randomSplit(by: 0.5)
        self.majorityTable = majorityTable
        // Set the desired number of synthetic samples to generate
        let numSyntheticSamples = 100
    }
    
    
    func findKNearestNeighbors(_ dataPoint: [String: Double], k: Int, data: MLDataTable) -> [Int] {
        var distances: [(index: Int, distance: Double)] = []

        for (index, row) in data.rows.enumerated() {
            var sumSquaredDifferences: Double = 0.0
            for (columnName, neighborValue) in extractNumericFeatureValues(row) {
                if let dataPointValue = dataPoint[columnName] {
                    let difference = dataPointValue - neighborValue
                    sumSquaredDifferences += difference * difference
                }
            }
            let distance = sqrt(sumSquaredDifferences)
            distances.append((index: index, distance: distance))
        }

        distances.sort { $0.distance < $1.distance }
        return distances.prefix(k).map { $0.index }
    }

    func euclideanDistance<T: FloatingPoint>(_ vector1: [T], _ vector2: [T]) -> T {
        precondition(vector1.count == vector2.count, "Vectors must have the same length")

        var sumSquaredDifferences: T = 0

        for i in 0..<vector1.count {
            let difference = vector1[i] - vector2[i]
            sumSquaredDifferences += difference * difference
        }

        return sqrt(sumSquaredDifferences)
    }
    func createSyntheticSamples() -> MLDataTable {
        // Generate synthetic samples using SMOTE
            var syntheticSamples: [[String: MLDataValue]] = []
            for _ in 1...1 {
                // Create a synthetic sample by interpolating between the selected sample and the neighbor
                var syntheticSample: [String: MLDataValue] = [:]
                // Randomly select a minority class sample
                let randomIndex = Int.random(in: 0..<minorityTable.rows.count)
                let minoritySample = minorityTable.rows[randomIndex]

                // Extract numeric feature values from the minority sample
                let minorityFeatureValues = extractNumericFeatureValues(minoritySample)

                // Find k-nearest neighbors for the selected minority sample
                let neighbors = findKNearestNeighbors(minorityFeatureValues, k: 3, data: majorityTable)

                // Randomly select one of the neighbors
                let neighborIndex = neighbors.randomElement()!

                // Extract numeric feature values from the neighbor
                let neighborFeatureValues = extractNumericFeatureValues(majorityTable.rows[neighborIndex])

                for (columnName, featureValue) in minoritySample {
                    if columnName != targetColumn.name { // Skip the target column
                        if let minorityValue = featureValue.doubleValue,
                            let neighborValue = neighborFeatureValues[columnName] {
                            // Calculate the Euclidean distance and use it to generate a synthetic value
                            let syntheticValue = (minorityValue + neighborValue) / 2.0 // Replace with your distance calculation logic
                            syntheticSample[columnName] = MLDataValue.double(syntheticValue)
                        }
                        if let minorityValue = featureValue.intValue,
                            let neighborValue = neighborFeatureValues[columnName] {
                            // Calculate the Euclidean distance and use it to generate a synthetic value
                            let syntheticValue = (Double(minorityValue) + neighborValue) / 2.0 // Replace with your distance calculation logic
                            syntheticSample[columnName] = MLDataValue.int(Int(syntheticValue))
                        }
                    }
                }

                // Assign the minority class label to the synthetic sample
                syntheticSample[targetColumn.name!] = MLDataValue.int(self.minorityValue)

                // Append the synthetic sample to the list
                syntheticSamples.append(syntheticSample)
            }

            // Convert the list of synthetic samples to an MLDataTable
            var sampler: [String: [MLDataValueConvertible]] = [:]
            for sample in syntheticSamples {
                for (key, _) in sample {
                    sampler[key] = []
                    newEntries[key] = [] as? MLDataValueConvertible
                }
            }
            // Populate the sampler dictionary with values from syntheticSamples
            for sample in syntheticSamples {
                for (key, value) in sample {
                    switch value.type {
                    case .int:
                        sampler[key]?.append(value.intValue!)
                    case .double:
                        sampler[key]?.append(value.doubleValue!)
                    default:
                        sampler[key]?.append(value.stringValue!)
                    }
                }
            }

            // Convert the sampler dictionary to newEntries
            for (key, values) in sampler {
                if values.allSatisfy( {$0.dataValue.intValue != nil }) {
                    newEntries[key] = values as? [Int]
                } else if values.allSatisfy( {$0.dataValue.doubleValue != nil }) {
                    newEntries[key] = values as? [Double]
                } else if values.allSatisfy( {$0.dataValue.stringValue != nil }) {
                    newEntries[key] = values as? [String]
                }
            }

            syntheticDataTable = try! MLDataTable(dictionary: newEntries)

            // Combine original data with synthetic data
            return syntheticDataTable
        }

    

    func extractNumericFeatureValues(_ row: MLDataTable.Row) -> [String: Double] {
        var numericValues: [String: Double] = [:]
        for (columnName, featureValue) in row {
            if columnName != targetColumn.name! { // Skip the target column
                if let numericValue = featureValue.doubleValue {
                    numericValues[columnName] = numericValue
                }
                if let numericValue = featureValue.intValue {
                    numericValues[columnName] = Double(numericValue)
                }
            }
        }
        return numericValues
    }
    
    static func inferColumnType(in table: MLDataTable, for columnName: String) -> MLFeatureType {
        let column = table[columnName]
        if column.ints != nil {
            return .int64
        }
        if column.doubles != nil {
            return .double
        }
        if column.strings != nil {
            return .string
        }
        return .string // Default to string if data type couldn't be determined
    }
}
