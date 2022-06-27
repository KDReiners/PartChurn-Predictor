//
//  ManagerModels.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 24.06.22.
//

import Foundation
public class ManagerModels: ObservableObject {
    private var _modelsDataModel: ModelsModel?
    @Published var modelIsInstantiated = false
    public var modelsDataModel: ModelsModel {
        get {
            if _modelsDataModel == nil {
                _modelsDataModel = ModelsModel()
                modelIsInstantiated = true
            }
            return _modelsDataModel!
        }
    }
    public func deinitAll() -> Void {
        _modelsDataModel?.detachValues()
        _modelsDataModel = nil
        modelIsInstantiated = false
    }
   
}
