//
//  BatchImporter.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 14.06.22.
//

import Foundation
import CoreData
import OSLog
enum BatchError: Error {
    case wrongDataFormat(error: Error)
    case missingData
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
}

extension BatchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .missingData:
            return NSLocalizedString("Found and will discard a quake missing a valid code, magnitude, place, or time.", comment: "")
        case .creationError:
            return NSLocalizedString("Failed to create a new Quake object.", comment: "")
        case .batchInsertError:
            return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
        case .batchDeleteError:
            return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
        case .persistentHistoryChangeError:
            return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}

extension BatchError: Identifiable {
    var id: String? {
        errorDescription
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to fetch data from the remote server and save it to the Core Data store.
*/

internal class BatchProvider {

//    // MARK: USGS Data
//
//    // MARK: Logging
//
//    let logger = Logger(subsystem: "peas.com.PartChurn-Predictor", category: "persistence")
//
//    // MARK: Core Data
//
//    private let inMemory: Bool
//    private var notificationToken: NSObjectProtocol?
//
//    internal init(inMemory: Bool = false) {
//        self.inMemory = inMemory
//
//        // Observe Core Data remote change notifications on the queue where the changes were made.
//        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { note in
//            self.logger.debug("Received a persistent store remote change notification.")
//            Task {
//                await self.fetchPersistentHistory()
//            }
//        }
//    }
//
//    deinit {
//        if let observer = notificationToken {
//            NotificationCenter.default.removeObserver(observer)
//        }
//    }
//
//    /// A peristent history token used for fetching transactions from the store.
//    private var lastToken: NSPersistentHistoryToken?
//
//    /// A persistent container to set up the Core Data stack.
//    lazy var container: NSPersistentContainer = {
//        /// - Tag: persistentContainer
//        let container = NSPersistentContainer(name: "PartChurn_Predictor")
//
//        guard let description = container.persistentStoreDescriptions.first else {
//            fatalError("Failed to retrieve a persistent store description.")
//        }
//
//        if inMemory {
//            description.url = URL(fileURLWithPath: "/dev/null")
//        }
//
//        // Enable persistent store remote change notifications
//        /// - Tag: persistentStoreRemoteChange
//        description.setOption(true as NSNumber,
//                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
//
//        // Enable persistent history tracking
//        /// - Tag: persistentHistoryTracking
//        description.setOption(true as NSNumber,
//                              forKey: NSPersistentHistoryTrackingKey)
//        container.loadPersistentStores { storeDescription, error in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        }
//
//        // This sample refreshes UI by consuming store changes via persistent history tracking.
//        /// - Tag: viewContextMergeParentChanges
//        container.viewContext.automaticallyMergesChangesFromParent = false
//        container.viewContext.name = "viewContext"
//        /// - Tag: viewContextMergePolicy
//        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        container.viewContext.undoManager = nil
//        container.viewContext.shouldDeleteInaccessibleFaults = true
//        return container
//    }()
//
//    /// Creates and configures a private queue context.
//    private func newTaskContext() -> NSManagedObjectContext {
//        // Create a private queue context.
//        /// - Tag: newBackgroundContext
//        let taskContext = container.newBackgroundContext()
//        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
//        // to reduce resource requirements.
//        taskContext.undoManager = nil
//        return taskContext
//    }


    /// Uses `NSBatchInsertRequest` (BIR) to import a JSON dictionary into the Core Data store on a private queue.
    internal func importValues(from propertiesList: [coreDataProperties]) async throws {
        guard !propertiesList.isEmpty else { return }

        let taskContext = PersistenceController.shared.container.newBackgroundContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "ImportValues"

        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = self.newBatchInsertRequest(with: propertiesList)
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            BaseServices.logger.debug("Failed to execute batch insert request.")
            throw BatchError.batchInsertError
        }

        BaseServices.logger.debug("Successfully inserted data.")
    }

    private func newBatchInsertRequest(with propertyList: [coreDataProperties]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: Values.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }

    /// Synchronously deletes given records in the Core Data store with the specified object IDs.
    func deleteQuakes(identifiedBy objectIDs: [NSManagedObjectID]) {
        let viewContext = PersistenceController.shared.container.viewContext
        BaseServices.logger.debug("Start deleting data from the store...")

        viewContext.perform {
            objectIDs.forEach { objectID in
                let quake = viewContext.object(with: objectID)
                viewContext.delete(quake)
            }
        }

        BaseServices.logger.debug("Successfully deleted data.")
    }

    /// Asynchronously deletes records in the Core Data store with the specified `Quake` managed objects.
    func deleteQuakes(_ quakes: [Values]) async throws {
        let objectIDs = quakes.map { $0.objectID }
        let taskContext = PersistenceController.shared.newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "deleteContext"
        taskContext.transactionAuthor = "deleteQuakes"
        BaseServices.logger.debug("Start deleting data from the store...")

        try await taskContext.perform {
            // Execute the batch delete.
            let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            guard let fetchResult = try? taskContext.execute(batchDeleteRequest),
                  let batchDeleteResult = fetchResult as? NSBatchDeleteResult,
                  let success = batchDeleteResult.result as? Bool, success
            else {
                BaseServices.logger.debug("Failed to execute batch delete request.")
                throw BatchError.batchDeleteError
            }
        }

        BaseServices.logger.debug("Successfully deleted data.")
    }
}

internal struct coreDataProperties {
    var predictedvalue: String
    var rowno: Int64
    var value: String
    var idmodel: String
    var idfile: String
    var idcolumn: String
    var dictionaryValue: [String: Any] {
        [
            "predictedvalue": predictedvalue,
            "rowno": rowno,
            "value": value,
            "idmodel": idmodel,
            "idfile": idfile,
            "idcolumn": idcolumn
        ]
    }
}
