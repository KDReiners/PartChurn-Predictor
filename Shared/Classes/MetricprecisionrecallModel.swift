//
//  MetricprecisionrecallModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 21.02.23.
//

import Foundation
import CreateML
public class MetricprecisionrecallModell: Model<Metricprecisionrecall> {
    @Published var result: [Metricprecisionrecall]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Metricprecisionrecall] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    internal func updateEntry(prediction: Predictions, algorithmName: String, targetStatistics: MlDataTableProvider.TargetStatistics) {
        guard let algorithm = AlgorithmsModel().items.first(where: {$0.name == algorithmName}) else {
            return
        }
        let predicate = NSPredicate(format: " metricprecisionrecall2prediction == %@ && metricprecisionrecall2algorithm == %@", prediction, algorithm)
        self.deleteAllRecords(predicate: predicate)
        let newRecord = self.insertRecord()
        newRecord.truepositives = Int32(targetStatistics.truePositives)
        newRecord.truenegatives = Int32(targetStatistics.trueNegatives)
        newRecord.falsepositives = Int32(targetStatistics.falsePositives)
        newRecord.falsenegatives = Int32(targetStatistics.falseNegatives)
        newRecord.metricprecisionrecall2algorithm = algorithm
        newRecord.metricprecisionrecall2prediction = prediction
        BaseServices.save()
    }
    
}
