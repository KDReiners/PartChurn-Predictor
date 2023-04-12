//
//  Persistence.swift
//  Shared
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import CoreData
import OSLog
import SwiftUI

class PersistenceController {
    private let inMemory: Bool
    private var notificationToken: NSObjectProtocol?
    private var didSaveNotificationToken: NSObjectProtocol?
    let logger = Logger(subsystem: "peas.com.PartChurn-Predictor", category: "persistence")
    /// A peristent history token used for fetching transactions from the store.
    static let  shared = PersistenceController()
    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "PartChurn_Predictor")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
//        container.viewContext.reset()
        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()
    
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        //        container = NSPersistentContainer(name: "PartChurn_Predictor")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
    }
    // Creates and configures a private queue context.
    internal func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    internal func fixLooseRelations(){
        do {
            let fetchRequest: NSFetchRequest<Values> = Values.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "idcolumn != nil")
            let fetchedResults =  try self.container.viewContext.fetch(fetchRequest)
            var i = 1
            print("Number of records: " + String(fetchedResults.count))
            for result in fetchedResults  as [Values] {
                print("working on: " + String(i))
                let idModel: NSManagedObjectID = getManagedObjectID(stringValue: result.idmodel!)
                let idFile: NSManagedObjectID = getManagedObjectID(stringValue: result.idfile!)
                let idColumn: NSManagedObjectID = getManagedObjectID(stringValue: result.idcolumn!)
                guard let model = self.container.viewContext.object(with: idModel) as? Models   else { return }
                guard let file = self.container.viewContext.object(with: idFile) as? Files   else { return }
                guard let column = self.container.viewContext.object(with: idColumn) as? Columns   else { return }
                result.value2model = model
                result.idmodel = nil
                result.value2file = file
                result.idfile = nil
                result.value2column = column
                result.idcolumn = nil
                i += 1
            }
            do {
                try BaseServices.save()
            } catch {
                fatalError("error while saving viewContext")
            }
        } catch {
            fatalError(error.localizedDescription)
        }
       
    }
    private func getManagedObjectID(stringValue: String) -> NSManagedObjectID
    {
        return (PersistenceController.shared.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: URL.init(string: stringValue)!))!
    }
}
