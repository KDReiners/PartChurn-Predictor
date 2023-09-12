//
//  TabularDataProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 24.01.23.
//

import Foundation
import SwiftUI
import CoreData
struct NavigationViewCell: View {
    var prediction: Predictions!
    var algorithmName: String!
    var body: some View {
            Button(action: {
                SimulatorView(prediction: prediction, algorithmName: algorithmName).openNewWindow()
            }) {
                Text("Open New Window")
            }
        }
}
struct VerticalGridCell : View {
    var textValues: [String]
    init(textValues: [String]) {
        self.textValues = textValues
    }
    var body: some View {
        let cells = textValues
        let gridItems = [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)]
        ScrollView {
            LazyVGrid(columns: gridItems) {
                ForEach(cells, id: \.self) { cell in
                    Text(cell).scaledToFit()
                }
            }
        }
    }
}
struct TextViewCell: View {
    var textValue: String = ""
    var body: some View {
        Text(textValue)
    }
}
struct DoubleValueCell: View {
    var value: Double = 0
    var body: some View {
        Text(BaseServices.doubleFormatter.string(from: NSNumber(value: value))!)
    }
}
struct IntValueCell: View {
    var value: Int = 0
    var body: some View {
        Text(BaseServices.intFormatter.string(from: NSNumber(value: value))!)
    }
}
internal struct PredictionKPI: Identifiable  {
    var id = UUID()
    var prediction: Predictions!
    var inputColumnsNames = [String]()
    var algorithm: String! = ""
    var timeSpan: String! = ""
    var metricName: String! = ""
    var metricValue: Double! = 0.00
    var rowCount: Int! = 0
    var targetsAtOptimum: String! = ""
    var dirtiesAtThreshold: String! = ""
    var targetsAtThreshold: String! = ""
    var targetValue: String! = ""
    var predictionValueAtThreshold: String! = ""
    var predictionValueAtOptimum: String! = ""
    var dirtiesAtOptimum: String! = ""
    var targetPopulation: String! = ""
    var threshold: String! = ""
    var rootMeanSquaredError: String! = ""
    var maximumError: String! = ""
    var dataSetType: String = "Evaluation"
    var falseNegatives: Double = 0.0000001
    var trueNegatives: Double = 0.0000001
    var falsePositives: Double = 0.0000001
    var truePositives: Double = 0.0000001
    var lookAhead: Int = 0
    var timeSliceFrom: Int = 0
    var timeSliceTo: Int = 0
    var precision: Double! {
        get {
            return (truePositives / (truePositives + falsePositives))
        }
    }
    var recall: Double! {
        get {
            return (truePositives / (truePositives + falseNegatives))
        }
    }
    var f1Score: Double! {
        get {
            return (2 * truePositives) / (2 * truePositives + falseNegatives + falsePositives)
        }
    }
    var specifity: Double! {
        get {
            return (trueNegatives / (trueNegatives + falsePositives))
        }
    }
    
}
internal class PerformanceDataProvider: ObservableObject {
    var predictionsDataModel: PredictionsModel
    internal var PredictionKPIS: [PredictionKPI] {
        get {
            if self.model.model2observations?.count ?? 0 > 0 {
                return fillPredictionKPIS()
            } else {
                return [PredictionKPI]()
            }
        }
    }
    var involvedColumns: TableColumn<PredictionKPI,Never, VerticalGridCell , Text> {
        TableColumn("Involved Columns") { col in
            VerticalGridCell(textValues: col.inputColumnsNames)
        }
        .width(min: 150, ideal: 200, max: 250)
    }
    var columnsCount: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("Column(s) count") { row in
            TextViewCell(textValue: "\(row.inputColumnsNames.count)")
        }
    }
    var timeSliceFrom: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("TimeSlice from") { row in
            TextViewCell(textValue: "\(row.timeSliceFrom)")
        }
    }
    var timeSliceTo: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("TimeSlice to") { row in
            TextViewCell(textValue: "\(row.timeSliceTo)")
        }
    }
    var lookAhead: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("LookAhead") { row in
            TextViewCell(textValue: "\(row.lookAhead)")
        }
    }
    var timeSlices: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("TimeSlices") { row in
            TextViewCell(textValue: row.timeSpan)
        }
    }
    var algorithm: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("Algorithm") { row in
            TextViewCell(textValue:  row.algorithm)
        }
    }
    var precision: TableColumn<PredictionKPI, Never, DoubleValueCell, Text> {
        TableColumn("Precision") { row in
            DoubleValueCell(value: row.precision)
        }
    }
    var recall: TableColumn<PredictionKPI, Never, DoubleValueCell, Text> {
        TableColumn("Recall") { row in
            DoubleValueCell(value: row.recall)
        }
    }
    var f1Score: TableColumn<PredictionKPI, Never, DoubleValueCell, Text> {
        TableColumn("F1-Score") { row in
            DoubleValueCell(value: row.f1Score)
        }
    }
    var specifity: TableColumn<PredictionKPI, Never, DoubleValueCell, Text> {
        TableColumn("Specifity") { row in
            DoubleValueCell(value: row.specifity)
        }
    }
    var falseNegatives: TableColumn<PredictionKPI, Never, IntValueCell, Text> {
        TableColumn("false Negatives") { row in
            IntValueCell(value: Int(row.falseNegatives))
        }
    }
    var falsePositives: TableColumn<PredictionKPI, Never, IntValueCell, Text> {
        TableColumn("false Positives") { row in
            IntValueCell(value: Int(row.falsePositives))
        }
    }
    var trueNegatives: TableColumn<PredictionKPI, Never, IntValueCell, Text> {
        TableColumn("true Negatives") { row in
            IntValueCell(value: Int(row.trueNegatives))
        }
    }
    var truePositives: TableColumn<PredictionKPI, Never, IntValueCell, Text> {
        TableColumn("true Positives") { row in
            IntValueCell(value: Int(row.truePositives))
        }
    }
    var simulation: TableColumn<PredictionKPI, Never, NavigationViewCell, Text> {
        TableColumn("Link") { row in
            NavigationViewCell(prediction: row.prediction, algorithmName: row.algorithm)
        }
    }

    var model: Models
               init(model: Models) {
        self.model = model
        self.predictionsDataModel = PredictionsModel(model: self.model)
    }
    private func fillPredictionKPIS() -> [PredictionKPI] {
        var result = [PredictionKPI]()
        for observation in ObservationsModel().items.filter( { $0.observation2model == self.model}) {
            let mlExplainColumnCluster = MLExplainColumnCluster(prediction: observation.observation2prediction!)
            let inputColumns = mlExplainColumnCluster.inputColumns.map( { $0.name! })
            for algorithm in observation.observation2prediction!.prediction2algorithms?.allObjects as![Algorithms] {
                for lookAheadItem in observation.observation2prediction!.prediction2lookaheads?.allObjects as! [Lookaheads] {
                    if LookaheadsModel.LookAheadItemRelations(lookAheadItem: lookAheadItem).connectedAlgorihms .contains(algorithm) {
                        var predictionKPI = PredictionKPI()
                        predictionKPI.prediction = observation.observation2prediction
                        predictionKPI.inputColumnsNames = inputColumns
                        predictionKPI.algorithm = algorithm.name!
                        predictionKPI.timeSpan = String(observation.observation2prediction!.seriesdepth)
                        for predictionMetricValue in (observation.observation2predictionmetricvalues?.allObjects as! [Predictionmetricvalues]).filter({ $0.predictionmetricvalue2algorithm == algorithm && $0.predictionmetricvalue2lookahead == lookAheadItem }) {
                            let predictionMetricType = predictionMetricValue.predictionmetricvalue2predictionmetric!.name!
                            switch predictionMetricType {
                            case "targetsAtOptimum":
                                predictionKPI.targetsAtOptimum = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "dirtiesAtThreshold":
                                predictionKPI.dirtiesAtThreshold = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "dirtiesAtOptimum":
                                predictionKPI.dirtiesAtOptimum = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "targetValue":
                                predictionKPI.targetValue = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "threshold":
                                predictionKPI.threshold = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "predictionValueAtThreshold":
                                predictionKPI.predictionValueAtThreshold = BaseServices.doubleFormatter.string(from: predictionMetricValue.value as NSNumber)!
                            case "targetsAtThreshold":
                                predictionKPI.targetsAtThreshold = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "targetPopulation":
                                predictionKPI.targetPopulation = BaseServices.intFormatter.string(from:predictionMetricValue.value.toInt()! as NSNumber)
                            case "predictionValueAtOptimum":
                                predictionKPI.predictionValueAtOptimum =  BaseServices.doubleFormatter.string(from: predictionMetricValue.value as NSNumber)!
                            case "falseNegatives":
                                print("falseNegatives set to: \(predictionMetricValue.value)")
                                predictionKPI.falseNegatives = Double(predictionMetricValue.value)
                            case "trueNegatives":
                                predictionKPI.trueNegatives = Double(predictionMetricValue.value)
                            case "falsePositives":
                                predictionKPI.falsePositives = Double(predictionMetricValue.value)
                            case "truePositives":
                                predictionKPI.truePositives = Double(predictionMetricValue.value)
                            case "lookAhead":
                                predictionKPI.lookAhead = Int(predictionMetricValue.value)
                                print("assigned lookAhead \(predictionMetricValue.value)")
                            case "timeSliceTo":
                                predictionKPI.timeSliceTo = Int(predictionMetricValue.value)
                                print("assigned timeSliceTo \(predictionMetricValue.value)")
                            case "timeSliceFrom":
                                predictionKPI.timeSliceFrom = Int(predictionMetricValue.value)
                                print("assigned timeSliceFrom \(predictionMetricValue.value)")
                            default:
                                print("KPI not found: " + predictionMetricType)
                            }
                        }
                        result.append(predictionKPI)
                    }
                }
            }
        }
        return result
    }
}
