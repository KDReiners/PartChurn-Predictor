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
    
    internal var composer: Composer?
    internal var combinator: Combinator
    init(model: Models) {
        self.model = model
        self.composer = Composer(model: model)
        self.combinator = Combinator(model: self.model, orderedColumns: (composer?.orderedColumns)!, mlDataTable: (composer?.mlDataTable_Base)!)
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
//                    ValuesView(mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: (composer?.orderedColumns)!, selectedColumns: selectedColumnCombination, selectedTimeSeries: selectedTimeSeriesCombination)
            }
        }
    }
}

struct ComposerView_Previews: PreviewProvider {
    static var previews: some View {
        ComposerView(model: ModelsModel().items.first!)
    }
}
