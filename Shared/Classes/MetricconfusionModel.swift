//
//  MetricconfusionModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 21.02.23.
//

import Foundation
import CreateML
public class MetricconfusionModel: Model<Metricconfusion> {
    @Published var result: [Metricconfusion]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Metricconfusion] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    public func updateEntry(datasetTypeName: String, prediction: Predictions, algorithmName: String, table: MLDataTable) {
        guard let dataSetType = DatasettypesModel().items.first(where: {$0.name == datasetTypeName}) else {
            return
        }
        guard let algorithm = AlgorithmsModel().items.first(where: {$0.name == algorithmName}) else {
            return
        }
        let predicate = NSPredicate(format: "ANY metricconfusion2datasettype == %@ && metricconfusion2prediction == %@ && metricconfusion2algorithm == %@", dataSetType, prediction, algorithm)
        self.deleteAllRecords(predicate: predicate)
        for row in table.rows {
            let newRecord = self.insertRecord()
            newRecord.addToMetricconfusion2datasettype(dataSetType)
            newRecord.metricconfusion2algorithm = algorithm
            newRecord.metricconfusion2prediction = prediction
            newRecord.truelabel = Int16(row["True Label"]?.intValue ?? 0)
            newRecord.predicted = Int16(row["Predicted"]?.intValue ?? 0)
            newRecord.count = Int16(row["Count"]?.intValue ?? 0)
        }
        BaseServices.save()
    }
    
}
