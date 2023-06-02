//
//  CustomColumn.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 04.07.22.
//

import Foundation
import SwiftUI
import CreateML
struct CustomColumn: Identifiable {
    let id = UUID()
    var title: String
    var enabled: Bool = true
    var rows: [String] = []
    var lists: [GridItemView] = []
    var alignment: Alignment
}
