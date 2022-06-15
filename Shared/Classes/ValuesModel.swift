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
            updateDummyRelations()
        }
    }
    internal func updateDummyRelations() -> Void  {
        
        for item in self.items.filter( {return $0.value2model == nil || $0.value2file == nil || $0.value2column == nil }) {
            let modelObjectID = PersistenceController.shared.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL.init(string: item.idmodel!)!)
            let fileObjectID = PersistenceController.shared.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL.init(string: item.idfile!)!)
            let columnObjectID = PersistenceController.shared.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL.init(string: item.idcolumn!)!)
            guard let model = PersistenceController.shared.container.viewContext.object(with: modelObjectID!) as? Models else { return }
            guard let file = PersistenceController.shared.container.viewContext.object(with: fileObjectID!) as? Files   else { return }
            guard let column = PersistenceController.shared.container.viewContext.object(with: columnObjectID!) as? Columns   else { return }
            item.value2model = model
            item.idmodel = nil
            item.value2file = file
            item.idfile = nil
            item.value2column = column
            item.idcolumn = nil
            
        }
        saveChanges()
    }
}

      
