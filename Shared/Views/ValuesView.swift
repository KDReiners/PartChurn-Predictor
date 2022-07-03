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
    var betterRows: [String] = []
    var alignment: Alignment
}
struct model: Identifiable {
    let id = UUID()
    var model: MLModel
    var path: String
}
struct ValuesView: View {
    var numCols: Int = 0
    var numRows : Int = 0
    var gridItems = [GridItem]()
    var coreDataML: CoreDataML
    var mlDict = [String: MLDataValueConvertible]()
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
        mlDict = self.coreDataML.inputDictionary
        prepareView()
        numCols = columns.count
        numRows = columns[0].betterRows.count
    }
    mutating func prepareView() -> Void {
        var rows = [String]()
        for column in self.coreDataML.orderedColumns {
            var newColumn = Column(title: column.name ?? "Unbekannt", alignment: .trailing)
            var newGridItem: GridItem?
            var newTargetColumn: Column?
            var newTargetGridItem: GridItem?
            if column.istarget == true {
                newTargetColumn = Column(title: column.name ?? "Unbekannt" + "_predicted", alignment: .trailing)
                newTargetGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
            }
            let valueType = mlTable[column.name!].type
            switch valueType {
            case MLDataValue.ValueType.int:
                rows = Array.init(mlTable[column.name!].map( { BaseServices.intFormatter.string(from: NSNumber(value: $0.intValue!)) }))
                newColumn.alignment = .trailing
                newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                column.datatype = setColumnDataType(column: column, calcedDataType: BaseServices.columnDataTypes.Int)
            case MLDataValue.ValueType.double:
                rows = Array.init(mlTable[column.name!].map( { BaseServices.doubleFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
                column.datatype = setColumnDataType(column: column, calcedDataType:BaseServices.columnDataTypes.Double)
                newColumn.alignment = .trailing
                newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
            case MLDataValue.ValueType.string:
                rows = Array.init(mlTable[column.name!].map( { $0.stringValue! }))
                column.datatype = BaseServices.columnDataTypes.String.rawValue
                column.datatype = setColumnDataType(column: column, calcedDataType:BaseServices.columnDataTypes.String)
                newColumn.alignment = .leading
                newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
                default:
                    print("error")
            }
            BaseServices.save()
//          rows = Array.init(mlTable[column.name!].map( { String($0.intValue!) }))
            newColumn.betterRows.append(contentsOf: rows)
            newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
            self.columns.append(newColumn)
            self.gridItems.append(newGridItem!)
            if newTargetColumn != nil {
                self.columns.append(newTargetColumn!)
                self.gridItems.append(newTargetGridItem!)
            }
        }
    }
    func setColumnDataType(column: Columns, calcedDataType: BaseServices.columnDataTypes) -> Int16 {
        var result: Int16 = 0
        if column.datatype == calcedDataType.rawValue {
            column.isuserdefined = false
            result = calcedDataType.rawValue
            
        }
        if column.isuserdefined == true && column.datatype != calcedDataType.rawValue {
            result = column.datatype
        }
        return result
    }
    var body: some View {
        let cells = (0..<numRows).flatMap{j in columns.enumerated().map{(i,c) in CellIndex(id:j + i*numRows, colIndex:i, rowIndex:j)}}
        ScrollView([.vertical], showsIndicators: true) {
            LazyVGrid(columns:gridItems, pinnedViews: [.sectionHeaders], content: {
                Section(header: stickyHeaderView) {
                    ForEach(cells) { cellIndex in
                        let column = columns[cellIndex.colIndex]
                        Text(column.betterRows[cellIndex.rowIndex]).padding(.horizontal)
                            .font(.body).monospacedDigit()
                            .scaledToFit()
                        
                    }
                }
            })
        }
        .background(.white)
        .padding(.horizontal)
        
    }
    var stickyHeaderView: some View {
        VStack(spacing: 10) {
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
                                .padding(.horizontal)
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
    private mutating func getModel(path: String) ->MLModel {
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
        let newModel = model(model: result!, path: path)
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

struct ValuesView_Previews: PreviewProvider {
    static var previews: some View {
        return ValuesView(coreDataML: nil, regressorName: "mllinearRegressor")
    }
}
