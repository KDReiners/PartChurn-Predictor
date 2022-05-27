//
//  GenericFeatureProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 25.05.22.
//

import Foundation
import CoreML
import CreateML
internal class featureProviderGenerator<T> where T: CoreML.MLModel{
    var model: T
    var featureProviders = [MLFeatureProvider]()
    var dataDictionary: Dictionary<String, [String]>
    var featureValues = [MLFeatureValue]()
    var dataPointFeatures = [String: [MLFeatureValue]]()
    init(model: T, modelDictionary: Dictionary<String, [String]>) {
        self.model = model
        self.dataDictionary = modelDictionary
        let inputFeatures = model.modelDescription.inputDescriptionsByName
        for inputFeature in inputFeatures {
            var newFeature:MLFeatureValue
            for value in dataDictionary[inputFeature.value.name]!.enumerated() {
                newFeature = MLFeatureValue(string: "\(value)")
                featureValues.append(newFeature)
            }
            dataPointFeatures[inputFeature.value.name] = featureValues
            featureValues.removeAll()
        }
        if let provider = try? MLDictionaryFeatureProvider(dictionary: dataPointFeatures) {
                 featureProviders.append(provider)}
            
    }
}
