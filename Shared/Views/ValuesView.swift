//
//  ValuesView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 08.06.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML
struct Column: Identifiable {
    let id = UUID()
    var title: String
    var enabled: Bool = true
    var rows: [String] = []
    var alignment: Alignment
}

struct ValuesView: View {
    var numCols: Int = 0
    var numRows : Int = 0
    var columnItems = [GridItem]()
    var coreDataML: CoreDataML
    var mlTable: MLDataTable
    
    
    var columns = [Column]()
    var maxRows: Int = 0
    
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    init( coreDataML: CoreDataML?) {
        self.coreDataML = coreDataML!
        mlTable = self.coreDataML.mlDataTable
        resolve()
        numCols = columns.count
        numRows = columns[0].rows.count
    }
    mutating func resolve() -> Void {
        
        for column in self.coreDataML.orderedColumns {
            var newColumn = Column(title: column.name ?? "Unbekannt", alignment: .trailing)
            var newGridItem: GridItem?
            var newTargetColumn: Column?
            var newTargetGridItem: GridItem?
            if column.istarget == true {
                newTargetColumn = Column(title: column.name ?? "Unbekannt" + "_predicted", alignment: .trailing)
                newTargetGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
            }
            var predictedValue: MLFeatureValue?
            for row in mlTable.rows {
                if let intValue = row[column.name!]?.intValue {
                    newColumn.rows.append(BaseServices.intFormatter.string(from: intValue as NSNumber)!)
                    newColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                }
                if let doubleValue = row[column.name!]?.doubleValue {
                    newColumn.rows.append(BaseServices.doubleFormatter.string(from: doubleValue as NSNumber)!)
                    newColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
                }
                if let  stringValue = row[column.name!]?.stringValue {
                    newColumn.rows.append(stringValue)
                    newColumn.alignment = .leading
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
                }
                if column.istarget == true {
                    predictedValue = predictFromRow(mlRow: row).featureValue(for: column.name!)
                    newTargetColumn?.rows.append(BaseServices.doubleFormatter.string(from: predictedValue!.doubleValue as NSNumber)!)
                    newTargetColumn?.alignment = .trailing
                    newTargetColumn?.title = "Predict"
                    newTargetGridItem?.alignment = .trailing
                }
            }
            self.columns.append(newColumn)
            self.columnItems.append(newGridItem!)
            if newTargetColumn != nil {
                self.columns.append(newTargetColumn!)
                self.columnItems.append(newTargetGridItem!)
            }
        }
    }
    var body: some View {
        let cells = (0..<numRows).flatMap{j in columns.enumerated().map{(i,c) in CellIndex(id:j + i*numRows, colIndex:i, rowIndex:j)}}
        ScrollView([.vertical], showsIndicators: true) {
            LazyVGrid(columns:columnItems, pinnedViews: [.sectionHeaders], content: {
                Section(header: stickyHeaderView) {
                    ForEach(cells) { cellIndex in
                        let column = columns[cellIndex.colIndex]
                        Text(column.rows[cellIndex.rowIndex])
                            .font(.body).monospacedDigit()
                            .scaledToFit()
                        
                    }
                }
            })
        }.background(.white)
        
    }
    var stickyHeaderView: some View {
        Rectangle()
            .fill(Color.gray)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 40, maxHeight: .infinity)
            .overlay(
                LazyVGrid(columns: columnItems) {
                    ForEach(columns) { col in
                        Text(col.title)
                            .foregroundColor(Color.white)
                            .font(.body)
                            .scaledToFit()
                    }
                }
            )
    }
    fileprivate func predict(_ result: [String : MLDataValueConvertible]) -> MLFeatureProvider {
        let provider: MLDictionaryFeatureProvider = {
            do {
                return try MLDictionaryFeatureProvider(dictionary: result)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        let path = "/Users/klaus.reiners/Documents/WK/Swift/PartChurn Analysis/PartChurn Predictor/Shared/MLModels/LinearPredictor.mlmodel"
        var isDir:ObjCBool = true
        let url = URL.init(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            let compiledUrl:URL = {
            do {
                return try MLModel.compileModel(at: url)
            } catch {
                    fatalError(error.localizedDescription)
            }
            }()
            let test = try? MLModel(contentsOf: compiledUrl)
        }
        let model: MLBoostedTreePredictor = {
            do {
                let config = MLModelConfiguration()
                return try MLBoostedTreePredictor(configuration: config)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        let prediction: MLFeatureProvider = {
            do {
                return try model.model.prediction(from: provider)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        return prediction
    }
    public func predictFromRow(mlRow: MLDataTable.Row) -> MLFeatureProvider {
        var result = [String: MLDataValueConvertible]()
        for i in 0..<mlRow.keys.count {
            if mlRow.keys[i] != "Kuendigt" {
                result[mlRow.keys[i]] = mlRow.values[i].intValue
                if  result[mlRow.keys[i]] == nil {
                    result[mlRow.keys[i]] = mlRow.values[i].doubleValue
                }
                if  result[mlRow.keys[i]] == nil {
                    result[mlRow.keys[i]] = mlRow.values[i].stringValue
                }
            }
        }
        return predict(result)
    }
}

struct ValuesView_Previews: PreviewProvider {
    static var previews: some View {
        return ValuesView(coreDataML: nil)
    }
}
