import Foundation
import Combine

protocol Operator {
    var name: String { get }
    var description: String { get }
    var documentationURL: String { get }
    var state: MarbleViewState { get }
}

struct TupleOperator<Input>: Operator {

    let name: String
    let description: String
    let documentationURL: String

    let operation: (SequencePublisher, SequencePublisher) -> AnyPublisher<String, FailureString>

    let input1: [TimedEvent]
    let input2: [TimedEvent]
}

struct SingleOperator<Input>: Operator {
    let name: String
    let description: String
    let documentationURL: String

    let operation: (SequencePublisher, SequenceScheduler) -> AnyPublisher<String, FailureString>

    let input: [TimedEvent]

    init(name: String, description: String, documentationURL: String, operation: @escaping (SequencePublisher, SequenceScheduler) -> AnyPublisher<String, FailureString>, input: [TimedEvent]) {

        self.name = name
        self.description = description
        self.documentationURL = documentationURL
        self.operation = operation
        self.input = input
    }
}
