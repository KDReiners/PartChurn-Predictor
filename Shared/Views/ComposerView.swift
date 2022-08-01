//
//  ComposerView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.07.22.
//

import SwiftUI

struct ComposerView: View {
    var model: Models
    @State var scenarioSelection: Scenario?
    @State var timeSeriesSeletion: [Int]?
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
                        Text("Time Series Combinations")
                        List(combinator.scenarios.first!.listOfTimeSeriesCombinations(), id: \.self) { timeSeries in
                            Text(timeSeries)
                        }
                            .listStyle(.plain)
                    }
                    VStack(alignment: .leading) {
                        Text("Column Combinations")
                        List(combinator.scenarios, id: \.self, selection: $scenarioSelection) {
                            scenario in
                            if scenario.levelIncludedColumns() > 0 {
                                Section(header: Text("Level: \(scenario.levelIncludedColumns())")) {
                                    ForEach(scenario.listOfColumnNames(), id: \.self ) { name in
                                        Text(name).padding(.bottom, 0)
                                    }
                                }
                                .padding(.bottom, 0 )
                            }
                        }.padding(.bottom, 0)
                            .listStyle(.plain)
                    }
                }
                ValuesView(mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: composer!.orderedColumns)
            }
        }
    }
}

struct ComposerView_Previews: PreviewProvider {
    static var previews: some View {
        ComposerView(model: ModelsModel().items.first!)
    }
}
