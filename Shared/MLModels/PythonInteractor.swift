//
//  PythonInteraction.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 05.03.23.
//

import Foundation
import PythonKit
class PythonInteractor {
    let np = Python.import("numpy")
    let plt = Python.import("matplotlib.pyplot")
    let pdp = Python.import("pdpbox.pdp")
    let ct = Python.import("coremltools")
    init(modelPath: URL) {
        let model = ct.models.MLModel(modelPath.path)
        let currentModel = ct.converters.keras.convert(model)
        model.save(modelPath.path)
        
    }
}

