//
//  Extensions.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import SwiftUI
extension Binding {
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
extension Binding where Value == NSNumber? {
    var boolBinding: Binding<Bool> {
        Binding<Bool>(get: {
            self.wrappedValue == true
        }, set: { value in
            self.wrappedValue = NSNumber(value: value)
        })
    }
}
//open class ManagedObject: NSManagedObject {
//    override public func willChangeValue(forKey key: String) {
//        super.willChangeValue(forKey: key)
//
//        objectWillChange.send()
//    }
//}
extension Sequence {
  func sorted(
    by firstPredicate: (Element, Element) -> Bool,
    _ secondPredicate: (Element, Element) -> Bool,
    _ otherPredicates: ((Element, Element) -> Bool)...
  ) -> [Element] {
    return sorted(by:) { lhs, rhs in
      if firstPredicate(lhs, rhs) { return true }
      if firstPredicate(rhs, lhs) { return false }
      if secondPredicate(lhs, rhs) { return true }
      if secondPredicate(rhs, lhs) { return false }
      for predicate in otherPredicates {
        if predicate(lhs, rhs) { return true }
        if predicate(rhs, lhs) { return false }
      }
      return false
    }
  }
}
extension NSObject {
    func propertyNames() -> [String] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap{ $0.label }
    }
}
