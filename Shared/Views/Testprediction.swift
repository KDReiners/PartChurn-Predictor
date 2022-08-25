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
/*
struct Column: Identifiable {
    let id = UUID()
    var title: String
    var enabled: Bool = true
    var rows: [String] = []
    var alignment: Alignment
}

struct ValuesView_Predict: View {
    var numCols: Int = 0
    var numRows : Int = 0
    var gridItems = [GridItem]()
    var coreDataML: CoreDataML
    var mlTable: MLDataTable
    var columns = [Column]()
    var models = [model]()
    var maxRows: Int = 0
    var regressorName: String
    
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    init( coreDataML: CoreDataML?, regressorName: String) {
        self.coreDataML = coreDataML!
        self.regressorName = regressorName
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
                    predictedValue = predictFromRow(regressorName: regressorName, mlRow: row).featureValue(for: column.name!)
                    newTargetColumn?.rows.append(BaseServices.doubleFormatter.string(from: predictedValue!.doubleValue as NSNumber)!)
                    newTargetColumn?.alignment = .trailing
                    newTargetColumn?.title = "Predict"
                    newTargetGridItem?.alignment = .trailing
                }
            }
            self.columns.append(newColumn)
            self.gridItems.append(newGridItem!)
            if newTargetColumn != nil {
                self.columns.append(newTargetColumn!)
                self.gridItems.append(newTargetGridItem!)
            }
        }
    }
    var body: some View {
        let cells = (0..<numRows).flatMap{j in columns.enumerated().map{(i,c) in CellIndex(id:j + i*numRows, colIndex:i, rowIndex:j)}}
        ScrollView([.vertical], showsIndicators: true) {
            LazyVGrid(columns:gridItems, pinnedViews: [.sectionHeaders], content: {
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
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40, maxHeight: .infinity)
                .overlay(
                    LazyVGrid(columns: gridItems) {
                        ForEach(columns) { col in
                            Text(col.title)
                                .foregroundColor(Color.white)
                                .font(.body)
                                .scaledToFit()
                        }
                    }
                )
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40, maxHeight: .infinity)
                .overlay(
                     stickyFilterView(columns: columns)
                )
        }.padding(0)
    }
    struct stickyFilterView: View {
        var columns: [Column]
        @State var filterDict = Dictionary<String, String>()
        init(columns: [Column]) {
            self.columns = columns
            for column in columns {
                filterDict[column.title] = ""
            }
        }
        var body: some View {
            ForEach(columns) { col in
                TextField(col.title, text: binding(for: col.title))
                    .onSubmit {
                        print(binding(for: col.title))
                    }
            }
        }
        private func binding(for key: String) -> Binding<String> {
                return Binding(get: {
                    return self.filterDict[key] ?? ""
                }, set: {
                    self.filterDict[key] = $0
                })
            }

    }
    fileprivate mutating func predict(regressorName: String, result: [String : MLDataValueConvertible]) -> MLFeatureProvider {
        let provider: MLDictionaryFeatureProvider = {
            do {
                return try MLDictionaryFeatureProvider(dictionary: result)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        let url = BaseServices.homePath.appendingPathComponent(regressorName+".mlmodel")
        let model = getModel(path: url.path)
        let prediction: MLFeatureProvider = {
            do {
                return try model.prediction(from: provider)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        return prediction
    }
    private mutating func getModel(url: String) ->MLModel {
        var result: MLModel?
        if let result = models.filter({ $0.path == path}).first?.model {
            return result
        } else {
            let url = URL.init(fileURLWithPath: path)
            let compiledUrl:URL = {
                do {
                    return try MLModel.compileModel(at: url)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            result = {
                do {
                    return try MLModel(contentsOf: compiledUrl)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            
        }
        let newModel = model(model: result!, url:)
        models.append(newModel)
        return result!
    }
    public mutating func predictFromRow(regressorName: String, mlRow: MLDataTable.Row) -> MLFeatureProvider {
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
        return predict(regressorName: regressorName, result: result)
    }
}

*/

