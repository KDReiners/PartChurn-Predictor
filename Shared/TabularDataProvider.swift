//
//  TabularDataProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 24.01.23.
//

import Foundation
import SwiftUI
import CoreData
class TabularDataProvider: ObservableObject {
    var predictionsDataModel: PredictionsModel
    var PredictionKPIS: [PredictionKPI] {
        get {
            if self.model.model2predictions?.count ?? 0 > 0 {
                return fillPredictionKPIS()
            } else {
                return [PredictionKPI]()
            }
        }
    }
    var model: Models
    init(model: Models) {
        self.model = model
        self.predictionsDataModel = PredictionsModel(model: self.model)
    }
    struct PredictionKPI: Identifiable {
        var id = UUID()
        var groupingPattern: String?
        var algorithm: String?
        var metricName: String?
        var metricValue: Double?
        var rowCount: Int?
        var targetsAtOptimum: String?
        var dirtiesAtThreshold: String?
        var targetsAtThreshold: String?
        var targetValue: String?
        var predictionValueAtThreshold: String?
        var predictionValueAtOptimum: String?
        var dirtiesAtOptimum: String?
        var targetPopulation: String?
        var threshold: String?
        var rootMeanSquaredError: String?
        var maximumError: String?
        var dataSetType: String = "Evaluation"
        
    }
    private func fillPredictionKPIS() -> [PredictionKPI] {
        var result = [PredictionKPI]()
        for prediction in predictionsDataModel.items.filter( { $0.prediction2model == self.model}) {
            for algorithm in prediction.prediction2algorithms?.allObjects as![Algorithms] {
                var predictionKPI = PredictionKPI()
                for metricValue in (algorithm.algorithm2metricvalues?.allObjects as! [Metricvalues]).filter( { $0.metricvalue2datasettype?.name == "evaluation" && $0.metricvalue2prediction == prediction}) {
                    predictionKPI.groupingPattern = prediction.groupingpattern
                    predictionKPI.algorithm = algorithm.name!
                    predictionKPI.metricName = metricValue.metricvalue2metric?.name!
                    let metricName = predictionKPI.metricName ?? "no name"
                    switch metricName {
                    case "rootMeanSquaredError":
                        predictionKPI.rootMeanSquaredError = BaseServices.doubleFormatter.string(from: metricValue.value as NSNumber)!
                    case "maximumError":
                        predictionKPI.maximumError = BaseServices.doubleFormatter.string(from: metricValue.value as NSNumber)!
                    default:
                        print("KPI not found: " + (predictionKPI.metricName ?? "no Name provided!"))
                    }
                }
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
