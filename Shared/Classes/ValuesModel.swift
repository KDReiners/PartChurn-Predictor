//
//  ValuesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import CoreData
import SwiftUI
public class ValuesModel: Model<Values> {
    @Published var result: [Values]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Values] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    internal func updateDummyRelations() async -> Void  {
        
        for item in self.items.filter( {return $0.value2model == nil }) {
            let modelObjectID = PersistenceController.shared.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL.init(string: item.idmodel!)!)
            let model = PersistenceController.shared.container.viewContext.object(with: modelObjectID!)
            item.value2model = model as? Models
        }
    }
}

      
