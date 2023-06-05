import SwiftUI
import CreateML
struct GridItemView: View {
    var sequence: MLDataColumn<MLDataValue.SequenceType>?
    var rowIndex: Int?
    var body: some View {
        HStack {
            if let values = sequence?.extractValues(rowIndex: rowIndex!) {
                ForEach(values, id: \.self) { value in
                    Text(value.convertedToStringValue)
                    Spacer()
                }
            }
        } .background(BaseServices.isEvenRow(rowIndex!) ? Color.white: Color.gray.opacity(0.1))
    }
}

extension MLDataColumn where Element == MLDataValue.SequenceType {
    func extractValues(rowIndex: Int) -> Array<PackedValue> {
        var result: [PackedValue] = []
        let base = self.element(at: rowIndex)
        for i in 0..<base!.count {
            let newPackedElement = PackedValue(from:base![i])!
            result.append(newPackedElement)
        }
        return result
    }
}

