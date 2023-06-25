//
//  Models.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 24.06.23.
//

import Foundation
import CoreML
struct loadedModel: Identifiable {
    let id = UUID()
    var model: MLModel
    var path: String?
    var url: URL
}
