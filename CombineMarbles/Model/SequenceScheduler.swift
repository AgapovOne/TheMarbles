import Foundation
import Combine

class SequenceScheduler: Scheduler {

    var now: SequenceScheduler.Time = Time(value: 0)
    var minimumTolerance: SequenceScheduler.Time.Stride = 0

    private var scheduled: [ScheduledAction] = []

    struct Time: Comparable {

        private(set) var value: Int64
        var magnitude: UInt32 {
            UInt32(abs(value))
        }

        fileprivate init(value: Int64) {
            self.value = value
        }
    }

    private struct ScheduledAction {
        let uuid: UUID
        let time: Time
        let interval: Int64?
        let action: () -> ()

        init(uuid: UUID = UUID(), time: Time, interval: Int64? = nil, action: @escaping () -> ()) {

            self.uuid = uuid
            self.time = time
            self.interval = interval
            self.action = action
        }
    }

    func schedule(after date: SequenceScheduler.Time, interval: Int64, tolerance: Int64, options: String?, _ action: @escaping () -> Void) -> Cancellable {

        let action = ScheduledAction(time: date, interval: interval, action: action)
        append(action)

        return AnyCancellable({ [weak self] in
            if let index = self?.scheduled.firstIndex(where: { $0.uuid == action.uuid }) {
                self?.scheduled.remove(at: index)
            }
        })
    }

    func schedule(after date: SequenceScheduler.Time, tolerance: Int64, options: String?, _ action: @escaping () -> Void) {
        guard now < date else { return }

        append(ScheduledAction(time: date, action: action))
    }

    func schedule(options: String?, _ action: @escaping () -> Void) {
        append(ScheduledAction(time: now, action: action))
    }

    func start() {
        guard !scheduled.isEmpty else { return }

        let scheduledAction = scheduled.removeFirst()
        now = scheduledAction.time

        scheduledAction.action()

        if let interval = scheduledAction.interval {
            let newAction = ScheduledAction(
                uuid: scheduledAction.uuid,
                time: now.advanced(by: interval),
                interval: scheduledAction.interval,
                action: scheduledAction.action
            )

            append(newAction)
        }

        DispatchQueue.main.async { [weak self] in
            self?.start()
        }
    }

    private func append(_ action: ScheduledAction) {

        scheduled.append(action)
        scheduled.sort { $0.time < $1.time }
    }
}

extension SequenceScheduler.Time: Strideable {

    func distance(to other: SequenceScheduler.Time) -> Int64 {
        return Int64(other.value - value)
    }

    func advanced(by n: Int64) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: value + Int64(n))
    }
}

extension SequenceScheduler.Time: SignedNumeric {

    init(integerLiteral value: Int32) {
        self.init(value: Int64(value))
    }

    init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(value: Int64(source))
    }

    static func + (lhs: SequenceScheduler.Time, rhs: SequenceScheduler.Time) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: lhs.value + rhs.value)
    }

    static func -= (lhs: inout SequenceScheduler.Time, rhs: SequenceScheduler.Time) {
        lhs.value -= rhs.value
    }

    static func += (lhs: inout SequenceScheduler.Time, rhs: SequenceScheduler.Time) {
        lhs.value += rhs.value
    }

    static func * (lhs: SequenceScheduler.Time, rhs: SequenceScheduler.Time) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: lhs.value * rhs.value)
    }

    static func *= (lhs: inout SequenceScheduler.Time, rhs: SequenceScheduler.Time) {
        lhs.value *= rhs.value
    }

    static func - (lhs: SequenceScheduler.Time, rhs: SequenceScheduler.Time) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: lhs.value - rhs.value)
    }
}

extension SequenceScheduler.Time: SchedulerTimeIntervalConvertible {

    static func seconds(_ s: Int) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: Int64(s) * 1000  * 1000 * 1000)
    }

    static func seconds(_ s: Double) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: Int64(s) * 1000  * 1000 * 1000)
    }

    static func milliseconds(_ ms: Int) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: Int64(ms) * 1000 * 1000)
    }

    static func microseconds(_ us: Int) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: Int64(us) * 1000)
    }

    static func nanoseconds(_ ns: Int) -> SequenceScheduler.Time {
        return SequenceScheduler.Time(value: Int64(ns))
    }
}

extension Int64: SchedulerTimeIntervalConvertible {
    public static func seconds(_ s: Int) -> Int64 {
        Int64(s) * 1000  * 1000 * 1000
    }

    public static func seconds(_ s: Double) -> Int64 {
        Int64(s) * 1000  * 1000 * 1000
    }

    public static func milliseconds(_ ms: Int) -> Int64 {
        Int64(ms) * 1000  * 1000
    }

    public static func microseconds(_ us: Int) -> Int64 {
        Int64(us) * 1000
    }

    public static func nanoseconds(_ ns: Int) -> Int64 {
        Int64(ns)
    }
}
