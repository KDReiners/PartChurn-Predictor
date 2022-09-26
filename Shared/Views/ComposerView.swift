//
//  ComposerView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.07.22.
//

import SwiftUI
import CoreMedia

struct ComposerView: View {
    var model: Models
    @State var selectedColumnCombination: [Columns]?
    @State var selectedTimeSeriesCombination: [String]?
    var compositionsDataModel: CompositionsModel
    var valuesView: ValuesView?
    var mlDataTableProvider: MlDataTableProvider
    var composer: FileWeaver?
    var combinator: Combinator
    var columnsDataModel: ColumnsModel?
    init(model: Models, composer: FileWeaver, combinator: Combinator, compositionsDataModel: CompositionsModel) {
        self.model = model
        self.compositionsDataModel = compositionsDataModel
        self.columnsDataModel = ColumnsModel(model: self.model)
        self.composer = composer
        self.combinator = combinator
        self.mlDataTableProvider = MlDataTableProvider()
        self.mlDataTableProvider.mlDataTable = composer.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = composer.orderedColumns!
        valuesView = ValuesView(mlDataTableProvider: self.mlDataTableProvider)
        updateValuesView()
    }
    var body: some View {
        HStack(spacing: 50) {
            VStack(alignment: .center) {
                Text(model.name ?? "unbekanntes Model")
                    .font(.title)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                Divider()
                HStack(spacing: 50) {
                    VStack(alignment: .leading) {
                        Text("Timeseries Combinations")
                        List(combinator.scenario.timeSeriesSections, id: \.rows, selection: $selectedTimeSeriesCombination) { section in
                            Section(header: Text("Level: \(section.level)"))  {
                                ForEach(section.rows, id: \.self) { row in
                                    HStack {
                                        Text(row)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedTimeSeriesCombination = selectedTimeSeriesCombination == section.rows ? nil: section.rows }
                                }
                            }.padding(.top, 2)
                        }
                    }.padding()
                    .onChange(of: selectedTimeSeriesCombination) { newSelectedTimeSeriesCombination in
                        self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
                        if let timeSeriesRows = newSelectedTimeSeriesCombination {
                            var selectedTimeSeries = [[Int]]()
                            for row in timeSeriesRows {
                                let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                                selectedTimeSeries.append(innerResult)
                            }
                            self.mlDataTableProvider.timeSeries = selectedTimeSeries
                        } else {
                            self.mlDataTableProvider.timeSeries = nil
                        }
                        updateValuesView()
                    }

                    VStack(alignment: .leading) {
                        Text("Column Combinations")
                        List(combinator.scenario.columnSections, id: \.self, selection: $selectedColumnCombination) { section in
                            Section(header: Text("Level: \(section.level)"))  {
                                ForEach(section.columns, id: \.self) { columns in
                                    HStack {
                                        ForEach(columns, id: \.self) { column in
                                            HStack {
                                                Text(column.name!)
                                                Spacer()
                                            }
                                            .contentShape(Rectangle())
                                        }
                                    }.onTapGesture { selectedColumnCombination = selectedColumnCombination == columns ? nil: columns }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }.padding()
                    .onChange(of: selectedColumnCombination) { newSelectedColumnCombination in
                        self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
                        self.mlDataTableProvider.selectedColumns = newSelectedColumnCombination
                        self.mlDataTableProvider.orderedColumns = composer?.orderedColumns
                        updateValuesView()
                    }
                }
                HStack {
                    Button("Save Compositions") {
                        storeCompositions()
                    }
                    Button("Delete Compositions") {
                        deleteCombinations()
                    }
                }
                VStack(alignment: .leading) {
                    valuesView
                }.padding(.horizontal)
            }
        }
    }
    func updateValuesView() {
        self.mlDataTableProvider.mlDataTableRaw = nil
        self.mlDataTableProvider.mlDataTable = self.mlDataTableProvider.buildMlDataTable().mlDataTable
        self.mlDataTableProvider.updateTableProvider()
        self.mlDataTableProvider.loaded = false
    }
    struct Combination {
        var compositionDataModel: CompositionsModel
//        var modelsDataModel = ModelsModel()
//        var columnsDataModel = ColumnsModel()
        var model: Models!
        var columns = [Columns]()
        var timeSeries: Timeseries!
        var i: Int16 = 0
        func saveToCoreData() {
            let compositionEntry = self.compositionDataModel.insertRecord()
            compositionEntry.id = UUID()
            compositionEntry.composition2model = self.model
            compositionEntry.composition2timeseries = timeSeries
            compositionEntry.composition2columns = NSSet(array: columns)
//            for column in columns {
//                compositionEntry.addToComposition2columns(column)
//            }
        }
    }
    internal func storeCompositions() {
        let seriesEntries = self.combinator.getTimeSeriesEntries()
        for columns in self.combinator.columnCombinations {
            for seriesEntry in seriesEntries {
                var combination = Combination(compositionDataModel: self.compositionsDataModel)
                combination.model = self.model
                combination.columns.append(contentsOf: columns)
                combination.timeSeries = seriesEntry.timeSeries
                combination.saveToCoreData()
            }
        }
        BaseServices.save()
    }
    internal func deleteCombinations() {
        let compositionDataModel = self.compositionsDataModel
        compositionDataModel.deleteAllRecords(predicate: nil)
        let timeseriesDataModel = TimeSeriesModel()
        timeseriesDataModel.deleteAllRecords(predicate: nil)
        let timeSliceModel = TimeSliceModel()
        timeSliceModel.deleteAllRecords(predicate: nil)
        compositionDataModel.arrayOfClusters = [CompositionsModel.Cluster]()
        BaseServices.save()
        
    }


}
