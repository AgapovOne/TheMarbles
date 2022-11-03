import SwiftUI
import Combine

class MarbleViewState: ObservableObject {

    private var generator: ([SequancePublisher], SequnceScheduler) -> SequanceEqperimentRunner
    private var cancellable = Set<AnyCancellable>()

    @Published var input: [[TimedEvent]] {
        didSet {
            update()
        }
    }

    @Published var output: [TimedEvent] = []

    init(input: [[TimedEvent]], generator: @escaping ([SequancePublisher], SequnceScheduler) -> SequanceEqperimentRunner) {
        self.input = input
        self.generator = generator
    }

    func update() {

        let scheduler = SequnceScheduler()

        generator(self.input.map { SequancePublisher(events: $0, scheduler: scheduler) }, scheduler)
            .run(scheduler: scheduler)
            .receive(on: RunLoop.main)
            .assign(to: \.output, on: self)
            .store(in: &cancellable)
    }
}

extension TupleOperator {

    var state: MarbleViewState {

        return MarbleViewState(
            input: [input1, input2],
            generator: { publisher, _ in

                let combined = self.operation(publisher[0], publisher[1])
                return SequanceExperiment(publisher: combined)
            }
        )
    }
}

extension SingleOperator {

    var state: MarbleViewState {

        return MarbleViewState(
            input: [input],
            generator: { publisher, scheduler in
                let combined = self.operation(publisher[0], scheduler)
                return SequanceExperiment(publisher: combined)
            }
        )
    }
}

struct MarblesScreen: View {

    @ObservedObject var state: MarbleViewState
    
    let operation: Operator

    init(operation: Operator) {
        self.operation = operation
        state = operation.state
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 24) {
                ForEach(0..<state.input.count) {
                    MarbleLane(positions: self.$state.input[$0], isDraggable: true)
                        .frame(height: 44)
                }
            }
            HStack {
                Text("move around")
                    .font(.footnote)
                Image(systemName: "hand.point.up.left")
            }
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Text(operation.description)
                .font(.body.monospaced())
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            MarbleLane(positions: $state.output, isDraggable: false)
                .frame(height: 44)

            DocumentationLink(
                name: self.operation.name,
                url: self.operation.documentationURL
            )
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(.vertical, 36)
        .padding(.horizontal)
        #if os(iOS)
        .navigationBarTitle(operation.name)
        #endif
        .onAppear { self.state.update() }
    }
}

//#if DEBUG
//struct MarblesScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        MarblesScreen(operation: )
//    }
//}
//#endif
