import Foundation
import SwiftUI

struct ArrowShape: Shape {

    let headLength: CGFloat = 12
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - headLength, y: rect.maxY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - headLength, y: rect.minY))
        }
    }
}

struct MarbleLane: View {

    @Binding var positions: [TimedEvent]
    func positions(excludingIndex: Int) -> [TimedEvent] {
        var modifiedPositions = positions
        modifiedPositions.remove(at: excludingIndex)
        modifiedPositions.removeAll(where: { $0.type != .next })
        return modifiedPositions
    }

    let isDraggable: Bool

    var body: some View {
        ZStack {
            GeometryReader { proxy in

                ArrowShape()
                    .stroke(Color.arrowColor)
                    .frame(width: proxy.size.width, height: 20)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                ForEach(self.positions) { element in
                    element.view
                        .position(x: proxy.denormalize(x: element.position), y: proxy.size.height / 2)
                        .gesture(DragGesture().onChanged {
                            guard self.isDraggable else { return }
                            guard let index = self.positions.firstIndex(of: element) else { return }
                            let newPosition = proxy.normalize(x: $0.location.x)

                            let hasNearby = positions(excludingIndex: index).contains(where: {
                                ($0.position - 0.05...$0.position + 0.05).contains(newPosition)
                            })
                            if !hasNearby {
                                self.positions[index].position = newPosition
                            }
                        })
                        .frame(width: 50, height: 50, alignment: .center)
                        .zIndex(element.zIndex)
                }
            }
        }
    }
}

private extension TimedEvent {

    var view: some View {
        switch type {
        case .next:
            return AnyView(Marble(content: content))
        case .finished:
            return AnyView(Finished())
        case .error:
            return AnyView(ErrorView())
        }
    }

    var zIndex: Double {
        switch type {
        case .next:
            return 1
        case .finished, .error:
            return 0
        }
    }
}

private extension GeometryProxy {

    func normalize(x: CGFloat) -> Double {
        let width = frame(in: .global).width
        return Double(x / width)
    }

    func denormalize(x: Double) -> CGFloat {
        let width = frame(in: .global).width
        return CGFloat(x) * width
    }
}

private extension TimedEvent {

    var position: Double {
        get { Double(timeInterval) / 100 }
        set { timeInterval = Int(newValue * 100) }
    }
}
