//
//  File.swift
//  healthKitShaman
//
//  Created by Klaus-Dieter Reiners on 19.11.21.
//

import Foundation
import CoreData
import Combine
class Storage<T>: NSObject, ObservableObject, NSFetchedResultsControllerDelegate where T: NSManagedObject {
    let context: NSManagedObjectContext
    var items = CurrentValueSubject<[T], Never>([])
    lazy var fetchController: NSFetchedResultsController<T> = { [weak self] in
        guard let this = self else {
            fatalError("lazy property has been called after object has been descructed")
            }
        guard let request = T.fetchRequest() as? NSFetchRequest<T> else {
            fatalError("Can't set up NSFetchRequest")
        }
        request.sortDescriptors = []
        let tmp = NSFetchedResultsController<T>(fetchRequest: request, managedObjectContext: PersistenceController.shared.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            return tmp
        }()
    override init() {
        context = PersistenceController.shared.container.viewContext
        super.init()
        fetchController.delegate = self
        do {
            try fetchController.performFetch()
            items.value = (fetchController.fetchedObjects ?? []) as [T]
        } catch {
            NSLog("Error could not fetch log objects")
        }
    }
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            let items = controller.fetchedObjects as! [T]
            self.items.value = items
        BaseServices.logger.log("Context has changed, reloading \(T.self) ")

    }
}
