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
    static func returnFittingProviderContext(model: Models, lookAhead: Int,  prediction: Predictions? = nil, algorithmName: String? = nil) -> MlDataTableProviderContext? {
        var result: MlDataTableProviderContext?
        result = providerContexts.filter { $0.model == model  && $0.clusterSelection?.prediction == prediction && $0.lookAhead == lookAhead}.first
        if result == nil {
            result = MlDataTableProviderContext(mlDataTableProvider: MlDataTableProvider(model: model), prediction: prediction,  algorithmName: algorithmName, lookAhead: lookAhead)
            self.providerContexts.append(result!)
        }
        guard let result = result else {
            fatalError()
        }
        return result
    }
    class MlDataTableProviderContext: ObservableObject {
        @Published var mlDataTableProvider: MlDataTableProvider
        @Published var lookAhead: Int!
        var pythonInteractor: PythonInteractor!
        var gridItems = [GridItem]()
        var clusterSelection: PredictionsModel.PredictionCluster?
        var predictionsDataModel = PredictionsModel()
        var columnsDataModel:  ColumnsModel!
        var composer: FileWeaver!
        var combinator: Combinator!
        var model: Models!

        var lookAheadPath: URL? {
            get {
                var result: URL? = nil
                if let prediction = clusterSelection?.prediction {
                    let lookAhead = PredictionsModel(model: self.model!).returnLookAhead(prediction: prediction, lookAhead: lookAhead)
                    result = BaseServices.sandBoxDataPath.appendingPathComponent((prediction.prediction2model?.name)!).appendingPathComponent(prediction.objectID.uriRepresentation().lastPathComponent).appendingPathComponent(lookAhead.objectID.uriRepresentation().lastPathComponent);
                }
                return result
            }
        }
        init(mlDataTableProvider: MlDataTableProvider,  prediction: Predictions?, algorithmName: String? = nil, lookAhead: Int) {
            self.lookAhead = lookAhead
            if prediction != nil {
                predictionsDataModel.createPredictionForModel(model: prediction!.prediction2model!)
                self.clusterSelection = predictionsDataModel.arrayOfPredictions.first(where: { $0.prediction == prediction })
            }
            self.clusterSelection?.prediction = prediction
            self.mlDataTableProvider = mlDataTableProvider
            self.model = mlDataTableProvider.model
            self.columnsDataModel = ColumnsModel(model: self.model)
            self.composer = FileWeaver(model: self.model, lookAhead: self.lookAhead)
            predictionsDataModel.createPredictionForModel(model: self.model)
            self.combinator = Combinator(model: self.model, orderedColumns: (composer?.orderedColumns)!, mlDataTable: (composer?.mlDataTable_Base)!)
            self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
            self.mlDataTableProvider.orderedColumns = composer?.orderedColumns!
            self.mlDataTableProvider.prediction = prediction
            
        }
        func setPrediction(prediction: Predictions) {
            if self.clusterSelection?.prediction != prediction {
                self.clusterSelection = predictionsDataModel.arrayOfPredictions.first(where: { $0.prediction == prediction })
                self.mlDataTableProvider.prediction = prediction
                self.mlDataTableProvider.selectedColumns = clusterSelection?.columns
                /// KDR
//                generateValuesView()
            }
        }
        func generateValuesView() {
            let callingFunction = #function
            let className = String(describing: type(of: self))
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
            self.mlDataTableProvider.mlDataTable = try? self.mlDataTableProvider.buildMlDataTable().mlDataTable
            self.mlDataTableProvider.updateTableProvider(callingFunction: callingFunction, className: className, lookAhead: 0)
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

            @State var isEditing: Bool = false
            @State var mlRowDictionary = [String: MLDataValueConvertible]()
            init(customColumn: CustomColumn, rowIndex: Int, mlDataTableProvider: MlDataTableProvider, columnsDataModel: ColumnsModel) {
                self.customColumn = customColumn
                self.rowIndex = rowIndex
                self.mlDataTableProvider = mlDataTableProvider
                self.columnsDataModel = columnsDataModel
            }
            var body: some View {
                TextField("Hier gibt es keinen Wert", text: binding(for: customColumn.title), onEditingChanged: { (changed) in
                    isEditing = changed
                    if isEditing == false {
                        guard let updateValue =  $mlRowDictionary[customColumn.title].wrappedValue as? String else { return }
                        updateRowDictionary(updateValue: updateValue)
                        self.mlDataTableProvider.updateRequest = true
                    }
                }).disabled(self.mlDataTableProvider.mlRowDictionary.count  == 0)
            }
            private func binding(for key: String) -> Binding<String> {
                    return .init(
                        get: {
                            if mlDataTableProvider.selectedRowIndex != nil
                                && mlDataTableProvider.mlDataTable.columnNames.contains(customColumn.title) == true
                                && isEditing == false {
                                switch mlDataTableProvider.mlDataTable[customColumn.title].type {
                                case MLDataValue.ValueType.int:
                                    return String((self.mlDataTableProvider.mlRowDictionary[customColumn.title]?.dataValue.intValue)!)
                                case MLDataValue.ValueType.double:
                                    return String((self.mlDataTableProvider.mlRowDictionary[customColumn.title]?.dataValue.doubleValue)!)
                                case MLDataValue.ValueType.string:
                                    return (self.mlDataTableProvider.mlRowDictionary[customColumn.title]?.dataValue.stringValue)!
                                default: return "Could not find valueType"
                                }
                            } else { return  mlRowDictionary[customColumn.title]?.dataValue.stringValue ?? "" }
                        },
                        set: {
                            mlRowDictionary[customColumn.title] = $0
                        })
                }
            private func updateRowDictionary(updateValue: String) {
                switch mlDataTableProvider.mlDataTable[customColumn.title].type {
                case MLDataValue.ValueType.int:
                    var newValue: Int
                    newValue = Int.parse(from: updateValue) ?? 0
                    self.mlDataTableProvider.mlRowDictionary[customColumn.title] = newValue
                    case MLDataValue.ValueType.double:
                    var newValue: Double
                    newValue = Double.parse(from: updateValue) ?? 0.00
                        self.mlDataTableProvider.mlRowDictionary[customColumn.title] = Double(String(newValue).preparedToDecimalNumberConversion)
                    case MLDataValue.ValueType.string:
                        self.mlDataTableProvider.mlRowDictionary[customColumn.title] = updateValue
                    default: self.mlDataTableProvider.mlRowDictionary[customColumn.title] = "Could not find valueType"
                    }
            }
        }
    }
}

