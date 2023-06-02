//
//  PackedValue.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 01.06.23.
//

import Foundation
import CreateML
struct PackedValue: MLDataValueConvertible {
    init() {
        value = 0 // Set the default value for the `value` property
        dataValue = MLDataValue.int(0)
    }
    
    var dataValue: MLDataValue
    
    static var dataValueType: MLDataValue.ValueType {
        return .int
    }
    
    let value: Any
    
    init?(from dataValue: MLDataValue) {
        if let intValue = dataValue.intValue {
               self.value = intValue
           } else if let doubleValue = dataValue.doubleValue {
               self.value = doubleValue
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
