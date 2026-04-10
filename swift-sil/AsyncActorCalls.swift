// Async Actor Calls - to see hop_to_executor

@MainActor
func mainActorWork() -> Int {
    return 42
}

// Non-isolated async function calling MainActor function
func callFromNonIsolated() async -> Int {
    // This should generate hop_to_executor
    await mainActorWork()
}

actor Counter {
    var value = 0

    func increment() -> Int {
        value += 1
        return value
    }
}

// Calling actor method from outside
func useCounter(_ counter: Counter) async -> Int {
    await counter.increment()
}

// Cross-actor call
actor OtherActor {
    let counter: Counter

    init(counter: Counter) {
        self.counter = counter
    }

    func callCounter() async -> Int {
        // Cross-actor call
        await counter.increment()
    }
}
