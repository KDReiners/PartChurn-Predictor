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
    internal static func showKpis(model: Models, file: Files?, algorithmName: String?) -> Ml_MetricKPI {
        var result = Ml_MetricKPI()
        let algorithmsModel = AlgorithmsModel()
        let metricValuesModel = MetricvaluesModel()
        guard let algorithm = algorithmsModel.items.first(where: { return  $0.name == algorithmName }) else {
            return result
        }
        let metricValues = metricValuesModel.items.filter( {
            return $0.metricvalue2file == file && $0.metricvalue2algorithm == algorithm
        })
        for metricValue in  metricValues {
            let key = (metricValue.metricvalue2datasettype?.name!)! + "Metrics." + (metricValue.metricvalue2metric?.name!)!
            result.dictOfMetrics[key]? = metricValue.value
            print("Key: \(key) metric: \(metricValue.value)")
        }
        return result
        
    }
    public struct valueList: View {
        @State var model: Models?
        @State var fileName: String?
        @State var file: Files? = nil
        @State var algorithmName: String?
        @State var oldSection: String?
        internal var metricStructure: Ml_MetricKPI?
        public init(model: Models, file: Files?, algorithmName: String) {
            self.model = model
            self.file = FilesModel().items.first(where: { return $0.name == fileName })
            self.algorithmName = algorithmName
            metricStructure = AlgorithmsModel.showKpis(model: model, file: file, algorithmName: algorithmName)
        }
        public var body: some View {
            List {
                ForEach(metricStructure?.dictOfMetrics.sorted(by: >) ?? Ml_MetricKPI().dictOfMetrics.sorted(by: >), id: \.key) { key, value in
                    let resolvedKey = metricStructure?.resolveDictOfMetrics(key: key)
                    Section(header: Text(resolvedKey!.datasetType).font(.subheadline)) {
                        HStack {
                            Text("\(resolvedKey!.metricType)")
                            Spacer()
                            Text("\(value)")
                        }
                    }
                }
            }
        }
    }
}


