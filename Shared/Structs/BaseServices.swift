//
//  BaseServices.swift
//  healthKitShaman
//
//  Created by Klaus-Dieter Reiners on 19.11.21.
//

import Foundation
import OSLog
import CoreData
public struct BaseServices
{
    internal enum columnDataTypes: Int16, CaseIterable {
        case Int = 0
        case Double = 1
        case String = 2
    }
    /// Properties
    public static var homePath: URL {
        get {
            return FileManager.default.homeDirectoryForCurrentUser
        }
    }
    /// let constructors
    
    public static let logger = {
        return Logger()
    }()
    public static let standardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    public static var intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    public static let doubleFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    /// functions
    public static func getAttributesForEntity(entity: NSEntityDescription) -> Array<EntityAttributeInfo> {
        var result = Array<EntityAttributeInfo>()
        let attributes = entity.attributesByName
        attributes.forEach { attribute in
            let newInfo = EntityAttributeInfo.init(key: attribute.key, value: attribute.value.attributeValueClassName!)
            result.append(newInfo)
        }
        return result
        
    }
    public static func returnAttributeCluster(readOnlyFields: [String], attributes: inout [EntityAttributeInfo], readOnlyAttributes: inout [EntityAttributeInfo], readWriteAttributes: inout [EntityAttributeInfo] ) -> Void {
        for i in 0..<attributes.count {
            
            for readOnly in readOnlyFields {
                if attributes[i].key == readOnly {
                    attributes[i].readOnly = true
                }
            }
        }
        readOnlyAttributes = attributes.filter { $0.readOnly == true}.sorted {
            return $0.key < $1.key
        }
        readWriteAttributes = attributes.filter { $0.readOnly == false}.sorted {
            return $0.key < $1.key
        }
    }
    public static func convertToStandardDate(dateString: String) -> Date! {
        let format = DateFormatter()
        format.timeZone = .current
        format.dateFormat = "dd-MM-yyyy HH:mm"
        return format.date(from: dateString)
    }
    public static func save() -> Void {
        do {
            if PersistenceController.shared.container.viewContext.hasChanges {
                try PersistenceController.shared.container.viewContext.save()
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
