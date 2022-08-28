//
//  ValuesTableProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 04.07.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML

class ValuesTableProvider: ObservableObject {
    var coreDataML: CoreDataML!
    var mlDataTable: MLDataTable!
    var models = [model]()
    var urlToPredictionModel: URL?
    var predictionModel: MLModel?
    var customColumns = [CustomColumn]()
    var gridItems = [GridItem]()
    var numCols: Int = 0
    var numRows: Int = 0
    init( mlDataTable: MLDataTable, orderedColumns: [String], prediction: Predictions? = nil , regressorName: String? = nil) {
        self.mlDataTable = mlDataTable
        if regressorName != nil && prediction != nil {
            urlToPredictionModel = BaseServices.createPredictionPath(prediction: prediction!, regressorName: regressorName!)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: urlToPredictionModel!.path) {
               predictionModel = getModel(url: urlToPredictionModel!)
                incorporatedPredition(model: predictionModel!)
            }
        }
        prepareView(orderedColumns: orderedColumns)
    }
    
    init(file: Files?) {
        self.coreDataML = CoreDataML(model: file?.files2model, files: file)
        self.mlDataTable = coreDataML.mlDataTable
        prepareView()
        numCols = customColumns.count
        numRows = numCols > 0 ?customColumns[0].rows.count : 0
    }
    private func incorporatedPredition(model: MLModel) {
    
    }
    
    fileprivate func insertIntoGridItems(_ columnName: String?, _ rows: inout [String]) {
        var newCustomColumn = CustomColumn(title: columnName!, alignment: .trailing)
        var newGridItem: GridItem?
        let valueType = mlDataTable[columnName!].type
        let mlDataValueFormatter = NumberFormatter()
        switch valueType {
        case MLDataValue.ValueType.int:
            rows = Array.init(mlDataTable[columnName!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
            newCustomColumn.alignment = .trailing
            newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
        case MLDataValue.ValueType.double:
            mlDataValueFormatter.minimumFractionDigits = 2
            mlDataValueFormatter.maximumFractionDigits = 2
            mlDataValueFormatter.hasThousandSeparators = true
            rows = Array.init(mlDataTable[columnName!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
            newCustomColumn.alignment = .trailing
            newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
        case MLDataValue.ValueType.string:
            rows = Array.init(mlDataTable[columnName!].map( { $0.stringValue! }))
            newCustomColumn.alignment = .leading
            newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
        default:
            print("error determing valueType")
        }
        newCustomColumn.rows.append(contentsOf: rows)
        newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
        self.customColumns.append(newCustomColumn)
        self.gridItems.append(newGridItem!)
    }
    
    func prepareView(orderedColumns: [String]) -> Void {
        var rows = [String]()
        self.gridItems.removeAll()
        for column in  orderedColumns {
            insertIntoGridItems(column, &rows)
        }
    }
    func prepareView() -> Void {
        var rows = [String]()
        for column in self.coreDataML.orderedColumns {
            if column.isshown! == 1 {
                var newCustomColumn = CustomColumn(title: column.name ?? "Unbekannt", alignment: .trailing)
                var newGridItem: GridItem?
                let valueType = mlDataTable[column.name!].type
                let mlDataValueFormatter = NumberFormatter()
                mlDataValueFormatter.numberStyle = column.decimalpoint == true ? .decimal : .none
                switch valueType {
                case MLDataValue.ValueType.int:
                    mlDataValueFormatter.minimumFractionDigits = 0
                    rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
                    newCustomColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                    column.datatype = BaseServices.columnDataTypes.Int.rawValue
                case MLDataValue.ValueType.double:
                    mlDataValueFormatter.minimumFractionDigits = 2
                    mlDataValueFormatter.maximumFractionDigits = 2
                    rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
                    newCustomColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
                    column.datatype = BaseServices.columnDataTypes.Double.rawValue
                case MLDataValue.ValueType.string:
                    rows = Array.init(mlDataTable[column.name!].map( { $0.stringValue! }))
                    newCustomColumn.alignment = .leading
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
                    column.datatype = BaseServices.columnDataTypes.String.rawValue
                default:
                    print("error determining value type")
                }
                newCustomColumn.rows.append(contentsOf: rows)
                newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                self.customColumns.append(newCustomColumn)
                self.gridItems.append(newGridItem!)
            }
        }
    }
    private func getModel(url: URL) ->MLModel {
        var result: MLModel?
        if let result = models.filter({ $0.url == url}).first?.model {
            return result
        } else {
            let compiledUrl:URL = {
                do {
                    return try MLModel.compileModel(at: url)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            result = {
                do {
                    return try MLModel(contentsOf: compiledUrl)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            
        }
        let newModel = model(model: result!, url: url)
        models.append(newModel)
        return result!
    }
    private func predict(regressorName: String, result: [String : MLDataValueConvertible]) -> MLFeatureProvider {
        let provider: MLDictionaryFeatureProvider = {
            do {
                return try MLDictionaryFeatureProvider(dictionary: result)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        let prediction: MLFeatureProvider = {
            do {
                return try predictionModel!.prediction(from: provider)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        return prediction
    }

    public func predictFromRow(regressorName: String, mlRow: MLDataTable.Row) -> MLFeatureProvider {
        var result = [String: MLDataValueConvertible]()
        for i in 0..<mlRow.keys.count {
            if mlRow.keys[i] != "Kuendigt" {
                result[mlRow.keys[i]] = mlRow.values[i].intValue
                if  result[mlRow.keys[i]] == nil {
                    result[mlRow.keys[i]] = mlRow.values[i].doubleValue
                }
                if  result[mlRow.keys[i]] == nil {
                    result[mlRow.keys[i]] = mlRow.values[i].stringValue
                }
            }
        }
        return predict(regressorName: regressorName, result: result)
    }
    struct model: Identifiable {
        let id = UUID()
        var model: MLModel
        var path: String?
        var url: URL
    }
}
