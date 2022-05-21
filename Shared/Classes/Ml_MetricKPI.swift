//
//  File.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 12.05.22.
//

import Foundation
import CreateML
import SwiftUI
internal class Ml_MetricKPI: ObservableObject {
    struct section {
        var dataSetType: String?
        var metricType: [String]?
    }
    var currentDataSetType = ""
    var worstTrainingError: Double  = 0
    var worstValidationError: Double = 0
    var worstEvalutationError: Double = 0
    var trainingRootMeanSquaredError: Double = 0
    var validatitionRootMeanSquaredError: Double = 0
    var evaluationRootMeanSquaredError: Double = 0
    var dictOfMetrics = Dictionary<String, Double>()
    var sections = [section]()
    init() {
        dictOfMetrics["trainingMetrics.maximumError"] = 0
        dictOfMetrics["trainingMetrics.rootMeanSquaredError"] = 0
        dictOfMetrics["validationMetrics.maximumError"] = 0
        dictOfMetrics["validationMetrics.rootMeanSquaredError"] = 0
        dictOfMetrics["evaluationMetrics.maximumError"] = 0
        dictOfMetrics["evaluationMetrics.rootMeanSquaredError"] = 0
        for key in dictOfMetrics.keys {
            var newSection: section
            let dataSetType = resolveDictOfMetrics(key: key).datasetType
            let metricType = resolveDictOfMetrics(key: key).metricType
            if currentDataSetType != dataSetType {
                newSection = section()
                newSection.dataSetType = dataSetType
                newSection.metricType = Array<String>()
                newSection.metricType?.append(metricType)
                sections.append(newSection)
            } else {
                var currentSection = sections.first(where: { return $0.dataSetType == metricType})
                currentSection?.metricType?.append(metricType)
            }
        }
                                                        
    }
    
    internal func postMetric(model: Models, file: Files, algorithmName: String) {
        
        let metricsvaluesModel = MetricvaluesModel()
        let datasetTypeModel = DatasettypesModel()
        let metricsModel = MetricsModel()
        let algorithmsModel = AlgorithmsModel()
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
           var algorithmType = algorithmsModel.items.first(where: {
               return $0.name == algorithmName } )
            if algorithmType == nil {
                algorithmType = algorithmsModel.insertRecord()
                algorithmType?.name = algorithmName
            }
        
            let newMetric = metricsvaluesModel.insertRecord()
            /// Set relations
            newMetric.metricvalue2model = model
            newMetric.metricvalue2file = file
            newMetric.metricvalue2datasettype = datasetType
            newMetric.metricvalue2algorithm = algorithmType
            metricType.metric2datasettypes = metricType.metric2datasettypes?.addingObjects(from: [datasetType]) as NSSet?
            metricType.metric2metricvalues = metricType.metric2metricvalues?.addingObjects(from: [newMetric]) as NSSet?
            /// Set value
            newMetric.value = item.value
            /// Save changes
            metricsvaluesModel.saveChanges()
            datasetTypeModel.saveChanges()
            metricsModel.saveChanges()
            algorithmsModel.saveChanges()
        }
    }
    func resolveDictOfMetrics(key: String) -> (datasetType: String, metricType: String) {
        let subTypes = key.split(separator: ".", maxSplits: 1)
        let datasetType = subTypes[0].replacingOccurrences(of: "Metrics", with: "")
        let metricType = String(subTypes[1])
        return(datasetType, metricType)
        
    }
    
   
}
