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
    @Published var reportingDetails: [ComparisonSummaryEntry] = []
    @Published var reportingSummaries: [ComparisonSummaryEntry] = []
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
    internal func resume() -> Void {
        attachValues()
        gather()
    }
    internal func gather() -> Void {
        var dictOfPrimaryKeys: [String: [Comparisons]] = [:]
        for entity in self.items.filter({ $0.comparion2model == model }) {
            if let primaryKeyValue = entity.primarykey {
                if dictOfPrimaryKeys[primaryKeyValue] == nil {
                    dictOfPrimaryKeys[primaryKeyValue] = [entity]
                } else {
                    dictOfPrimaryKeys[primaryKeyValue]?.append(entity)
                }
            }
        }
        reportingSummaries = dictOfPrimaryKeys.map( { ComparisonsModel.ComparisonSummaryEntry(model: self.model, primaryKeyValue: $0.key, items: $0.value)})
    }
    internal struct ComparisonDetailEntry: Identifiable, Hashable {
        // Protocol stubs
        internal var id = UUID()
        static func == (lhs: ComparisonsModel.ComparisonDetailEntry, rhs: ComparisonsModel.ComparisonDetailEntry) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        internal var comparison: Comparisons
        internal var observation: Observations
        internal var primarykey: String
        internal var timebase: String
        internal var targetpredicted: String
        internal var targetreported: String
        internal var algorithm: String
        
        init(id: UUID = UUID(), comparison: Comparisons) {
            self.id = id
            self.primarykey = comparison.primarykey!
            self.comparison = comparison
            self.timebase = String(comparison.timebase)
            self.targetpredicted = BaseServices.doubleFormatter.string(from: NSNumber(value: comparison.targetpredicted))!
            self.targetreported = BaseServices.doubleFormatter.string(from: NSNumber(value: comparison.targetreported))!
            let cluster = PredictionsModel(model: comparison.comparion2model!).createPredictionCluster(item: (comparison.comparison2observation?.observation2prediction)!)
            self.algorithm = (comparison.comparison2observation?.observation2algorithm?.name)!
            guard let observation = comparison.comparison2observation else {
                fatalError()
            }
            self.observation = observation
        }
    }
    internal struct ComparisonSummaryEntry: Identifiable, Hashable {
        static func == (lhs: ComparisonsModel.ComparisonSummaryEntry, rhs: ComparisonsModel.ComparisonSummaryEntry) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        var model: Models
        var subEntriesCount: Int
        var columnDataModel: ColumnsModel
        internal var id = UUID()
        internal var primaryKeyColumnName: String?
        internal var timeBaseColumName: String?
        internal var comparisonsDetails: [ComparisonDetailEntry] = []
        internal var timeBaseCount: Int = 0
        internal var targetsReported : Double! = 0.0
        internal var targetsPredicted: Double! = 0.0
        internal var primaryKeyValue: String = ""
        internal var observation: Observations?
        internal var reportingDateStringValue = ""
        var primayKeyColumn: TableColumn<ComparisonSummaryEntry, Never, TextViewCell, Text> {
            TableColumn("TimeSlice to") { row in
                TextViewCell(textValue: "\(row.primaryKeyColumnName!)")
            }
        }
        var timeBaseCountStringValue: String {
            return String(timeBaseCount)
        }
        var targetPredictedStringValue: String {
            return BaseServices.doubleFormatter.string(from: NSNumber(value: targetsPredicted))!
        }
        var targetReportedStringValue: String {
            return BaseServices.doubleFormatter.string(from: NSNumber(value: targetsReported))!
        }
        var lookAheadStringValue: String {
            return String((observation?.observation2lookahead!.lookahead)!)
        }
        var timeSlicesStringValue: String {
            return String((observation?.observation2prediction?.seriesdepth)!)
        }
        var threshold: Double!
        init(model: Models, primaryKeyValue: String? = nil,  items: [Comparisons], threshold: Double = 1) {
            // Direct Values
            self.model = model
            comparisonsDetails = items.map({ComparisonDetailEntry(comparison: $0) })
            guard let primaryKeyValue = primaryKeyValue else {
                fatalError()
            }
            self.primaryKeyValue = primaryKeyValue
            self.subEntriesCount = items.count
            self.timeBaseCount = Set(items.map { $0.timebase }).count / items.count
            self.targetsPredicted = items.reduce(0) { $0 + $1.targetpredicted } / Double(timeBaseCount)
            self.targetsReported = Double(items.reduce(0) { $0 + $1.targetreported }) / Double(timeBaseCount)
            reportingDateStringValue = BaseServices.standardDateFormatterWithoutTime.string(from: Date.now)
            // Helper
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
