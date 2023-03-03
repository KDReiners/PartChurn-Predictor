//
//  CategoriesModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 01.03.23.
//

import Foundation
import CoreData
import SwiftUI
public class CategoriesModel: Model<Categories> {
    @Published var result: [Categories]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Categories] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
}
