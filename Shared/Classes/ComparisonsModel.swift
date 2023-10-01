//
//  ComparisonsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 15.09.23.
//

import Foundation
import SwiftUI
public class ComparisonsModel: Model<Comparisons> {
    @Published var reportingSummaries: [ComparisonSummaryEntry] = []
    var reportingDetails:  [[ComparisonDetailEntry]]!
    var votings: [Voting] = []
    var result: [Comparisons]!
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
                }}
        reportingSummaries = dictOfPrimaryKeys.map( { ComparisonsModel.ComparisonSummaryEntry(model: self.model, primaryKeyValue: $0.key, items: $0.value)})
        reportingDetails = reportingSummaries.map( { $0.comparisonsDetails })
        votings = Winners(reportingDetails: reportingDetails).votings
    }
    struct Voting: Identifiable, Hashable  {
        // Protocol stubs
        internal var id = UUID()
        static func == (lhs: ComparisonsModel.Voting, rhs: ComparisonsModel.Voting) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        var primaryKey: String!
        var observation: Observations!
        var lookAhead: String!
        var algorithm: String!
        var timeSlices: String!
        var entriesCount: String!
        var contribution: String!
        var uniqueContributions: String!
        var mixedContributions: String!
        init() {
            
        }
    }
    struct Winners {
        var votings: [Voting] = []
        var result: [[ComparisonDetailEntry]]
        init(reportingDetails: [[ComparisonDetailEntry]]) {
            self.result = reportingDetails
            var distinctDictOfObservations = Set<String>()
            
            for outer in result {
                for inner in outer {
                    let candidate = inner.observation
                    let innerPrimaryKey = inner.primarykey
                        let key = inner.observation.objectID.uriRepresentation().lastPathComponent
                        distinctDictOfObservations.insert(key)
                        let observationStatistic = ObservationStatistics(observation: inner.observation, comparisonDetailEntries: result)
                        var voting = Voting()
                        voting.contribution = String(observationStatistic.contributions.ownDistinctPrimaryKeys.count)
                        let ownContributions = observationStatistic.contributions.ownDistinctPrimaryKeys
                        let foreignContributions = observationStatistic.contributions.foreignDistinctPrimaryKeys
                        voting.uniqueContributions = String(Array(ownContributions.subtracting(foreignContributions)).count)
                        voting.mixedContributions = String(Array(ownContributions.intersection(foreignContributions)).count)
                        voting.primaryKey = key
                        voting.observation = inner.observation
                        voting.lookAhead = String(Int(exactly: inner.observation.observation2lookahead!.lookahead)!)
                        voting.algorithm = (inner.observation.observation2algorithm?.name)!
                        voting.timeSlices = String(Int((inner.observation.observation2prediction?.seriesdepth)!))
                        let comparisons = inner.observation.observation2comparisons!.allObjects as! [Comparisons]
                        voting.entriesCount = String(countPrimaryKeys(comparions: comparisons))
                        if votings.first(where: { $0.primaryKey == voting.primaryKey }) == nil {
                            votings.append(voting)
                        }
                }
            }
        }
        internal func countPrimaryKeys(comparions: [Comparisons]) -> Int {
            var distinctPrimaryKeys = Set<String>()
            for comparison in comparions {
                distinctPrimaryKeys.insert(comparison.primarykey!)
            }
            return distinctPrimaryKeys.count
        }
        struct ObservationStatistics {
            var observation: Observations
            var comparisonDetailEntries: [[ComparisonDetailEntry]]
            var contributions: Contributions {
                get {
                    return Contributions(comparisonDetailEntries: comparisonDetailEntries, observation: observation)
                }
            }
            init(observation: Observations, comparisonDetailEntries: [[ComparisonDetailEntry]]) {
                self.observation = observation
                self.comparisonDetailEntries = comparisonDetailEntries
            }
            struct Contributions {
                var ownDistinctPrimaryKeys = Set<String>()
                var foreignDistinctPrimaryKeys = Set<String>()
                init(comparisonDetailEntries: [[ComparisonDetailEntry]], observation: Observations) {
                    for outer in comparisonDetailEntries {
                        for entry in outer {
                            if entry.observation == observation {
                                ownDistinctPrimaryKeys.insert(entry.primarykey)
                            } else {
                                foreignDistinctPrimaryKeys.insert(entry.primarykey)
                            }
                        }
                    }
                }
            }
        }
        
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
        internal var lookahead: String
        internal var observationId: String
        internal var timeslices: String
        
        init(id: UUID = UUID(), comparison: Comparisons) {
            self.id = id
            self.primarykey = comparison.primarykey!
            self.comparison = comparison
            self.timebase = String(comparison.timebase)
            self.targetpredicted = BaseServices.doubleFormatter.string(from: NSNumber(value: comparison.targetpredicted))!
            self.targetreported = BaseServices.doubleFormatter.string(from: NSNumber(value: comparison.targetreported))!
            let cluster = PredictionsModel(model: comparison.comparion2model!).createPredictionCluster(item: (comparison.comparison2observation?.observation2prediction)!)
            self.algorithm = (comparison.comparison2observation?.observation2algorithm?.name)!
            self.lookahead = String((comparison.comparison2observation?.observation2lookahead?.lookahead)!)
            guard let observation = comparison.comparison2observation else {
                fatalError()
            }
            self.observation = observation
            self.observationId = observation.objectID.uriRepresentation().lastPathComponent
            self.timeslices = String(cluster.seriesDepth)
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
        internal var comparisonsDetails: [ComparisonDetailEntry] {
            get {
                return getComparisonDetails()
            }
        }
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
            //            comparisonsDetails = items.map({ComparisonDetailEntry(comparison: $0) })
            guard let primaryKeyValue = primaryKeyValue else {
                fatalError()
            }
            self.primaryKeyValue = primaryKeyValue
            self.subEntriesCount = items.count
            self.timeBaseCount = Set(items.map { $0.comparison2observation }).count
            self.targetsPredicted = items.reduce(0) { $0 + $1.targetpredicted } / Double(items.count)
            self.targetsReported = Double(items.reduce(0) { $0 + $1.targetreported }) / Double(items.count)
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
        private func getComparisonDetails()  -> [ComparisonDetailEntry] {
            var result: [ComparisonDetailEntry] = []
            let detailComparator: (ComparisonDetailEntry, ComparisonDetailEntry) -> Bool = { (a, b) in
                if a.observation.objectID.uriRepresentation().lastPathComponent !=  b.observation.objectID.uriRepresentation().lastPathComponent {
                    return a.observation.objectID.uriRepresentation().lastPathComponent < b.observation.objectID.uriRepresentation().lastPathComponent
                }
                if a.lookahead != b.lookahead {
                    return a.lookahead < b.lookahead
                }
                if a.timebase != b.timebase {
                    return a.timebase < b.timebase
                }
                return a.observation.objectID.uriRepresentation().lastPathComponent < b.observation.objectID.uriRepresentation().lastPathComponent
            }
            let items = ComparisonsModel(model: self.model).items.filter { $0.primarykey == primaryKeyValue}
            result = items.map({ComparisonDetailEntry(comparison: $0) })
            return result.sorted(by: detailComparator)
            
        }
        
    }
}
