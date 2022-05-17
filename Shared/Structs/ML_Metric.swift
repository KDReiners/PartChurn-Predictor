//
//  File.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 12.05.22.
//

import Foundation
import CreateML
import SwiftUI
struct Ml_MetricKPI {
    struct metricDetail {
        var datasetType: String
        var metricType: String
    }
    var worstTrainingError: Double  = 0
    var worstValidationError: Double = 0
    var worstEvalutationError: Double = 0
    var trainingRootMeanSquaredError: Double = 0
    var validatitionRootMeanSquaredError: Double = 0
    var evaluationRootMeanSquaredError: Double = 0
    var dictOfMetrics = Dictionary<String, Double>()
    init() {
        dictOfMetrics["trainingMetrics.maximumError"] = 0
        dictOfMetrics["trainingMetrics.rootMeanSquaredError"] = 0
        dictOfMetrics["validationMetrics.maximumError"] = 0
        dictOfMetrics["validationMetrics.rootMeanSquaredError"] = 0
        dictOfMetrics["evaluationMetrics.maximumError"] = 0
        dictOfMetrics["evaluationMetrics.rootMeanSquaredError"] = 0
                                                          
    }
    internal func postMetric(model: Models, file: Files) {
        
        let metricsvaluesModel = MetricvaluesModel()
        let datasetTypeModel = DatasettypesModel()
        let metricsModel = MetricsModel()
        for item in dictOfMetrics {
            let resolvedKey = resolveDictOfMetrics(key: item.key)
            let datasetType = datasetTypeModel.items.first(where: {
                return $0.name == resolvedKey.datasetType
            })
            let metricType = metricsModel.items.first(where: {
                return $0.name == resolvedKey.metricType
            })
            guard let datasetType = datasetType else {
                return
            }
            guard let metricType = metricType else {
                return
            }
            let newMetric = metricsvaluesModel.insertRecord()
            newMetric.metricvalue2model = model
            newMetric.metricvalue2file = file
            newMetric.value = item.value
            newMetric.metricvalue2metric?.metric2datasettypes =
            newMetric.metricvalue2metric?.metric2datasettypes?.addingObjects(from: [datasetType]) as NSSet?
            metricType.metric2metricvalues = metricType.metric2metricvalues?.addingObjects(from: [newMetric]) as NSSet?
            metricsvaluesModel.saveChanges()
            datasetTypeModel.saveChanges()
            metricsModel.saveChanges()
        }
    }
    func resolveDictOfMetrics(key: String) -> (datasetType: String, metricType: String) {
        let subTypes = key.split(separator: ".", maxSplits: 1)
        let datasetType = subTypes[0].replacingOccurrences(of: "Metrics", with: "")
        let metricType = String(subTypes[1])
        return(datasetType, metricType)
        
    }
    
   
}
