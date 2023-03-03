//
//  TestMultiselect.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 02.03.23.
//

import SwiftUI

struct TestMultiselect: View {
    @State private var selectedItems: Set<String> = []

    let items = [
        "Item 1",
        "Item 2",
        "Item 3",
        "Item 4",
        "Item 5"
    ]

    var body: some View {
        List(items, id: \.self, selection: $selectedItems) { item in
            Text(item)
        }
    }
}
