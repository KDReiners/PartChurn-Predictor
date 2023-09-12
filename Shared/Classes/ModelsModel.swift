//
//  ModelsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML
import TabularData

public class ModelsModel: Model<Models> {
    @Published var result: [Models]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    public static func getFilesForItem(model: Models) -> [Files] {
        let files = FilesModel()
        return files.items.filter( { $0.files2model == model } )
    }
    public static func getColumnsForItem(model: Models) -> [Columns] {
        let columuns = ColumnsModel()
        return columuns.items.filter( { $0.column2model == model} ).sorted(by: { $0.orderno < $1.orderno})
    }
    override public var items: [Models] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.name ?? "" > $0.name ?? ""})
        }
    }
}
class ModelObjects {
    var model: Models
    var compositionObjects =  [CompositionObject]()
    init(model: Models) {
        self.model = model
        guard let compositions = model.model2compositions else {
            return
        }
        for composition in compositions {
            let newCompositionObject = CompositionObject(composition: composition as! Compositions)
            compositionObjects.append(newCompositionObject)
        }
        
    }
    struct CompositionObject: Hashable {
        static func == (lhs: ModelObjects.CompositionObject, rhs: ModelObjects.CompositionObject) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        var id = UUID()
        
        var composition: Compositions
        var algorithmObjects =  [AlgorithmObject]()
        init( composition: Compositions)
        {
            self.composition = composition
            guard let predictions = self.composition.composition2predictions else {
                return
            }
            guard let predictionmetricvalues = predictions.prediction2predictionmetricvalues else {
                return
            }
            
            for predictionMetricValue  in predictionmetricvalues  {
                let algorithm = (predictionMetricValue as! Predictionmetricvalues).predictionmetricvalue2algorithm!
                var newAlgorithmObject = algorithmObjects.filter { $0.algorithm == algorithm }.first
                if newAlgorithmObject == nil {
                    newAlgorithmObject = AlgorithmObject(algorithm: algorithm)
                    algorithmObjects.append(newAlgorithmObject!)
                }
                newAlgorithmObject?.metricValues.append(predictionMetricValue as! Predictionmetricvalues)
            }
        }
        internal struct CompositionView: View {
            var rootObject: CompositionObject
            @State var item: AlgorithmObject!
            init(rootObject: CompositionObject) {
                self.rootObject = rootObject
            }
            var body: some View {
                ForEach(rootObject.algorithmObjects, id: \.self) { a in
                    NavigationLink(a.algorithmName, destination: Text(a.algorithmName), tag: a, selection: $item)
                }
            }
        }
    }
    struct AlgorithmObject: Hashable {
        static func == (lhs: ModelObjects.AlgorithmObject, rhs: ModelObjects.AlgorithmObject) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        var id = UUID()
        var algorithm: Algorithms
        var algorithmName: String {
            get {
                return algorithm.name!
            }
        }
        var metricValues = [Predictionmetricvalues]()
        init(algorithm: Algorithms) {
            self.algorithm = algorithm
            self.metricValues = algorithm.algorithm2predictionmetricvalues?.allObjects as! [Predictionmetricvalues]
        }
    }
}
