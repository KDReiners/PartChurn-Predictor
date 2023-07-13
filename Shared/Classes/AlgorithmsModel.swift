//
//  AlgorithmsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 18.05.22.
//

import Foundation
import SwiftUI
public class AlgorithmsModel: Model<Algorithms> {
    @Published var result: [Algorithms]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Algorithms] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.orderno > $0.orderno })
        }
    }
    internal static func showKpis(prediction: Predictions?, algorithmName: String?, lookAhead: Int?) -> Ml_RegressorMetricKPI {
        let result = Ml_RegressorMetricKPI()
        let algorithmsModel = AlgorithmsModel()
        let metricValuesModel = MetricvaluesModel()
        guard let prediction = prediction else {
            return result
        }
        guard let model = prediction.prediction2model else {
            return result
        }
        guard let lookAhead = lookAhead else {
            return result
        }
        let predictionsModel = PredictionsModel(model: model)
        let lookAheadItem = predictionsModel.returnLookAhead(prediction: prediction, lookAhead: lookAhead)
        
        guard let algorithm = algorithmsModel.items.first(where: { return  $0.name == algorithmName }) else {
            return result
        }
        let metricValues = metricValuesModel.items.filter( {
            return $0.metricvalue2algorithm == algorithm && $0.metricvalue2prediction == prediction && $0.metricvalue2lookahead == lookAheadItem
        })
        for metricValue in  metricValues {
            let key = (metricValue.metricvalue2datasettype?.name!)! + "Metrics." + (metricValue.metricvalue2metric?.name!)!
            result.dictOfMetrics[key]? = metricValue.value
        }
        return result
        
    }
    public struct valueList: View {
        var metricStructure: Ml_RegressorMetricKPI!
        var model: Models?
        var fileName: String?
        var algorithmName: String?
        var prediction: Predictions?
        var lookAhead: Int?
        public init(prediction: Predictions?, algorithmName: String, lookAhead: Int?) {
            self.model = prediction?.prediction2model
            self.prediction = prediction
            self.algorithmName = algorithmName
            self.lookAhead = lookAhead
            metricStructure = AlgorithmsModel.showKpis(prediction: prediction, algorithmName: algorithmName, lookAhead: lookAhead)
            metricStructure.updateMetrics()
        }
        public var body: some View {
            List {
                Section(header: Text(algorithmName ?? "Unbekannt").font(.title2)){
                    ForEach(metricStructure.sections, id: \.id) { header in
                        Section(header: Text(header.dataSetType ?? "Unbekannt").font(.title3)) {
                            ForEach(header.metricTypes!, id: \.metricType) { metric in
                                HStack {
                                    Text(metric.metricType!)
                                    Spacer()
                                    Text("\(metric.metricValue)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


