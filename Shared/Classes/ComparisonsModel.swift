//
//  ComparisonsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 15.09.23.
//

import Foundation
import SwiftUI
import CreateML
public class ComparisonsModel: Model<Comparisons> {
    @Published var reportingSummaries: [ComparisonSummaryEntry] = []
    @Published var historyCalculated = false
    var reportingDetails:  [[ComparisonDetailEntry]]!
    var churnStatistics: [ChurnStatistics] = []
    var votings: [Voting] = []
    var voters: String!
    var result: [Comparisons]!
    var primaryKeys: Array<String>!
    var allItems: [Comparisons]!
    var model: Models
    var theshold: Double = 1
    var historicalData: HistoricalData
    public init(model: Models) {
        self.model = model
        let readOnlyFields: [String] = []
        historicalData = HistoricalData(model: model)
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
    internal func retrieveHistory() {
        Task {
            await historicalData.fillHistory(model: model) { result in
                self.churnStatistics = result.churnCountByYear.map({ (year, churnCounts) in
                    ChurnStatistics(i_TimeBase: year, targetCount: churnCounts.churned, nonTargetCount: churnCounts.notChurned)
                }).sorted { $0.timeBase < $1.timeBase}
                DispatchQueue.main.sync {
                    self.historyCalculated = true
                }
              
            }
        }
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
        guard let observations = (self.model.model2observations?.allObjects as? [Observations])?.filter({ $0.observation2timeslicefrom!.value >= model.model2observationtimeslicefrom!.value && $0.observation2timesliceto!.value >= model.model2observationtimesliceto!.value}) else {
            return
        }
        votings = Winners(reportingDetails: reportingDetails).votings
        voters = String((observations.count))
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
        var foundTargets: String!
        var proposedTargets: String!
        var precision: String!
        var recall: String!
        var f1Score: String!
        init() {
            
        }
    }
    struct ChurnDataResults {
        let churnHistory: [Int: [Int]]
        let churnCountByYear: [Int: (churned: Int, notChurned: Int)]
    }
    class ChurnStatistics: Identifiable, Hashable {
        internal var id = UUID()
        static func == (lhs: ComparisonsModel.ChurnStatistics, rhs: ComparisonsModel.ChurnStatistics) -> Bool {
            lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        var timeBase: Int
        var targetCount: Int
        var nonTargetCount: Int
        var lblTimebase: String {
            get {
                return String(timeBase)
            }
        }
        var lblTargetCount: String {
            get {
                return String(targetCount)
            }
        }
        var lblNonTargetCount: String {
            get {
                return String(nonTargetCount)
            }
        }
        init(i_TimeBase: Int, targetCount: Int, nonTargetCount: Int) {
            self.timeBase = i_TimeBase
            self.targetCount = targetCount
            self.nonTargetCount = nonTargetCount
        }
    }
    struct Winners {
        typealias bs = BaseServices
        var votings: [Voting] = []
        var result: [[ComparisonDetailEntry]]
        var comparisons: [Comparisons]!
        
        init(reportingDetails: [[ComparisonDetailEntry]]) {
            self.result = reportingDetails
            for outer in result {
                for inner in outer {
                    /// Observation
                    /// Get the distinct observation key
                    /// Init the statisc struct for the current observation
                    comparisons = inner.observation.observation2comparisons!.allObjects as? [Comparisons]
                    let observationStatistic = ObservationStatistics(observation: inner.observation, comparisonDetailEntries: result)
                    /// set the vote of the observation
                    var voting = Voting()
                    voting.contribution = observationStatistic.contributions.lblOwnPrimaryKeysCount
                    voting.uniqueContributions = observationStatistic.contributions.lblUniquePrimaryKeysCount
                    voting.mixedContributions = observationStatistic.contributions.lblMixedPrimaryKeysCount
                    voting.primaryKey = observationStatistic.references.primaryKey
                    voting.observation = observationStatistic.references.observation
                    voting.lookAhead = String(Int(exactly: inner.observation.observation2lookahead!.lookahead)!)
                    voting.algorithm = (inner.observation.observation2algorithm?.name)!
                    voting.timeSlices = String(Int((inner.observation.observation2prediction?.seriesdepth)!))
                    voting.entriesCount = String(Winners.countPrimaryKeys(comparions: comparisons))
                    voting.precision = observationStatistic.lblPrecision
                    voting.recall = observationStatistic.lblRcall
                    voting.f1Score = observationStatistic.lblf1Score
                    voting.foundTargets = observationStatistic.lblFoundTargets
                    voting.proposedTargets = observationStatistic.lblProposedTargets
                    if votings.first(where: { $0.primaryKey == voting.primaryKey }) == nil {
                        votings.append(voting)
                    }
                }
            }
        }
        internal static func countPrimaryKeys(comparions: [Comparisons]) -> Int {
            var distinctPrimaryKeys = Set<String>()
            for comparison in comparions {
                distinctPrimaryKeys.insert(comparison.primarykey!)
            }
            return distinctPrimaryKeys.count
        }
        struct ObservationStatistics {
            var observation: Observations
            var comparisonDetailEntries: [[ComparisonDetailEntry]]
            var comparisons: [Comparisons]
            var lblPrecision:String {
                get {
                    return bs.doubleFormatter.string(from: NSNumber(value: precision))!
                }
            }
            var lblRcall: String {
                get {
                    return bs.doubleFormatter.string(from: NSNumber(value: recall))!
                }
            }
            var lblf1Score: String {
                get {
                    return bs.doubleFormatter.string(from: NSNumber(value: f1Score))!
                }
            }
            var lblFoundTargets: String {
                get {
                    return String(foundTargets)
                }
            }
            var lblProposedTargets: String {
                get {
                    return String(proposedTargets)
                }
            }
            var precision: Double {
                get {
                    return observation.precision
                }
            }
            var recall: Double {
                get {
                    return observation.recall
                }
            }
            var f1Score: Double {
                get {
                    return observation.f1score
                }
            }
            var foundTargets: Int {
                get {
                    return countPrimaryKeys(comparions: comparisons.filter { $0.targetreported == 0 && $0.comparison2observation == observation })
                }
            }
            var proposedTargets: Int {
                get {
                    return countPrimaryKeys(comparions: comparisons.filter { $0.targetreported != 0 && $0.comparison2observation == observation })
                }
            }
            struct References {
                var primaryKey: String!
                var observation: Observations!
                var lookAhead: Lookaheads { 
                    get {
                        guard let result = observation.observation2lookahead else {
                        fatalError()
                    }
                    return result }
                }
            }
            var references: References { get {
                var result = References()
                result.observation = observation
                result.primaryKey = observation.objectID.uriRepresentation().lastPathComponent
                return result }
            }
            var contributions: Contributions {
                get {
                    return Contributions(comparisonDetailEntries: comparisonDetailEntries, observation: observation)
                }
            }
            init(observation: Observations, comparisonDetailEntries: [[ComparisonDetailEntry]]) {
                self.observation = observation
                self.comparisonDetailEntries = comparisonDetailEntries
                self.comparisons = comparisonDetailEntries.flatMap { outer in
                    outer.map { comparisonDetailEntries in
                        comparisonDetailEntries.comparison}
                }
            }
            
            struct Contributions {
                var lblOwnPrimaryKeysCount: String {
                    bs.convertToString(ownDistinctPrimaryKeys.count)
                }
                var lblForeignPrimaryKeysCount: String {
                    bs.convertToString(foreignDistinctPrimaryKeys)
                }
                var lblUniquePrimaryKeysCount:String {
                    bs.convertToString(uniqueDistinctPrimaryKeys.count)
                }
                var lblMixedPrimaryKeysCount: String {
                    bs.convertToString(mixedDistinctPrimaryKeys.count)
                }
                var ownDistinctPrimaryKeys = Set<String>()
                var foreignDistinctPrimaryKeys = Set<String>()
                var uniqueDistinctPrimaryKeys = Set<String>()
                var mixedDistinctPrimaryKeys = Set<String>()
                init(comparisonDetailEntries: [[ComparisonDetailEntry]], observation: Observations) {
                    for outer in comparisonDetailEntries {
                        for entry in outer {
                            if entry.observation == observation {
                                ownDistinctPrimaryKeys.insert(entry.primarykey)
                            } else {
                                foreignDistinctPrimaryKeys.insert(entry.primarykey)
                            }
                        }
                        uniqueDistinctPrimaryKeys = Set(Array(ownDistinctPrimaryKeys.subtracting(foreignDistinctPrimaryKeys)))
                        mixedDistinctPrimaryKeys = Set(Array(ownDistinctPrimaryKeys.intersection(foreignDistinctPrimaryKeys)))
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
        internal var votersCount: Int = 0
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
        var lblVotersCount: String {
            return String(votersCount)
        }
        var lblTargetPredicted: String {
            return BaseServices.doubleFormatter.string(from: NSNumber(value: targetsPredicted))!
        }
        var lblTargetReported: String {
            return BaseServices.doubleFormatter.string(from: NSNumber(value: targetsReported))!
        }
        var lblLookAhead: String {
            return String((observation?.observation2lookahead!.lookahead)!)
        }
        var lblTimeSlices: String {
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
            self.votersCount = Set(items.map { $0.comparison2observation }).count
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
    class HistoricalData {
        var model: Models
        var dataColumnsModel: ColumnsModel!
        var churnHistory: [Int: [Int]] = [:]
        var timeStampColumnName: String!
        var targetColumnName: String!
        var mlDataTable: MLDataTable!
        var churnCountByYear: [Int: (churned: Int, notChurned: Int)] = [:]
        init(model: Models) {
            self.model = model
            self.dataColumnsModel = ColumnsModel(model: model)
            self.targetColumnName = dataColumnsModel.targetColumns.first!.name
            self.timeStampColumnName = dataColumnsModel.timeStampColumn!.name
        }
        func fillHistory(model: Models, completion: @escaping (ChurnDataResults) -> Void) async {
            guard let mlDataTableProviderContext = SimulationController.returnFittingProviderContext(model: model, lookAhead: 0) else {
                print("\(#function) no dataContext could be generated")
                return
            }
            self.mlDataTable = mlDataTableProviderContext.mlDataTableProvider.mlDataTable
            
            // Initialize other properties (timeStampColumnName, targetColumnName, etc.) here
            
            for i in 0..<mlDataTable[self.timeStampColumnName].count {
                guard let key = mlDataTable[timeStampColumnName][i].intValue else {
                    fatalError()
                }
                guard let value = mlDataTable[targetColumnName][i].intValue else {
                    fatalError()
                }
                if churnHistory[key] == nil {
                    churnHistory[key] = [value]
                } else {
                    churnHistory[key]?.append(value)
                }
            }
            
            let churnCountByYear: [Int: (churned: Int, notChurned: Int)] = churnHistory.mapValues { churnStatus in
                let churnedCount = churnStatus.reduce(0) { $0 + ($1 == 0 ? 1 : 0) }
                let notChurnedCount = churnStatus.reduce(0) { $0 + ($1 == 1 ? 1 : 0) }
                return (churned: churnedCount, notChurned: notChurnedCount)
            }
            
            let results = ChurnDataResults(churnHistory: churnHistory, churnCountByYear: churnCountByYear)
            
            // Call the completion handler with the results
            completion(results)
        }
    }
}
