//
//  File.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 12.05.22.
//

import Foundation
import CreateML
struct Ml_MetricKPI {
    var trainingMetrics: MLRegressorMetrics?
    var validationMetrics: MLRegressorMetrics?
}
