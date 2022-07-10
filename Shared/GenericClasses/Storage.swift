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
            fatalError("lazy property has been called after object has been destructed")
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
//        NotificationCenter.default.addObserver(self, selector: #selector(contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(contextWillSave(_:)), name: Notification.Name.NSManagedObjectContextWillSave, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: nil)
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
//    @objc func contextObjectsDidChange(_ notification: Notification) {
//        print(notification)
//    }
//
//    @objc func contextWillSave(_ notification: Notification) {
//        print(notification)
//    }
//
//    @objc func contextDidSave(_ notification: Notification) {
//        print(notification)
//    }
    
}
