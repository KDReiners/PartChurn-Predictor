//
//  ComposerView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.07.22.
//

import SwiftUI

struct ComposerView: View {
    var model: Models
    @State var sourceSelection =  Set<UUID>()
    @State var sourceColumnSelection: Columns?
    @State var targetSelection = Set<UUID>()
    @State var targetColumnSelection: Columns?
    internal var composer: Composer?
    init(model: Models) {
        self.model = model
        self.composer = Composer(model: model)
    }
    var body: some View {
        HStack(spacing: 50) {
            VStack(alignment: .center) {
                Text(model.name ?? "unbekanntes Model")
                    .font(.title)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                Divider()
                HStack(spacing: 50) {
                    VStack(alignment:.leading) {
                        Text("Cognitionsources")
                        List(composer!.cognitionSources, id: \.id, selection: $sourceSelection) { source in
                            Text(source.name!)
                        }
                        ForEach(composer!.cognitionSources.filter { $0.id == sourceSelection.first } , id: \.id) { source in
                            List(source.valueColumns, id: \.self, selection: $sourceColumnSelection) { column in
                                Text(column.name!)
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Cognitiontargets")
                        List(composer!.cognitionObjects, id: \.id, selection: $targetSelection) { target in
                            Text(target.name!)
                        }
                        ForEach(composer!.cognitionObjects.filter { $0.id == targetSelection.first }, id: \.id) { target in
                            List(target.valueColumns, id:\.self, selection: $targetSelection) { column in
                                Text(column.name!)
                            }
                            
                        }
                    }
                }
                ValuesView(mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: composer!.orderedColumns)
            }
        }
    }
}
    
struct ComposerView_Previews: PreviewProvider {
    static var previews: some View {
        ComposerView(model: ModelsModel().items.first!)
    }
}
