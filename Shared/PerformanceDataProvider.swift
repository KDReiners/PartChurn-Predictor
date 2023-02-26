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
    var involvedColumnArray = [String]()
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
    var falseNegatives: Double!
    var trueNegatives: Double!
    var falsePositives: Double!
    var truePositives: Double!
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
            if self.model.model2predictions?.count ?? 0 > 0 {
                return fillPredictionKPIS()
            } else {
                return [PredictionKPI]()
            }
        }
    }
    var involvedColumns: TableColumn<PredictionKPI,Never, VerticalGridCell , Text> {
        TableColumn("Involved Columns") { col in
            VerticalGridCell(textValues: col.involvedColumnArray)
        }
        .width(min: 150, ideal: 200, max: 250)
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
    var timeSlices: TableColumn<PredictionKPI, Never, TextViewCell, Text> {
        TableColumn("TimeSlices") { row in
            TextViewCell(textValue: row.timeSpan)
        }
    }
    var model: Models
               init(model: Models) {
        self.model = model
        self.predictionsDataModel = PredictionsModel(model: self.model)
    }
    private func fillPredictionKPIS() -> [PredictionKPI] {
        var result = [PredictionKPI]()
        for prediction in predictionsDataModel.items.filter( { $0.prediction2model == self.model}) {
            for algorithm in prediction.prediction2algorithms?.allObjects as![Algorithms] {
                var predictionKPI = PredictionKPI()
                predictionKPI.prediction = prediction
                predictionKPI.involvedColumnArray = predictionsDataModel.includedColumns(prediction: prediction).map({$0.name! })
                predictionKPI.algorithm = algorithm.name!
                for predictionMetricValue in (prediction.prediction2predictionmetricvalues?.allObjects as! [Predictionmetricvalues]).filter({ $0.predictionmetricvalue2algorithm == algorithm }) {
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
                        predictionKPI.falseNegatives = Double(predictionMetricValue.value)
                    case "trueNegatives":
                        predictionKPI.trueNegatives = Double(predictionMetricValue.value)
                    case "falsePositives":
                        predictionKPI.falsePositives = Double(predictionMetricValue.value)
                    case "truePositives":
                        predictionKPI.truePositives = Double(predictionMetricValue.value)
                    default:
                        print("KPI not found: " + predictionMetricType)
                    }
                }
                result.append(predictionKPI)
            }
        }
        return result
    }
}
