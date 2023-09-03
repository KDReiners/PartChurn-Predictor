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
    public enum PeriodTypes: Int16, CaseIterable {
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
    func incrementHalfYear(_ value: Int, by increment: Int, periodType: PeriodTypes) -> Int {
        var year: Int
        var month: Int
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.timeZone = TimeZone.current
        switch periodType {
        case .year:
            return value
        case .halfYear:
            year = value / 10
            let halfYear = value % 10
            month = halfYear == 1 ? 6 : 12
            
            // Construct the date
            dateComponents.year = year
            dateComponents.month = month        // Add 1 to the month to move to the next month
            dateComponents.day = 1              // Setting day to 0 gives the last day of the previous month
            guard let initialDate = calendar.date(from: dateComponents) else {
                fatalError("Could not convert halfyear \(value) to date")
            }
            guard let newDate = calendar.date(byAdding: .month, value: -6 * increment, to: initialDate) else {
                fatalError("Could not create new targetDate for halfyear \(value) and increment \(increment)")
            }
            let result = periodType.convertToInt(calendarDate: newDate)
            return result
        case .quarter:
            return value
        case .month:
            return value
        }
    }
    func updateValues() -> [String: MLDataValueConvertible] {
        var newValues: [Int] = []
        let periodType: PeriodTypes = .halfYear
        let dateFormat = periodType.dateFormat()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        var dateComponents = DateComponents()
        dateComponents.month = 0
        
        for (key, values) in updatableDictionary {
            if key == timeStampColumnName,
               let valueSequence = values as? [Int] { // Ensure the value is an array of Int
                for value in valueSequence {
                    let newEntry = incrementHalfYear(value, by: lookAhead, periodType: periodType)
                    newValues.append(newEntry)
                }
            }
        }
        updatableDictionary[timeStampColumnName]! = newValues
        getTestValue(desiredCustno: "1004179")
        return updatableDictionary
    }
    func getTestValue(desiredCustno: String) {
        var custnoIndices: [Int] = []
        var client: Client = Client(custNo: desiredCustno)
        
        for (index, value) in (updatableDictionary["S_CUSTNO"].map({ $0}) as? [String])!.enumerated() {
            if value == desiredCustno {
                custnoIndices.append(index)
            }
        }
        for index in custnoIndices {
            var timeSliceContent = TimeSliceContent()
            timeSliceContent.timeSlice =  (updatableDictionary["I_TIMEBASE"].map({ $0}) as? [Int])![index]
            timeSliceContent.Alive = (updatableDictionary["I_ALIVE"].map({ $0}) as? [Int])![index]
            client.results.append(timeSliceContent)
        }
    }
    struct Client {
        var custNo: String
        var results: [TimeSliceContent] = []
    }
    struct TimeSliceContent {
        var timeSlice: Int?
        var Alive: Int?
        init() {
            
        }
    }
    
}
