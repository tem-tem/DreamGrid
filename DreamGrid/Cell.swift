import SwiftUI

struct CellView: View {
    let model: CellModel
    let gridID: UUID
    let namespace: Namespace.ID
    var onTapped: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(backgroundColor)
//                .shadow(color: .black.opacity(0.2), radius: 0, x: 2, y: 2)

            contentView
                .padding(8)
                .foregroundColor(.white)
                .contentTransition(.symbolEffect(.replace))
                .id(model.content + "\(model.progress?.completed ?? 0)")
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            onTapped()
        }
        .animation(.easeInOut(duration: 0.3), value: model.isComplete)
        .matchedGeometryEffect(id: model.type == .link ? model.destinationGridID : model.type == .categoryTitle ? gridID : UUID() , in: namespace)
    }

    @ViewBuilder
    private var contentView: some View {
        switch model.type {
        case .link:
            VStack {
                Text(model.content)
                    .font(.headline)
                    .fontWeight(.bold)
                if let progress = model.progress, progress.total > 0 {
                    Text("\(progress.completed) / \(progress.total)")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
            }
            .minimumScaleFactor(0.5)
            
        case .categoryTitle:
            Text(model.content)
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5)
            
        case .actionItem:
            VStack {
                Text(model.content)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.5)
                    .lineLimit(3)
                
                Spacer()
                
                if !model.content.isEmpty {
                    Image(systemName: model.isComplete == true ? "checkmark.square" : "square")
                        .font(.title2)
                }
            }
        }
    }

    private var backgroundColor: Color {
        switch model.type {
        case .link:
            return .purple
        case .categoryTitle:
            return .gray
        case .actionItem:
            if model.content.isEmpty { return Color.gray.opacity(0.3) }
            return model.isComplete == true ? .green : .blue
        }
    }
}
