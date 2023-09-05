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
    @State var selectedColumnCombination: Set<Columns> = []
    @State var selectedTimeSeriesCombination: [String]?
    var previousSelectedColumnCombination: Set<Columns> = []
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
        self.mlDataTableProvider = MlDataTableProvider(model: self.model)
        self.mlDataTableProvider.mlDataTable = composer.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = composer.orderedColumns!
        valuesView = ValuesView(mlDataTableProvider: self.mlDataTableProvider)
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
//                            updateValuesView()
                        }
                    VStack(alignment: .leading) {
                        Text("Columns ")
                        List(combinator.includedColumns.filter( { $0.isshown == true && $0.ispartofprimarykey == false} ), id: \.self, selection: $selectedColumnCombination) { column in
                            Text(column.name!)
                                .onTapGesture {
                                    if selectedColumnCombination.contains(column) {
                                        selectedColumnCombination.remove(column)
                                    } else {
                                        selectedColumnCombination.insert(column)
                                    }
                                }
                        }
                    }
                    .onTapGesture {
                        selectedColumnCombination.removeAll()
                    }
                    .padding()
                    .onChange(of: selectedColumnCombination) { newSelectedColumnCombination in
                        self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
                        self.mlDataTableProvider.selectedColumns = Array(newSelectedColumnCombination)
                        self.mlDataTableProvider.orderedColumns = composer?.orderedColumns
//                        updateValuesView()
                    }
                }
                HStack {
                    Button("Save Current Composition") {
                        storeComposition()
                    }.disabled(selectedColumnCombination.count == 0 || selectedTimeSeriesCombination == nil)
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
        }.onAppear {
//            updateValuesView()
        }
    }
    func updateValuesView() {
        let callingFunction = #function
        let className = String(describing: type(of: self))
        self.mlDataTableProvider.mlDataTableRaw = nil
        self.mlDataTableProvider.mlDataTable = try? self.mlDataTableProvider.buildMlDataTable().mlDataTable
        self.mlDataTableProvider.updateTableProvider(callingFunction: callingFunction, className: className, lookAhead: 0)
        self.mlDataTableProvider.loaded = false
    }
    struct Combination {
        var compositionDataModel: CompositionsModel
        var model: Models!
        var columns = [Columns]()
        var timeSeries: Timeseries!
        var i: Int32 = 0
        func saveToCoreData() {
            let compositionEntry = self.compositionDataModel.insertRecord()
            compositionEntry.id = UUID()
            compositionEntry.composition2model = self.model
            compositionEntry.composition2timeseries = timeSeries
            compositionEntry.composition2columns = NSSet(array: columns)
        }
    }
    internal func storeComposition() {
        let seriesLength = selectedTimeSeriesCombination![0].split(separator: ",").count
        let seriesEntries = self.combinator.getTimeSeriesEntries().filter {$0.timeSeries.timeseries2timeslices?.count == seriesLength}
        for seriesEntry in seriesEntries {
            var combination = Combination(compositionDataModel: self.compositionsDataModel)
            combination.model = self.model
            combination.columns.append(contentsOf: selectedColumnCombination)
            combination.timeSeries = seriesEntry.timeSeries
            combination.saveToCoreData()
        }
        BaseServices.save()
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
        let timeSliceModel = TimeSlicesModel()
        timeSliceModel.deleteAllRecords(predicate: nil)
        compositionDataModel.arrayOfClusters = [CompositionsModel.CompositionCluster]()
        BaseServices.save()
        
    }
    
    
}
