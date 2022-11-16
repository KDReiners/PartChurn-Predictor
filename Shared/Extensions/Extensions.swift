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
extension Binding where Value == String? {
    var stringBinding: Binding<String> {
        Binding<String>(get: {
            self.wrappedValue ?? ""
        }, set: { value in
            self.wrappedValue = value
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
extension Int {
    static func parse(from string: String) -> Int? {
        return Int(string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
    }
}
extension Double {
    static func parse(from string: String) -> Double? {
        let allowedCharset = CharacterSet
            .decimalDigits
            .union(CharacterSet(charactersIn: "+.-"))
        return Double(string.components(separatedBy: allowedCharset.inverted).joined())
    }
}
extension Optional {
    init?(from any: Any) {
        guard let opt = any as Any? as? Self else {
            return nil
        }
        self = opt
    }
}
extension String {
    var preparedToDecimalNumberConversion: String {
        split {
            !CharacterSet(charactersIn: "\($0)").isSubset(of: CharacterSet.decimalDigits)
        }.joined(separator: ".")
    }
}
