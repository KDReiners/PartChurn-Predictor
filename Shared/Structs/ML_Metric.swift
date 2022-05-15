//
//  File.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 12.05.22.
//

import Foundation
import CreateML
struct Ml_MetricKPI {
    var worstTrainingError: Double  = 0
    var worstValidationError: Double = 0
    var worstEvalutationError: Double = 0
    var trainingRootMeanSquaredError: Double = 0
    var validatitionRootMeanSquaredError: Double = 0
    var evaluationRootMeanSquaredError: Double = 0
    
    
}
