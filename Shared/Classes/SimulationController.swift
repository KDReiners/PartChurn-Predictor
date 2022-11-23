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
    @State var mlRowDictionary = [String: MLDataValueConvertible]()
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
        @ViewBuilder func getView(customColumn: CustomColumn, rowIndex: Int) -> some View {
            let column = columnsDataModel.items.first(where: { $0.ispartofprimarykey == 1 && $0.name == customColumn.title })
            if column == nil {
                SimulationField(customColumn: customColumn, mlDataTableProvider: self.mlDataTableProvider, field: customColumn.rows[rowIndex], rowIndex: rowIndex)
            } else {
                Text(customColumn.rows[rowIndex])
                    .foregroundColor(.gray)
            }
        }
        struct SimulationField: View {
            var customColumn: CustomColumn
            var mlDataTableProvider: MlDataTableProvider
            @State var field: String
            var rowIndex: Int
            var body: some View {
                TextField("", text: $field)
                    .onReceive(Just(field)) { text in
                        if mlDataTableProvider.selectedRowIndex != nil
                                && mlDataTableProvider.mlDataTable.columnNames.contains(customColumn.title) == true {
                            print(customColumn.title + " " + text)
                            switch mlDataTableProvider.mlDataTable[customColumn.title].type {
                            case MLDataValue.ValueType.int:
                                self.mlDataTableProvider.mlRowDictionary[customColumn.title] = Int(text)
                            case MLDataValue.ValueType.double:
                                self.mlDataTableProvider.mlRowDictionary[customColumn.title] = Double(text.preparedToDecimalNumberConversion)
                            case MLDataValue.ValueType.string:
                                self.mlDataTableProvider.mlRowDictionary[customColumn.title] = text
                            default: fatalError("Could not find valueType")
                            }
                        }
                    }
            }
        }
        
    }
   
}
