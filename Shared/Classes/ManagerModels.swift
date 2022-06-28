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
    private var _valuesDataModel: ValuesModel?
    private var _dataSetTypesDataModel: DatasettypesModel?
    private var _metricsDataModel: MetricsModel?

    init() {
        if self.modelsDataModel.items.count == 0 {
            let defaultModel = self.modelsDataModel.insertRecord()
            defaultModel.name = "New Analysis"
            let training = self.dataSetTypesDataModel.insertRecord()
            training.name = "training"
            let validation = self.dataSetTypesDataModel.insertRecord()
            validation.name = "validation"
            let evaluation = self.dataSetTypesDataModel.insertRecord()
            evaluation.name = "evaluation"
            let rootMeanSquaredError = self.metricsDataModel.insertRecord()
            rootMeanSquaredError.name = "rootMeanSquaredError"
            let maximumError = self.metricsDataModel.insertRecord()
            maximumError.name = "maximumError"
            BaseServices.save()
        }
    }
    public var modelsDataModel: ModelsModel {
        get {
            if _modelsDataModel == nil {
                _modelsDataModel = ModelsModel()
            }
            return _modelsDataModel!
        }
    }
    public var filesDataModel: FilesModel {
        get {
            if _filesDataModel == nil {
                _filesDataModel = FilesModel()
            }
            return _filesDataModel!
        }
    }
    public var columnssDataModel: ColumnsModel {
        get {
            if _columnsDataModel == nil {
                _columnsDataModel = ColumnsModel()
            }
            return _columnsDataModel!
        }
    }
    public var valuessDataModel: ValuesModel {
        get {
            if _valuesDataModel == nil {
                _valuesDataModel = ValuesModel()
            }
            return _valuesDataModel!
        }
    }
    public var dataSetTypesDataModel: DatasettypesModel {
        get {
            if _dataSetTypesDataModel == nil {
                _dataSetTypesDataModel = DatasettypesModel()
            }
            return _dataSetTypesDataModel!
        }
    }
    public var metricsDataModel: MetricsModel {
        get {
            if _metricsDataModel == nil {
                _metricsDataModel = MetricsModel()
            }
            return _metricsDataModel!
        }
    }
    public func deinitAll() -> Void {
    }
   
}
