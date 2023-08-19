//
//  TimeBaseInteractor.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 17.08.23.
//

import Foundation
import CreateML
class TimeLord: Identifiable {
    /// Enums
    internal enum PeriodTypes: Int16, CaseIterable {
        case year = 0
        case halfYear = 1
        case quarter = 2
        case month = 3
        static func fromRawValue(_ rawValue: Int16) -> PeriodTypes? {
            return PeriodTypes(rawValue: rawValue)
        }
        func dateFormat() -> String {
            switch self {
            case .year:
                return "YYYY"
            case .halfYear:
                return "YYYYM"
            case .quarter:
                return "YYYYM"
            case .month:
                return "YYYYMM"
            }
        }
        func convertToInt(calendarDate: Date) -> Int {
            let components = Calendar.current.dateComponents(
                [.year, .month, .quarter ],
              from: calendarDate
            )
            
            switch self {
            case .year:
                return components.year!
            case .halfYear:
                return components.month! <= 6 ? components.year! * 10 + 1 : components.year! * 10 + 2
            case .quarter:
                return components.quarter!
            case .month:
                return components.year! * 100 * components.month!
            }
        }
    }
    /// Properties
    var columnsDataModel = ColumnsModel()
    var updatableDictionary: [String: any MLDataValueConvertible]
    var timeStampColumnName: String
    var lookAhead: Int
    init(mlTableDictionary: [String: any MLDataValueConvertible], model: Models, lookAhead: Int) {
        columnsDataModel.model = model
        self.updatableDictionary = mlTableDictionary
        self.lookAhead = lookAhead
        self.timeStampColumnName = (columnsDataModel.timeStampColumn?.name)!
    }
    
    func updateValues() -> [String: MLDataValueConvertible] {
        var newValues: [Int] = []
        let periodType: PeriodTypes = .halfYear
        let dateFormat = periodType.dateFormat()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = 0
        
        for (key, values) in updatableDictionary {
            if key == timeStampColumnName,
               let valueSequence = values as? [Int] { // Ensure the value is an array of Int
                for value in valueSequence {
                    guard let currentDate = dateFormatter.date(from: String(value)) else {
                        fatalError("Failed to parse the date")
                    }
                    guard let newDate = calendar.date(byAdding: dateComponents, to: currentDate) else {
                        fatalError("Failed to calculate new date")
                    }
                    let newEntry = periodType.convertToInt(calendarDate: newDate)
                    newValues.append(newEntry)
                }
            }
        }
        updatableDictionary[timeStampColumnName]! = newValues
        return updatableDictionary
    }


//    func convertTimeSlices(lookAhead: Int)    -> Int {
//        var result = Array<Int>()
//        let dateFormatter = DateFormatter()
//        var dateComponents = DateComponents()
//        let dateFormat = PeriodTypes.fromRawValue(self.periodType)?.dateFormat()
//        dateFormatter.dateFormat = dateFormat
//        let calendar = Calendar.current
//        for index in 0..<values.count {
//            var value = values[index].dataValue.intValue
//            let currentDate = dateFormatter.date(from: String(value!))
//            dateComponents.month = -lookAhead * 6
//            let newDate = calendar.date(byAdding: dateComponents, to: currentDate!)!
//            let newValue = Int(dateFormatter.string(from: newDate))
//            result.append(newValue!)
//        }
//        return result
//    }
}
