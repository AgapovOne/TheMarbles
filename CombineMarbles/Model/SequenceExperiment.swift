import Foundation
import Combine

protocol SequenceExperimentRunner {
    func run(scheduler: SequenceScheduler) -> Future<[TimedEvent], Never>
}

struct SequenceExperiment<P: Publisher>: SequenceExperimentRunner where P.Failure == FailureString, P.Output == String {

    let publisher: P

    func run(scheduler: SequenceScheduler) -> Future<[TimedEvent], Never>  {

        return Future { callback in
            var cancellable: Cancellable?
            var collected = [TimedEvent]()

            cancellable = self.publisher
                .sink(receiveCompletion: { result in
                    let time = Int(scheduler.now.value / 1000 / 1000)
                    switch result {
                    case .finished:
                        collected.append(.finished(time))
                    case let .failure(failure):
                        collected.append(.error(time, failure.content))
                    }

                    callback(.success(collected))

                    if cancellable != nil {
                        cancellable = nil
                    }
                }, receiveValue: {
                    collected.append(.next(Int(scheduler.now.value / 1000 / 1000), $0))
                })

            scheduler.start()
        }
    }
}
