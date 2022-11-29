//
//  AlternateRows.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 28.11.22.
//

import Foundation
import SwiftUI
struct ContentView: View {
    let columns: Int = 5

    var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 0), count: columns)
        ScrollView(.vertical) {
            LazyVGrid(columns: gridItems, spacing: 0) {
                ForEach(0 ..< 20) { index in
                    Text("Item \(index)")
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(isEvenRow(index) ? Color.red: Color.green)
                }
            }
        }
    }

    func isEvenRow(_ index: Int) -> Bool {
        index / columns % 2 == 0
    }
}
