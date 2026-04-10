@MainActor
class ViewModel {
    func updateUI() {}

    func run(completion: @Sendable () -> Void) {}

    func setup() {
        run {
            updateUI() // error: main actor-isolated method in nonisolated closure
        }
    }
}
