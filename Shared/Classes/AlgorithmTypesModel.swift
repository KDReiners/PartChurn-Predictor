//
//  AlgorithmTypesModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 28.01.23.
//

import Foundation
public class AlgorithmTypesModel: Model<Algorithmtypes> {
    @Published var result: [Algorithmtypes]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Algorithmtypes] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.name ?? "" > $0.name ?? ""})
        }
    }
    internal func setUp() {
        return
        var algorithmModel = AlgorithmsModel()
        var algorithmType: Algorithmtypes?
        var algorithmNames: [String] = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor", "MLLinearClassifier", "MLDecisionTreeClassifier", "MLRandomForestClassifier", "MLBoostedTreeClassifier"]
        for algorithmName in algorithmNames {
            let name = algorithmModel.items.first {$0.name == algorithmName }?.name
            if name == nil {
                var newAlgorithm = algorithmModel.insertRecord()
                newAlgorithm.name = algorithmName
                if algorithmName.contains("Regressor") {
                    algorithmType = getAlgorithmType(name: "Regressor")
                }
                if algorithmName.contains("Classifier") {
                    algorithmType = getAlgorithmType(name: "Classifier")
                }
                newAlgorithm.algorithm2algorithmtype = algorithmType
            }
        }
        BaseServices.save()
    }
    private func getAlgorithmType(name: String) -> Algorithmtypes {
        var algorithmType: Algorithmtypes?
        algorithmType = self.items.filter { $0.name == name }.first
        if algorithmType == nil {
            algorithmType = self.insertRecord()
            algorithmType!.name = name
        }
        return algorithmType!
    }
}
