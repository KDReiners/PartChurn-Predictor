//
//  PredictionsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 22.08.22.
//
import SwiftUI
import Foundation
import CoreData
import TabularData
public class PredictionsModel: Model<Predictions> {
    @Published var result: [Predictions]!
    @Published var arrayOfPredictions = [PredictionCluster]()
    @Published var timeSeriesSelections = [String]()
    private var model: Models?
    private var lookAheadModel = LookaheadsModel()
    private var compositionsDataModel: CompositionsModel?
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    public init(model: Models) {
        self.model = model
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Predictions] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted { (lhs, rhs) in
                if lhs.columnsdepth == rhs.columnsdepth { // <1>
                    return lhs.seriesdepth > rhs.seriesdepth
                }
                return lhs.seriesdepth < rhs.seriesdepth // <2>
            }
        }
    }
    internal func savePredictions(model: Models) {
        getCurrentCombinations(model: model)
        for cluster in compositionsDataModel!.arrayOfClusters {
            let newPrediction = self.insertRecord()
            newPrediction.id = UUID()
            newPrediction.groupingpattern = cluster.groupingPattern
            newPrediction.seriesdepth = Int32(cluster.seriesDepth)
            newPrediction.columnsdepth = Int32(cluster.columns.count)
            newPrediction.prediction2model = model
            for composition in cluster.compositions {
                
                composition.composition2predictions = newPrediction
            }
        }
        BaseServices.save()
    }
    internal func returnLookAhead(prediction: Predictions, lookAhead: Int) -> Lookaheads {
        var result: Lookaheads?
        let lookAheads = lookAheadModel.items
        if lookAheads.count > 0 {
            result = lookAheads.first(where: { $0.lookahead == lookAhead})
        }
        if result == nil{
            let newLookAhead = LookaheadsModel().insertRecord()
            newLookAhead.addToLookahead2predictions(prediction)
            newLookAhead.lookahead = Int32(lookAhead)
            result = newLookAhead
        } else {
            result?.addToLookahead2predictions(prediction)
        }
//        BaseServices.save()
        guard let result = result else {
            fatalError("LookAhead could not be found!")
        }
        return result
    }
    private func getCurrentCombinations(model: Models) {
        self.model = model
        compositionsDataModel =  CompositionsModel(model: model)
        compositionsDataModel?.retrievePredictionClusters()
    }
    internal func getTargetStatistics(observation: Observations, algorithm: Algorithms ) -> MlDataTableProvider.TargetStatistics? {
        let result = MlDataTableProvider.TargetStatistics()
        guard let prediction = observation.observation2prediction  else {
            print("\(#function) cannot create prediction out of observation.")
            return result
        }
        guard let observationmetricvalues = prediction.prediction2predictionmetricvalues?.allObjects as? [Predictionmetricvalues] else {
            return result
        }
        let concretePredictionMetricValues = observationmetricvalues.filter( { $0.predictionmetricvalue2algorithm == algorithm && $0.predictionmetricvalue2lookahead == observation.observation2lookahead  })
        if concretePredictionMetricValues.count > 0 {
            for label in result.propertyNames() {
                result.setValue(concretePredictionMetricValues.first(where: { $0.predictionmetricvalue2predictionmetric?.name == label })!.value, forKey: label)
            }
        } else {
            return nil
        }
        return result
        
    }
    internal func createPredictionForModel(model: Models) {
        //      self.deleteAllRecords(predicate: nil)
        self.model = model
        let foundItems = self.items.filter( { $0.prediction2model == model })
        for item in foundItems {
            let newPredictionPresenatation = createPredictionCluster(item: item)
            arrayOfPredictions.append(newPredictionPresenatation)
        }
    }
    internal func createPredictionCluster(item: Predictions) -> PredictionCluster {
        let newPredictionPresenatation = PredictionCluster()
        newPredictionPresenatation.prediction = item
        newPredictionPresenatation.id = item.id!
        newPredictionPresenatation.groupingPattern = item.groupingpattern
        newPredictionPresenatation.seriesDepth = Int32(item.seriesdepth)
        newPredictionPresenatation.columnsDepth = Int32(item.columnsdepth)
        let composition = (item.prediction2compositions!.allObjects.first as! Compositions)
        newPredictionPresenatation.columns.append(contentsOf: composition.composition2columns?.allObjects as! [Columns])
        for composition in item.prediction2compositions!.allObjects as! [Compositions] {
            //                newPredictionPresenatation.columns.append(contentsOf: composition.composition2columns?.allObjects as! [Columns])
            newPredictionPresenatation.timeSeries.append(composition.composition2timeseries!)
        }
        return newPredictionPresenatation
    }
    internal class PredictionCluster: CompositionsModel.CompositionCluster {
        var columnsDepth: Int32!
        var prediction: Predictions!

        var connectedTimeSeries: [String]? {
            get {
                var result: [String]?
                if self.timeSeries.count > 0 {
                    result = [String]()
                    for series in self.timeSeries.sorted(by: { $0.from < $1.from }) {
                        let test = (series.timeseries2timeslices?.allObjects as! [Timeslices]).sorted(by: { $0.value < $1.value }).map( {String($0.value)}).joined(separator: ", ")
                        result!.append(test)
                    }
                }
                return result
            }
        }
        var selectedTimeSeries: [[Int]]? {
            get {
                var result: [[Int]]?
                if self.connectedTimeSeries != nil {
                    result = [[Int]]()
                    for row in self.connectedTimeSeries! {
                        let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                        result!.append(innerResult)
                    }
                }
                return result
            }
            
        }
        var minTimeSeries: Int32? {
            return timeSeries.min(by: { $0.from < $1.from })?.from
        }
        var maxTimeSeries: Int32? {
            return timeSeries.max(by: { $0.from < $1.from })?.from
        }
        var maxLookAhead: Int? {
            return connectedTimeSeries?.count
        }
        internal struct LookAheadView: View {
            @Binding internal var selectedLookAhead: Int?
            @Binding internal var maxLookAhead: Int
            
            var body: some View {
                List(selection: $selectedLookAhead) {
                    ForEach(0..<maxLookAhead, id: \.self) { number in
                        Row(number: number, selectedNumber: $selectedLookAhead)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        struct Row: View {
            let number: Int
            @Binding var selectedNumber: Int?
            
            var body: some View {
                Button(action: {
                    selectedNumber = selectedNumber == number ? nil: number
                }) {
                    HStack {
                        Text("\(number)")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedNumber == number {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
    }
}
struct MLExplainColumnCluster {
    var prediction: Predictions!
    var allColumns: [Columns]!
    var inputColumns: [Columns]!
    var timeSeriesColumn: Columns?
    var targetColumn: Columns?
    var partOfPrimaryKeyColumn: Columns!
    var composition: Compositions!
    init(prediction: Predictions)
    {
        self.prediction = prediction
        composition = prediction.prediction2compositions?.allObjects.first as? Compositions
        allColumns = composition.composition2columns?.allObjects as? [Columns]
        inputColumns = allColumns.filter({$0.istimeseries == 0 && $0.isshown == 1 && $0.ispartofprimarykey == 0 && $0.isincluded == 1 && $0.istarget == 0})
        timeSeriesColumn = (prediction.prediction2model?.model2columns?.allObjects as? [Columns])?.filter( { $0.istimeseries == 1}).first
        if timeSeriesColumn != nil {
            targetColumn = ((prediction.prediction2model?.model2columns?.allObjects as? [Columns])?.filter( {$0.istarget == 1 && $0.ispartoftimeseries == 1}).first)!
        } else {
            targetColumn = ((prediction.prediction2model?.model2columns?.allObjects as? [Columns])?.filter( {$0.istarget == 1 && $0.ispartoftimeseries == 0}).first)!
        }
        partOfPrimaryKeyColumn = ((prediction.prediction2model?.model2columns?.allObjects as? [Columns])?.filter( { $0.ispartofprimarykey == 1}).first)!
    }
    
}
