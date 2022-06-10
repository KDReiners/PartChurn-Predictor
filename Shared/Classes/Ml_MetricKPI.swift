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
    internal struct section {
        var id = UUID()
        var dataSetType: String?
        var metricTypes: [metric]?
    }
    internal struct metric {
        var id = UUID()
        var metricType: String?
        var metricValue: Double = 0
    }
    var worstTrainingError: Double  = 0
    var worstValidationError: Double = 0
    var worstEvalutationError: Double = 0
    var trainingRootMeanSquaredError: Double = 0
    var validatitionRootMeanSquaredError: Double = 0
    var evaluationRootMeanSquaredError: Double = 0
    @Published var dictOfMetrics = Dictionary<String, Double>()
    internal var sections = [section]()
    internal func updateMetrics() {
        var newSection: section
        for key in dictOfMetrics.keys.sorted(by: >) {
            let value = dictOfMetrics[key]
            var newMectric = metric()
            let dataSetType = resolveDictOfMetrics(key: key).datasetType
            let metricType = resolveDictOfMetrics(key: key).metricType
            newMectric.metricValue = value!
            var currentSection = sections.first(where: { return $0.dataSetType == dataSetType})
            if currentSection == nil {
                newSection = section()
                newSection.dataSetType = dataSetType
                newMectric.metricType = metricType
                newSection.metricTypes = Array<metric>()
                newSection.metricTypes?.append(newMectric)
                sections.append(newSection)
            } else {
                newMectric.metricType = metricType
                newMectric.metricValue = value!
                currentSection?.metricTypes?.append(newMectric)
                if let section = sections.firstIndex(where: { return $0.dataSetType == dataSetType}) {
                    sections[section] = currentSection!
                }
            }
        }
    }
    
    init() {
        dictOfMetrics["trainingMetrics.maximumError"] = 0
        dictOfMetrics["trainingMetrics.rootMeanSquaredError"] = 0
        dictOfMetrics["validationMetrics.maximumError"] = 0
        dictOfMetrics["validationMetrics.rootMeanSquaredError"] = 0
        dictOfMetrics["evaluationMetrics.maximumError"] = 0
        dictOfMetrics["evaluationMetrics.rootMeanSquaredError"] = 0
    }
    
    internal func postMetric(model: Models, file: Files?, algorithmName: String) {
        
        let metricsvaluesModel = MetricvaluesModel()
        let datasetTypeModel = DatasettypesModel()
        let metricsModel = MetricsModel()
        let algorithmsModel = AlgorithmsModel()
        let obsoleteMetrics = metricsvaluesModel.items.filter({$0.metricvalue2model == model && $0.metricvalue2file == file && $0.metricvalue2algorithm?.name == algorithmName})
        for item in obsoleteMetrics {
            metricsvaluesModel.deleteRecord(record: item)
        }
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
