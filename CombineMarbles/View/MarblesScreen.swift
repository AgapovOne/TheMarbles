import SwiftUI
import Combine

class MarbleViewState: ObservableObject {
    struct TimedEvents: Identifiable {
        let id: Int
        let events: [TimedEvent]
    }

    private var generator: ([SequencePublisher], SequenceScheduler) -> SequenceExperimentRunner
    private var cancellable = Set<AnyCancellable>()

    @Published var input: [TimedEvents] {
        didSet {
            update()
        }
    }

    @Published var output: [TimedEvent] = []

    init(
        input: [TimedEvents],
        generator: @escaping ([SequencePublisher], SequenceScheduler) -> SequenceExperimentRunner
    ) {
        self.input = input
        self.generator = generator
        update()
    }

    func update() {

        let scheduler = SequenceScheduler()

        generator(self.input.map { SequencePublisher(events: $0.events, scheduler: scheduler) }, scheduler)
            .run(scheduler: scheduler)
            .receive(on: RunLoop.main)
            .assign(to: \.output, on: self)
            .store(in: &cancellable)
    }
}

extension TupleOperator {

    var state: MarbleViewState {

        return MarbleViewState(
            input: [.init(id: 0, events: input1), .init(id: 1, events: input2)],
            generator: { publisher, _ in

                let combined = self.operation(publisher[0], publisher[1])
                return SequenceExperiment(publisher: combined)
            }
        )
    }
}

extension SingleOperator {

    var state: MarbleViewState {

        return MarbleViewState(
            input: [.init(id: 0, events: input)],
            generator: { publisher, scheduler in
                let combined = self.operation(publisher[0], scheduler)
                return SequenceExperiment(publisher: combined)
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
                ForEach(state.input) { events in
                    MarbleLane(
                        positions: .init(
                            get: { events.events },
                            set: { newValue in
                                state.input = state.input.map {
                                    .init(
                                        id: $0.id,
                                        events: $0.id == events.id
                                        ? newValue
                                        : $0.events
                                    )
                                }
                            }
                        ),
                        isDraggable: true
                    )
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
