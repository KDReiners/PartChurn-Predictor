//
//  StickyFilterView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 14.08.22.
//

import Foundation
import SwiftUI
class FilterViewProvider: ObservableObject {
    var mlDataTableFactory: MlDataTableFactory
    var tableFilterView: TableFilterView
    init(mlDataTableFactory: MlDataTableFactory) {
        self.mlDataTableFactory = mlDataTableFactory
        tableFilterView = TableFilterView(columns: self.mlDataTableFactory.customColumns, gridItems: self.mlDataTableFactory.gridItems, mlDataTableFactory: self.mlDataTableFactory)
    }

}
struct TableFilterView: View {
    var gridItems: [GridItem]
    var columns: [CustomColumn]
    @State var filterDict: Dictionary<String, String>!
    var mlDataTableFactory: MlDataTableFactory
    init(columns: [CustomColumn], gridItems: [GridItem], mlDataTableFactory: MlDataTableFactory) {
        self.columns = columns
        self.gridItems = gridItems
        self.filterDict = Dictionary<String, String>()
        self.mlDataTableFactory = mlDataTableFactory
        for column in columns {
            filterDict[column.title] = ""
        }
    }
    var body: some View {
        LazyVGrid(columns: gridItems) {
            ForEach(columns) { col in
                TextField(col.title, text: binding(for: col.title)).frame(alignment: .trailing)
                    .onSubmit {
                        print(binding(for: col.title))
                        self.mlDataTableFactory.filterMlDataTable(filterDict: filterDict)
                    }
            }
        }
    }
    private func binding(for key: String) -> Binding<String> {
        return Binding(get: {
            return self.filterDict[key] ?? ""
        }, set: {
            if !$0.isEmpty {
                self.filterDict[key] = $0
            } else {
                if self.filterDict[key] != nil {

                    self.filterDict.removeValue(forKey: key)
                }
            }
        })
    }
    
}
