//
//  PackedValue.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 01.06.23.
//

import Foundation
import CreateML
struct PackedValue: MLDataValueConvertible, Hashable {
    let id: UUID
    func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }
     
     static func ==(lhs: PackedValue, rhs: PackedValue) -> Bool {
         return lhs.id == rhs.id
     }
    init() {
        id = UUID()
        value = 0 // Set the default value for the `value` property
        dataValue = MLDataValue.int(0)
        convertedToStringValue = ""
    }
    var dataValue: MLDataValue
    static var dataValueType: MLDataValue.ValueType {
        return .int
    }
    
    let value: Any
    var convertedToStringValue: String
    
    init?(from dataValue: MLDataValue) {
        id = UUID()
        self.convertedToStringValue = ""
        if let intValue = dataValue.intValue {
            self.value = intValue
            self.convertedToStringValue = String(intValue)
           } else if let doubleValue = dataValue.doubleValue {
               self.value = doubleValue
               self.convertedToStringValue = String(doubleValue)
           } else if let stringValue = dataValue.stringValue {
               self.value = stringValue
           } else {
               // Conversion failed, return nil
               return nil
           }
           
           // If the conversion was successful, initialize the dataValue property
           self.dataValue = dataValue
    }
    
    var mlDataValue: MLDataValue {
        if let intValue = value as? Int {
            return MLDataValue.int(intValue)
        } else if let doubleValue = value as? Double {
            return MLDataValue.double(doubleValue)
        } else if let stringValue = value as? String {
            return MLDataValue.string(stringValue)
        } else {
            return MLDataValue.int(0) // Default value if none of the conditions match
        }
    }
}
