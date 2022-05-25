//
//  GenericFeatureProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 25.05.22.
//

import Foundation
import CoreML
internal class featureProviderGenerator<T> where T: CoreML.MLModel{
    var model: T
    init(model: T) {
        self.model = model
        let features = model.modelDescription.inputDescriptionsByName
    }
}
