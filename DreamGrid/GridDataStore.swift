import Foundation
import Combine

struct GridModel: Identifiable, Equatable {
    let id: UUID
    var title: String
    var cells: [CellModel] = []

    init(id: UUID, title: String, cells: [CellModel]) {
        self.id = id
        self.title = title
        self.cells = cells
    }
}

struct CellModel: Identifiable, Equatable {
    let id: Int
    let gridID: UUID
    var content: String
    var type: CellType
    var destinationGridID: UUID?
    var isComplete: Bool?
    var progress: (completed: Int, total: Int)?

    enum CellType {
        case link
        case categoryTitle
        case actionItem
    }
    
    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.content == rhs.content &&
               lhs.type == rhs.type &&
               lhs.destinationGridID == rhs.destinationGridID &&
               lhs.isComplete == rhs.isComplete &&
               lhs.progress?.completed == rhs.progress?.completed &&
               lhs.progress?.total == rhs.progress?.total
    }
}


class GridDataStore: ObservableObject {
    
    @Published var gridStore: [UUID: GridModel] = [:]
    
    var homeGridID: UUID
    
    private static let outerCellIndices = [0, 1, 2, 3, 5, 6, 7, 8]
    
    init() {
        let dreamBoardTitle = "Dream Board"
        self.homeGridID = UUID()
        
        let categoryData = [
            (title: "Travel",   items: ["Plan Japan Trip", "Visit National Parks", "Renew Passport", "Book Paris Flights"]),
            (title: "Health",   items: ["Run 5k", "Drink 8 glasses water", "Meal Prep", "Sleep 8 hours", "Meditate"]),
            (title: "Career",   items: ["Update Resume", "Network", "Get Cert"]),
            (title: "Projects", items: ["Build App", "Woodworking"]),
            (title: "Learning", items: ["SwiftUI", "History"]),
            (title: "Social",   items: ["Call Mom"]),
            (title: "Finance",  items: ["Save $1k", "Check Stocks"]),
            (title: "Home",     items: ["Fix Sink", "Declutter"])
        ]
        
        var localGridStore = [UUID: GridModel]()
        
        var categoryGrids: [GridModel] = []
        for data in categoryData {
            let (grid, _) = createCategoryGrid(data.title, items: data.items)
            categoryGrids.append(grid)
        }
        
        var homeCells = (0...8).map { CellModel(id: $0, gridID: homeGridID, content: "", type: .actionItem) }
        homeCells[4] = CellModel(id: 4, gridID: homeGridID, content: dreamBoardTitle, type: .categoryTitle)
        
        for (gridIndex, cellIndex) in Self.outerCellIndices.enumerated() {
            if gridIndex < categoryGrids.count {
                let categoryGrid = categoryGrids[gridIndex]
                homeCells[cellIndex] = CellModel(id: cellIndex,
                                                 gridID: homeGridID,
                                                 content: categoryGrid.title,
                                                 type: .link,
                                                 destinationGridID: categoryGrid.id,
                                                 progress: (0, 0))
            }
        }
        
        var homeGrid = GridModel(id: self.homeGridID, title: dreamBoardTitle, cells: homeCells)
        
        for grid in categoryGrids {
            localGridStore[grid.id] = grid
        }
        
        for grid in categoryGrids {
            guard let categoryGrid = localGridStore[grid.id],
                  let homeLinkIndex = homeGrid.cells.firstIndex(where: { $0.destinationGridID == grid.id })
            else { continue }
            
            let (completed, total) = Self.calculateGridProgress(grid: categoryGrid)
            homeGrid.cells[homeLinkIndex].progress = (completed, total)
        }
        
        localGridStore[self.homeGridID] = homeGrid

        self.gridStore = localGridStore
    }
    
    private init(empty: Bool) {
        self.homeGridID = UUID()
    }
    
    private func createCategoryGrid(_ title: String, items: [String]) -> (GridModel, UUID) {
        let id = UUID()
        var cells = (0...8).map { CellModel(id: $0, gridID: id, content: "", type: .actionItem) }
        
        cells[4] = CellModel(id: 4, gridID: id, content: title, type: .categoryTitle)
        
        for (itemIndex, cellIndex) in Self.outerCellIndices.enumerated() {
            if itemIndex < items.count {
                let isComplete = (itemIndex == 0 && !items.isEmpty)
                cells[cellIndex] = CellModel(id: cellIndex, gridID: id, content: items[itemIndex], type: .actionItem, isComplete: isComplete)
            }
        }
        
        let grid = GridModel(id: id, title: title, cells: cells)
        return (grid, id)
    }
    
    func toggleActionItem(gridID: UUID, itemID: Int) {
        var store = self.gridStore
        
        guard var categoryGrid = store[gridID],
              let itemIndex = categoryGrid.cells.firstIndex(where: { $0.id == itemID && $0.type == .actionItem }),
              var homeGrid = store[homeGridID],
              let homeLinkIndex = homeGrid.cells.firstIndex(where: { $0.destinationGridID == gridID })
        else {
            guard var grid = gridStore[gridID],
                  let itemIndex = grid.cells.firstIndex(where: { $0.id == itemID && $0.type == .actionItem })
            else { return }
            
            grid.cells[itemIndex].isComplete?.toggle()
            gridStore[gridID] = grid
            return
        }
        
        categoryGrid.cells[itemIndex].isComplete?.toggle()
        
        let (completed, total) = Self.calculateGridProgress(grid: categoryGrid)
        
        homeGrid.cells[homeLinkIndex].progress = (completed, total)
        
        store[gridID] = categoryGrid
        store[homeGridID] = homeGrid
        
        self.gridStore = store
    }
    
    public static func createDummyStore(levels: Int) -> GridDataStore {
        let store = GridDataStore(empty: true)
        var gridDict: [UUID: GridModel] = [:]
        
        let rootGrid = createRecursiveGrid(
            title: "Grid 0",
            level: 0,
            maxLevels: levels,
            store: &gridDict
        )
        
        store.gridStore = gridDict
        store.gridStore[rootGrid.id]?.title = "Home"
        store.gridStore[rootGrid.id]?.cells[4].content = "Home"
        store.homeGridID = rootGrid.id
        
        return store
    }
    
    private static func createRecursiveGrid(title: String, level: Int, maxLevels: Int, store: inout [UUID: GridModel]) -> GridModel {
        let id = UUID()
        var cells = (0...8).map { CellModel(id: $0, gridID: id, content: "", type: .actionItem) }
        
        cells[4] = CellModel(id: 4, gridID: id, content: title, type: .categoryTitle)
        
        if level >= maxLevels {
            for (i, cellIndex) in outerCellIndices.enumerated() {
                let itemTitle = "\(title) - Item \(i + 1)"
                let isComplete = (i == 0)
                cells[cellIndex] = CellModel(
                    id: cellIndex,
                    gridID: id,
                    content: itemTitle,
                    type: .actionItem,
                    isComplete: isComplete
                )
            }
        } else {
            for (i, cellIndex) in outerCellIndices.enumerated() {
                let childTitle = "\(title).\(i + 1)"
                
                let childGrid = createRecursiveGrid(
                    title: childTitle,
                    level: level + 1,
                    maxLevels: maxLevels,
                    store: &store
                )
                
                let (childCompleted, childTotal) = calculateGridProgress(grid: childGrid)
                
                cells[cellIndex] = CellModel(
                    id: cellIndex,
                    gridID: id,
                    content: childGrid.title,
                    type: .link,
                    destinationGridID: childGrid.id,
                    progress: (childCompleted, childTotal)
                )
            }
        }
        
        let grid = GridModel(id: id, title: title, cells: cells)
        store[id] = grid
        return grid
    }
    
    private static func calculateGridProgress(grid: GridModel) -> (Int, Int) {
        let actionItems = grid.cells.filter { $0.type == .actionItem && !$0.content.isEmpty }
        let completed = actionItems.filter { $0.isComplete == true }.count
        let total = actionItems.count
        return (completed, total)
    }
}
