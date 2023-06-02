import SwiftUI

struct GridItemView: View {
    let element: Int
    
    var body: some View {
        VStack {
            Text("Element: \(element)")
            List(0..<element, id: \.self) { index in
                Text("Item \(index)")
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color.gray)
        .cornerRadius(8)
    }
}
