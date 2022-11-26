//
//  SimulationController.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 12.11.22.
//

import Foundation
import CreateML
import SwiftUI
import Combine
class SimulationController: ObservableObject {
    static var providerContexts = [MlDataTableProviderContext]()
    static func returnFittingProviderContext(model: Models) -> MlDataTableProviderContext? {
        var result: MlDataTableProviderContext?
        result = providerContexts.filter { $0.model == model }.first
        if result == nil {
            result = MlDataTableProviderContext(mlDataTableProvider: MlDataTableProvider(model: model))
            self.providerContexts.append(result!)
        }
        guard let result = result else {
            fatalError()
        }
        return result
    }
    class MlDataTableProviderContext: ObservableObject {
        @Published var mlDataTableProvider: MlDataTableProvider
        var gridItems = [GridItem]()
        var clusterSelection: PredictionsModel.predictionCluster?
        var predictionsDataModel = PredictionsModel()
        var columnsDataModel:  ColumnsModel!
        var composer: FileWeaver!
        var combinator: Combinator!
        var model: Models!
        init(mlDataTableProvider: MlDataTableProvider) {
            self.mlDataTableProvider = mlDataTableProvider
            self.model = mlDataTableProvider.model
            self.columnsDataModel = ColumnsModel(model: self.model)
            self.mlDataTableProvider.regressorName  = "MLBoostedTreeRegressor"
            self.composer = FileWeaver(model: self.model)
            predictionsDataModel.createPredictionForModel(model: self.model)
            self.combinator = Combinator(model: self.model, orderedColumns: (composer?.orderedColumns)!, mlDataTable: (composer?.mlDataTable_Base)!)
            self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
            self.mlDataTableProvider.orderedColumns = composer?.orderedColumns!
        }
        func setPrediction(prediction: Predictions) {
            if self.clusterSelection?.prediction != prediction {
                self.clusterSelection = predictionsDataModel.arrayOfPredictions.first(where: { $0.prediction == prediction })
                self.mlDataTableProvider.prediction = prediction
                self.mlDataTableProvider.selectedColumns = clusterSelection?.columns
                generateValuesView()
            }
        }
        func generateValuesView() {
            if let timeSeriesRows = self.clusterSelection?.connectedTimeSeries {
                var selectedTimeSeries = [[Int]]()
                for row in timeSeriesRows {
                    let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                    selectedTimeSeries.append(innerResult)
                }
                self.mlDataTableProvider.timeSeries = selectedTimeSeries
            } else {
                self.mlDataTableProvider.timeSeries = nil
            }
            self.mlDataTableProvider.mlDataTableRaw = nil
            self.mlDataTableProvider.mlDataTable = self.mlDataTableProvider.buildMlDataTable().mlDataTable
            self.mlDataTableProvider.updateTableProvider()
            self.mlDataTableProvider.loaded = false
        }
        func createGridItems() {
            self.mlDataTableProvider.mlColumns!.forEach { col in
                let newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                self.gridItems.append(newGridItem)
            }
        }
        struct EditValueView: View {
            var customColumn: CustomColumn
            var rowIndex: Int
            var mlDataTableProvider: MlDataTableProvider
            var columnsDataModel: ColumnsModel
            init(customColumn: CustomColumn, rowIndex: Int, mlDataTableProvider: MlDataTableProvider, columnsDataModel: ColumnsModel) {
                self.customColumn = customColumn
                self.rowIndex = rowIndex
                self.mlDataTableProvider = mlDataTableProvider
                self.columnsDataModel = columnsDataModel
            }
            var body: some View {
                TextField("Hier gibt es keinen Wert", text: binding(for: customColumn.title))
            }
            private func binding(for key: String) -> Binding<String> {
                    return .init(
                        get: {
                            if mlDataTableProvider.selectedRowIndex != nil && mlDataTableProvider.mlDataTable.columnNames.contains(customColumn.title) == true {
                                switch mlDataTableProvider.mlDataTable[customColumn.title].type {
                                case MLDataValue.ValueType.int:
                                    return String((self.mlDataTableProvider.mlRowDictionary[customColumn.title]?.dataValue.intValue)!)
                                case MLDataValue.ValueType.double:
                                    return String((self.mlDataTableProvider.mlRowDictionary[customColumn.title]?.dataValue.doubleValue)!)
                                case MLDataValue.ValueType.string:
                                    return (self.mlDataTableProvider.mlRowDictionary[customColumn.title]?.dataValue.stringValue)!
                                default: return "Could not find valueType"
                                }
                            } else { return "" }
                        },
                        set: {
                            switch mlDataTableProvider.mlDataTable[customColumn.title].type {
                            case MLDataValue.ValueType.int:
                                var newValue: Int
                                newValue = Int.parse(from: $0) ?? 0
                                self.mlDataTableProvider.mlRowDictionary[customColumn.title] = newValue
                                case MLDataValue.ValueType.double:
                                var newValue: Double
                                newValue = Double.parse(from: $0) ?? 0.00
                                    self.mlDataTableProvider.mlRowDictionary[customColumn.title] = Double(String(newValue).preparedToDecimalNumberConversion)
                                case MLDataValue.ValueType.string:
                                    self.mlDataTableProvider.mlRowDictionary[customColumn.title] = $0
                                default: self.mlDataTableProvider.mlRowDictionary[customColumn.title] = "Could not find valueType"
                                }
                        })
                }
        }
    }
}
