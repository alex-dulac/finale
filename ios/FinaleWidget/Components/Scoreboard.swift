import SwiftUI

struct ScoreTileModel {
    let title: String
    let value: Int?
    let icon: String
}

enum ScoreboardAlignment {
    case vertical
    case horizontal
}

prefix func !(alignment: ScoreboardAlignment) -> ScoreboardAlignment {
    switch alignment {
    case .vertical: return .horizontal
    case .horizontal: return .vertical
    }
}

struct Scoreboard: View {
    let alignment: ScoreboardAlignment
    let tiles: [ScoreTileModel]
    
    var body: some View {
        Stack(alignment: alignment) {
            ForEach(Array(tiles.enumerated()), id: \.element.title) { (index, model) in
                ScoreTile(model: model, alignment: alignment)
                if (alignment == .horizontal && index < tiles.count - 1) {
                    Divider()
                }
            }
        }
        .fixedSize()
    }
}

private struct ScoreTileVertical: View {
    let model: ScoreTileModel
    
    var body: some View {
        VStack {
            Image(model.icon)
                .resizable()
                .frame(width: 30, height: 30)
                .colorMultiply(Color("AccentColor"))
            Text(model.title)
                .foregroundColor(Color("AccentColor"))
                .bold()
            Text(model.value != nil ? numberFormatter.string(from: NSNumber(value: model.value!))! : "---")
                .foregroundColor(Color("AccentColor"))
                .bold()
        }
    }
}

private struct ScoreTileHorizontal: View {
    let model: ScoreTileModel
    
    var body: some View {
        HStack {
            Text(model.value != nil ? numberFormatter.string(from: NSNumber(value: model.value!))! : "---")
                .foregroundColor(Color("AccentColor"))
                .bold()
            Image(model.icon)
                .resizable()
                .frame(width: 20, height: 20)
                .colorMultiply(Color("AccentColor"))
        }
    }
}

private struct ScoreTile : View {
    let model: ScoreTileModel
    let alignment: ScoreboardAlignment
    
    var body: some View {
        switch (alignment) {
        case .vertical: ScoreTileHorizontal(model: model)
        case .horizontal: ScoreTileVertical(model: model)
        }
    }
}

private struct Stack<Content> : View where Content : View {
    let alignment: ScoreboardAlignment
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        switch (alignment) {
        case .vertical: VStack(content: content)
        case .horizontal: HStack(content: content)
        }
    }
}
