//
//  StickyFilterView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 14.08.22.
//

import Foundation
import SwiftUI
class FilterViewProvider: ObservableObject {
    var mlDataTableProvider: MlDataTableProvider
    var tableFilterView: TableFilterView
    init(mlDataTableProvider: MlDataTableProvider) {
        self.mlDataTableProvider = mlDataTableProvider
        tableFilterView = TableFilterView(columns: self.mlDataTableProvider.customColumns, gridItems: self.mlDataTableProvider.gridItems, mlDataTableFactory: self.mlDataTableProvider)
    }

}
struct TableFilterView: View {
    var gridItems: [GridItem]
    var columns: [CustomColumn]
    @State var filterDict: Dictionary<String, String>!
    var mlDataTableFactory: MlDataTableProvider
    init(columns: [CustomColumn], gridItems: [GridItem], mlDataTableFactory: MlDataTableProvider) {
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
                        self.mlDataTableFactory.filterMlDataTable(filterDict: filterDict)
                    }
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
    }
    private func binding(for key: String) -> Binding<String> {
        return Binding(get: {
            return self.filterDict[key] ?? ""
        }, set: {
            if !$0.isEmpty {
                self.filterDict[key] = $0.replacingOccurrences(of: ",", with: ".")
            } else {
                if self.filterDict[key] != nil {
                    self.filterDict.removeValue(forKey: key)
                }
            }
        })
    }
    
}
