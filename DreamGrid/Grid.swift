import SwiftUI

struct GridView: View {
    let grid: GridModel
    let namespace: Namespace.ID
    var onCellTapped: (CellModel) -> Void
    
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(grid.cells) { cellModel in
                CellView(model: cellModel, gridID: grid.id, namespace: namespace, onTapped: {
                    onCellTapped(cellModel)
                })
            }
        }
    }
}
