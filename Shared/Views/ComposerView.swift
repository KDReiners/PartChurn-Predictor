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
    
    internal var composer: FileWeaver?
    internal var combinator: Combinator
    init(model: Models, composer: FileWeaver?, combinator: Combinator) {
        self.model = model
        self.composer = composer
        self.combinator = combinator
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
                                    }
                                    .onTapGesture { selectedTimeSeriesCombination = selectedTimeSeriesCombination == section.rows ? nil: section.rows }
                                }
                            }.padding(.top, 2)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Column Combinations")
                        List(combinator.scenario.columnSections, id: \.self, selection: $selectedColumnCombination) { section in
                            Section(header: Text("Level: \(section.level)"))  {
                                ForEach(section.columns, id: \.self) { columns in
                                    HStack {
                                        ForEach(columns, id: \.self) { column in
                                            Text(column.name!)
                                                .padding(0)
                                        }
                                    }.onTapGesture { selectedColumnCombination = selectedColumnCombination == columns ? nil: columns }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                HStack {
                    Button("Save Compositions") {
                        self.combinator.storeCompositions()
                    }
                    Button("Delete Compositions") {
                        self.combinator.deleteCombinations()
                    }
                }
                VStack(alignment: .leading) {
//                    ValuesView(mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: (composer?.orderedColumns)!, selectedColumns: selectedColumnCombination, timeSeriesRows: selectedTimeSeriesCombination)
                }.padding(.horizontal)
            }
        }
    }
}
