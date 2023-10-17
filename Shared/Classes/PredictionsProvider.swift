//
//  PredictionsProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 24.06.23.
//

import Foundation
import CoreML
import CreateML
class PredictionsProvider {
    var selectedColumns: [Columns]
    var isClassifier: Bool = false
    var mlDataTable: MLDataTable
    var predictionModel: MLModel?
    var targetColumn: Columns!
    var columnsDataModel: ColumnsModel!
    var predictedColumnName: String!
    var orderedColNames: [String]!
    var targetValues = [String: Int]()
    var regressorName: String!
    var prediction: Predictions!
    var loadedModels = [loadedModel]()
    init(mlDataTable: MLDataTable, orderedColNames: [String], selectedColumns: [Columns], prediction: Predictions , regressorName: String, lookAhead: Int?) {
        self.selectedColumns = selectedColumns
        self.orderedColNames = orderedColNames
        self.mlDataTable = mlDataTable
        self.prediction = prediction
        self.regressorName = regressorName
        self.prediction = prediction
        self.columnsDataModel = ColumnsModel(model: prediction.prediction2model)
        self.targetColumn = columnsDataModel.targetColumns.first
        if targetColumn != nil {
            self.predictedColumnName = "Predicted: " + (targetColumn?.name)!
            removePredictionColumns(predictionColumName: predictedColumnName)
        }
        let isClassifier = (regressorName.lowercased().contains("regressor")) ? false: true
        
        if let lookAhead = lookAhead {
            let urlToPredictionModel = BaseServices.sandBoxDataPath.appendingPathComponent((prediction.prediction2model?.name)!).appendingPathComponent(prediction.objectID.uriRepresentation().lastPathComponent).appendingPathComponent(PredictionsModel().returnLookAhead(prediction: prediction, lookAhead: lookAhead).objectID.uriRepresentation().lastPathComponent).appendingPathComponent(regressorName.replacingOccurrences(of: "ML", with: "") + ".mlmodel")
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: urlToPredictionModel.path) {
                let group = DispatchGroup()
                group.enter()
                getModel(url: urlToPredictionModel) { [self] completion in
                    predictionModel = completion
                    group.leave()

                }
                group.wait()
                incorporatedPrediction(selectedColumns: selectedColumns, isClassifier: isClassifier)
            }
        }
    }
    private func getModel(url: URL, completion: @escaping (MLModel?) -> Void) {
        var result: MLModel?
        
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            if let loadedModel = loadedModels.first(where: { $0.url == url })?.model {
                // If the model is already loaded, return it immediately
                result = loadedModel
            } else {
                do {
                    let compiledUrl: URL = try MLModel.compileModel(at: url)
                    result = try MLModel(contentsOf: compiledUrl)
                    let newModel = loadedModel(model: result!, url: url)
                    loadedModels.append(newModel)
                    completion(result)
                } catch {
                    // Handle the error
                    fatalError(error.localizedDescription)
                }
            }
        }
    }

    private func incorporatedPrediction(selectedColumns: [Columns], isClassifier: Bool) {
        let tableDictionary = convertDataTableToDictionary()
        let provider = try! MLArrayBatchProvider(dictionary: tableDictionary)
        let predictions = try! predictionModel?.predictions(from: provider, options: MLPredictionOptions())
        var predictedValues = [Double]()
        for i in 0..<(predictions?.count ?? 0) {
            predictedValues.append((predictions?.features(at: i).featureValue(for: targetColumn.name!)!.doubleValue)!)
        }
        let newColumn = MLDataColumn(predictedValues)
        self.mlDataTable.addColumn(newColumn, named: predictedColumnName)
        self.orderedColNames.append(predictedColumnName)
    }
    func removePredictionColumns(predictionColumName: String, filter: Bool? = false) {
        if self.mlDataTable.columnNames.contains(predictedColumnName) && filter != true {
            self.mlDataTable.removeColumn(named: predictedColumnName)
            for i in 0..<orderedColNames.count {
                if orderedColNames[i] == predictedColumnName {
                    self.orderedColNames.remove(at: i)
                }
            }
        }
    }
    func convertDataTableToDictionary() -> [String: [Any]] {
        var dictionary = [String: [Any]]()
        for columnName in self.mlDataTable.columnNames {
            let rows = self.mlDataTable[columnName]
            switch self.mlDataTable[columnName].type {
            case .int:
                dictionary[columnName] = Array(rows.map { $0.intValue })
            case .double:
                dictionary[columnName] = Array(rows.map { $0.doubleValue })
            case .string:
                dictionary[columnName] = Array(rows.map { $0.stringValue })
            default:
                print("ValueType not found")
            }
        }
        return dictionary
    }
}
