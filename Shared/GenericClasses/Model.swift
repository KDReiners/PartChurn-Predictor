//
//  Model.swift
//  healthKitShaman
//
//  Created by Klaus-Dieter Reiners on 19.11.21.
//
import CoreData
import Combine
public class Model<T>: GenericViewModel where T: NSManagedObject {
    public var items: [T] = []
    let context = PersistenceController.shared.container.viewContext
    public var attributes: Array<EntityAttributeInfo> = BaseServices.getAttributesForEntity(entity: T.self.entity())
    public var readOnlyAttributes: Array<EntityAttributeInfo> = []
    public var readWriteAttributes: Array<EntityAttributeInfo> = []
    private var readOnlyFields: [String] = []
    private var deviceCancellable: AnyCancellable?
    private var attachedStorage = Storage<T>()
    init(readOnlyFields: [String]){
        self.readOnlyFields = readOnlyFields
        BaseServices.returnAttributeCluster(readOnlyFields: readOnlyFields, attributes: &attributes, readOnlyAttributes: &readOnlyAttributes, readWriteAttributes: &readWriteAttributes)
        attachValues()
    }
    internal func detachValues() -> Void {
        deviceCancellable = nil
    }
    private func attachValues (devicePublisher: AnyPublisher<[T], Never> = Storage<T>().items.eraseToAnyPublisher()) {
        deviceCancellable = devicePublisher.sink {[weak self] items in
            self?.items = items
        }
        BaseServices.returnAttributeCluster(readOnlyFields: readOnlyFields, attributes: &attributes, readOnlyAttributes: &readOnlyAttributes, readWriteAttributes: &readWriteAttributes)
    }
    public func deleteAllRecords(predicate: NSPredicate?) -> Void {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.self.entity().name!)
        fetchRequest.predicate = predicate
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            let result = try PersistenceController.shared.container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result?.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [PersistenceController.shared.container.viewContext])
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    public func insertRecord() -> T {
        let result = NSEntityDescription.insertNewObject(forEntityName: T.entity().name!, into: context) as! T
        items.append(result)
        try? context.save()
        return result
    }
    public func recordExists(predicate:  NSPredicate) -> Bool {
        var result = false
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.self.entity().name!)
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .managedObjectIDResultType
        do {
            result = try PersistenceController.shared.container.viewContext.fetch(fetchRequest).count > 0
            
        } catch {
            fatalError(error.localizedDescription)
        }
        return result
    }
    public func deleteRecord(record: T) -> Void {
        context.delete(record)
    }
    public func saveChanges() -> Void {
        try? context.save()
    }
}

