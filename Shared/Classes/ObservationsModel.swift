//
//  ObservationsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 05.09.23.
//

import Foundation
public class ObservationsModel: Model<Observations> {
    @Published var result: [Observations]!
    var environment: Environment!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Observations] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    struct ObservationKey: Hashable {
        let timeslicefrom: Timeslices
        let timesliceto: Timeslices
    }
    // Helper
    struct Environment {
        var model: Models
        var columnsDataModel: ColumnsModel

        init(model: Models) {
            self.model = model
            columnsDataModel = ColumnsModel(model: model)
        }
        internal var primaryKeyColumnName: String {
            get {
                guard let primaryKeyColumnName = columnsDataModel.primaryKeyColumn?.name! else {
                    fatalError("\(#function) no primaryKeyColumn found.")
                }
                return  primaryKeyColumnName
            }
        }
        internal var timeBaseColumnName: String {
            get {
                guard let timeBaseColumnName = columnsDataModel.timeStampColumn?.name! else {
                    fatalError("\(#function) no timeBaseColumn not found.")
                }
                return timeBaseColumnName
            }
        }
        internal var observationsDictionary: [ ObservationKey: [Observations] ] {
            guard let modelObservations = model.model2observations?.allObjects as? [Observations] else {
                fatalError("\(#function) no observations found for model.")
            }
            let observationsDictionary = Dictionary(grouping: modelObservations ) { (observation) in
                return ObservationKey(timeslicefrom: observation.observation2timeslicefrom!,  timesliceto: observation.observation2timesliceto!)
            }
            return observationsDictionary
        }
    }
    
   
}
