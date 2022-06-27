//
//  ManagerModels.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 24.06.22.
//

import Foundation
public class ManagerModels: ObservableObject {
    private var _modelsDataModel: ModelsModel?
    private var _filesDataModel: FilesModel?
    private var _columnsDataModel: ColumnsModel?
    @Published var modelIsInstantiated = false
    @Published var fileIsInstantiated = false
    @Published var columnIsInstantiated = false
    public var modelsDataModel: ModelsModel {
        get {
            if _modelsDataModel == nil {
                _modelsDataModel = ModelsModel()
                modelIsInstantiated = true
            }
            return _modelsDataModel!
        }
    }
    public var filesDataModel: FilesModel {
        get {
            if _filesDataModel == nil {
                _filesDataModel = FilesModel()
                fileIsInstantiated = true
            }
            return _filesDataModel!
        }
    }
    public var columnssDataModel: ColumnsModel {
        get {
            if _columnsDataModel == nil {
                _columnsDataModel = ColumnsModel()
                columnIsInstantiated = true
            }
            return _columnsDataModel!
        }
    }
    public func deinitAll() -> Void {
        _modelsDataModel?.detachValues()
        _modelsDataModel = nil
        modelIsInstantiated = false
    }
   
}
