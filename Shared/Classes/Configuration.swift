//
//  Configuration.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 16.07.23.
//

import Foundation
import CreateML
import CoreData
import SwiftUI
class Configuration: ObservableObject {
    @Published var predictions: [Predictions] = []
    var columnsDataModel: ColumnsModel!
    var mlDataTable: MLDataTable?
    var statisticContext : SimulationController.MlDataTableProviderContext?
    var model: Models!
    init() {
    }
    func getStatistics() {
        self.columnsDataModel = ColumnsModel(model: self.model)
        if let context = SimulationController.returnFittingProviderContext(model: self.model, lookAhead: 0) {
                    statisticContext = context
        }
        guard let table = statisticContext?.mlDataTableProvider.mlDataTable! else {
            return
        }
        self.mlDataTable = table
        let targetColumn = columnsDataModel.targetColumns.first?.name!
        let test = getUniqueValues(columnName: targetColumn!)
        print(test)
    
    }
    private func getUniqueValues(columnName: String) -> Int{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"

        var selectedAggregators = [MLDataTable.Aggregator]()
        let counter = MLDataTable.Aggregator(operations: .count, of: "Count")
        selectedAggregators.append(counter)
        let sumUp =  MLDataTable.Aggregator(operations: .sum, of: "I_MAINTENANCE")
        selectedAggregators.append(sumUp)
        let groupedTable = self.mlDataTable!.group(columnsNamed: columnName, aggregators: selectedAggregators)
        return groupedTable.rows.count
    }
     
}
internal struct StatisticsView: View {
    var configuration: Configuration
    var body: some View {
        Text("Here i am")
    }
    
}
