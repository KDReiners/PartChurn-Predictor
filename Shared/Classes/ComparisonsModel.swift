//
//  ComparisonsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 15.09.23.
//

import Foundation
import SwiftUI
public class ComparisonsModel: Model<Comparisons> {
    @Published var result: [Comparisons]!
    @Published var reportingDetails: [ComparisonEntry] = []
    @Published var reportingSummaries: [ComparisonEntry] = []
    var primaryKeys: Array<String>!
    var allItems: [Comparisons]!
    var model: Models
    var theshold: Double = 1
    public init(model: Models) {
        self.model = model
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Comparisons] {
        get {
            return result.filter( {$0.comparion2model == self.model })
        }
        set
        {
            result = newValue.sorted(by: { $1.comparisondate ?? Date.now > $0.comparisondate ?? Date.now})
        }
    }
    internal func gather() -> Void {
        primaryKeys =  Array(items.compactMap { $0.primarykey })
        allItems = items.filter( {$0.targetpredicted <= 0.7} )
        for i in 0..<primaryKeys.count {
            let entries = allItems.filter( { $0.primarykey == primaryKeys[i]})
            let appearances = Double(entries.count)
            var sumOfTargetPredicted: Double = 0
            var sumOfTargetReported: Double = 0
            if entries.count > 0 {
                for entry in entries {
                    sumOfTargetReported += Double(entry.targetreported)
                    sumOfTargetPredicted += entry.targetpredicted
                    
                    var comparisonEntry: ComparisonEntry = ComparisonEntry(model: self.model, items: entries)
                    comparisonEntry.reportingDate = entry.comparisondate
                    comparisonEntry.timeBaseCount = Int(entry.timebase)
                    comparisonEntry.targetPredicted = entry.targetpredicted
                    comparisonEntry.targetReported = Double(entry.targetreported)
                    comparisonEntry.primaryKeyValue = entry.primarykey!
                    comparisonEntry.comparisons.append(contentsOf: entries)
                    reportingDetails.append(comparisonEntry)
                }
                var reportingSummaryEntry = ComparisonEntry(model: self.model, items: entries)
                reportingSummaryEntry.targetPredicted = sumOfTargetPredicted / appearances
                reportingSummaryEntry.targetReported = sumOfTargetReported / appearances
                reportingSummaryEntry.timeBaseCount = Int(appearances)
                reportingSummaryEntry.primaryKeyValue = entries.first!.primarykey!
                reportingSummaryEntry.reportingDate = entries.first!.comparisondate!
                reportingSummaries.append(reportingSummaryEntry)
            }
        }
    }
    struct ComparisonEntry: Identifiable {
        var model: Models
        var columnDataModel: ColumnsModel
        var id = UUID()
        internal var reportingDate: Date?
        internal var primaryKeyColumnName: String?
        internal var timeBaseColumName: String?
        internal var comparisons: [Comparisons] = []
        internal var timeBaseCount: Int = 0
        internal var targetReported : Double! = 0.0
        internal var targetPredicted: Double! = 0.0
        internal var primaryKeyValue: String = ""
        var primayKeyColumn: TableColumn<ComparisonEntry, Never, TextViewCell, Text> {
            TableColumn("TimeSlice to") { row in
                TextViewCell(textValue: "\(row.primaryKeyColumnName!)")
            }
        }
        var reportingDateStringValue: String {
            return BaseServices.standardDateFormatterWithoutTime.string(from: reportingDate!)
        }
        var timeBaseCountStringValue: String {
            return String(timeBaseCount)
        }
        var targetPredictedStringValue: String {
            return BaseServices.doubleFormatter.string(from: NSNumber(value: targetPredicted))!
        }
        var targetReportedStringValue: String {
            return BaseServices.doubleFormatter.string(from: NSNumber(value: targetReported))!
        }
        var threshold: Double!
        init(model: Models, items: [Comparisons], threshold: Double = 1) {
            self.model = model
            columnDataModel = ColumnsModel(model: model)
            guard let primaryKeyColumnName = columnDataModel.primaryKeyColumn?.name! else {
                return
            }
            self.primaryKeyColumnName = primaryKeyColumnName
            guard let timeBaseColumName = columnDataModel.timeStampColumn?.name! else {
                return
            }
            self.timeBaseColumName  = timeBaseColumName
        }

        
    }
}
