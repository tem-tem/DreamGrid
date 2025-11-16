import SwiftUI

@main
struct GridNavigatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var dataStore: GridDataStore
    @State private var navigationStack: [UUID] = []
    @Namespace private var gridAnimation
    
    private var activeGridID: UUID {
        navigationStack.last!
    }
    
    private var activeGrid: GridModel {
        dataStore.gridStore[activeGridID]!
    }
    
    init() {
        let store = GridDataStore()
        _dataStore = StateObject(wrappedValue: store)
        _navigationStack = State(initialValue: [store.homeGridID])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Dream Grid Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Current: \(activeGrid.title)")
                    .font(.headline)
                    .contentTransition(.opacity)
            }
            .padding()
            Spacer()
            ZStack {
                ForEach(navigationStack, id: \.self) { gridID in
                    let grid = dataStore.gridStore[gridID]!
                    if gridID == activeGridID {
                        GridView(grid: grid, namespace: gridAnimation, onCellTapped: handleCellTap)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                }
            }
        }
        .padding()
    }

    private func goBack() {
        if navigationStack.count > 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                navigationStack.removeLast()
            }
        }
    }
    
    private func handleCellTap(_ cell: CellModel) {
        switch cell.type {
            
        case .link:
            if let destID = cell.destinationGridID {
                withAnimation(.snappy(duration: 0.3, extraBounce: 0.1)) {
                    navigationStack.append(destID)
                }
            }
            
        case .actionItem:
            if !cell.content.isEmpty {
                dataStore.toggleActionItem(gridID: activeGridID, itemID: cell.id)
            }
            
        case .categoryTitle:
            if activeGridID != dataStore.homeGridID {
                goBack()
            }
        }
    }
}


#Preview {
    ContentView()
}
