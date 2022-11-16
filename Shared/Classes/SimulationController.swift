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
            result = MlDataTableProviderContext(mlDataTableProvider: MlDataTableProvider(), model: model)
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
        var joinColums: [Columns]!
        init(mlDataTableProvider: MlDataTableProvider, model: Models) {
            self.mlDataTableProvider = mlDataTableProvider
            self.mlDataTableProvider.model = model
            self.model = model
            self.columnsDataModel = ColumnsModel(model: self.model)
            self.joinColums = columnsDataModel.joinColumns
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
        @ViewBuilder func getView(customColumn: CustomColumn, rowIndex: Int) -> some View {
            
            
            let column = columnsDataModel.items.first(where: { $0.ispartofprimarykey == 1 && $0.name == customColumn.title })
            if column == nil {
                SimulationField(customColum: customColumn, mlDataTableProvider: self.mlDataTableProvider, rowIndex: rowIndex)
            } else {
                Text(customColumn.rows[rowIndex])
                    .foregroundColor(.gray)
            }
        }
    }
    struct SimulationField: View {
        @State var customColum: CustomColumn
        var mlDataTableProvider: MlDataTableProvider
        var rowIndex: Int
        var body: some View {
            TextField("", text: $customColum.rows[rowIndex])
                .onReceive(Just($customColum.rows[rowIndex])) { text in
                    if mlDataTableProvider.selectedRowIndex != nil {
                        switch mlDataTableProvider.mlDataTable[customColum.title].type {
                        case MLDataValue.ValueType.int:
                            mlDataTableProvider.mlRowDictionary[customColum.title] = Int(text.wrappedValue)
                        case MLDataValue.ValueType.double:
                            mlDataTableProvider.mlRowDictionary[customColum.title] = Double(text.wrappedValue.preparedToDecimalNumberConversion)
                        case MLDataValue.ValueType.string:
                            mlDataTableProvider.mlRowDictionary[customColum.title] = text.wrappedValue
                        default: fatalError("Could not find valueType")
                        }
                    }
                }
        }
    }
    struct JoinCondition {
        var Conditions: Dictionary<String, Any>
    }
}
