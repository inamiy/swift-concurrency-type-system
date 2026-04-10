// Advanced Isolation Patterns for SIL Exploration
// Covers: @isolated(any), sending, @concurrent, isolated parameter, #isolation

// MARK: - Supporting Types

class NonSendable {
    var value: Int = 0
    init(value: Int = 0) { self.value = value }
}

struct NonCopyable: ~Copyable {
    var value: Int
    init(value: Int = 0) { self.value = value }
}

// MARK: - 1. @isolated(any) - SE-0431

/// Function that takes @isolated(any) closure
func runIsolatedAny(_ f: @escaping @isolated(any) () async -> Void) async {
    // Can access isolation at runtime
    let iso = f.isolation
    _ = iso
    await f()
}

/// Calling with MainActor-isolated closure
@MainActor
func callWithMainActorClosure() async {
    await runIsolatedAny { @MainActor in
        print("on MainActor")
    }
}

// MARK: - 2. sending parameter - SE-0430

/// sending parameter: value must be in disconnected region
@MainActor
func acceptSending(_ ns: sending NonSendable) {
    print(ns.value)
}

/// sending result: returned value is in disconnected region
func produceSending() -> sending NonSendable {
    return NonSendable(value: 42)
}

/// Demo of sending
func sendingDemo() async {
    let ns = NonSendable(value: 10)
    await acceptSending(ns)
    // ns cannot be used after sending
}

// MARK: - 3. @concurrent - Swift 6.2

/// @concurrent: explicitly non-isolated async function
@concurrent
func concurrentWork() async -> Int {
    return 42
}

/// Calling @concurrent from MainActor
@MainActor
func callConcurrentFromMainActor() async {
    let result = await concurrentWork()
    print(result)
}

// MARK: - 4. isolated parameter

/// isolated parameter: function inherits caller's isolation
func withIsolation<T>(
    _ isolation: isolated (any Actor)?,
    _ body: () throws -> T
) rethrows -> T {
    try body()
}

/// #isolation: captures current isolation
@MainActor
func useIsolationMacro() {
    withIsolation(#isolation) {
        print("inherited isolation")
    }
}

// MARK: - 5. Actor with sending parameter

actor DataStore {
    var data: NonSendable?

    // Actor method params are implicitly sending
    func store(_ ns: NonSendable) {
        self.data = ns
    }

    func load() -> NonSendable? {
        return data
    }
}

// MARK: - 6. consuming sending (~Copyable)

func consumeSending(_ x: consuming sending NonCopyable) {
    print(x.value)
    // x is consumed here
}

// MARK: - 7. nonisolated(unsafe)

class UnsafeShared {
    nonisolated(unsafe) static var shared: NonSendable = NonSendable()
}
