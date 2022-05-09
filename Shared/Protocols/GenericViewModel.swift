//
//  GenericViewModel.swift
//  healthKitShaman
//
//  Created by Klaus-Dieter Reiners on 19.11.21.
//

import Foundation
import CoreData
public protocol GenericViewModel: ObservableObject {
    associatedtype T
    var items: [T] { get set }
    var attributes: Array<EntityAttributeInfo> { get }
    var readOnlyAttributes: Array<EntityAttributeInfo> { get }
    var readWriteAttributes: Array<EntityAttributeInfo> { get }
}



