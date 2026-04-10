// MARK: - SE-0430: `sending` parameter and result values
// https://github.com/apple/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md
//
// `sending` enables safely passing non-Sendable values across isolation boundaries.
// It guarantees that arguments and return values are in a "disconnected region".

// MARK: - Basic NonSendable type

// MARK: - 1. Basic `sending` parameter

/// Basic pattern: passing a non-Sendable value to an actor via `sending` parameter.
/// The `sending` parameter requires the argument to be in a disconnected region.
/// After the call, the caller can no longer use the argument.
/// - Note: As of Swift 6.2, without `sending` still allows region-based isolation to work.
@MainActor
private func acceptOnMainActor(_ ns: sending NonSendable) {
    // ns can be safely used on MainActor
    print("Received on MainActor: \(ns.value)")
}

/// Without `sending` parameter, NonSendable cannot be passed (but SE-0414 implicit sending works)
private func trySendWithoutSending() async {
    let ns = NonSendable(value: 42)

    // ✅ OK: ns is in disconnected region (freshly created)
    await acceptOnMainActor(ns)

    // ❌ Error: 'ns' has already been sent and cannot be used
    // print(ns.value)  // error: 'ns' used after being sent
}

// MARK: - 2. Basic `sending` result

/// A `sending` return value guarantees the returned value is in a disconnected region.
/// This allows non-Sendable values to be returned across isolation boundaries.
@MainActor
private struct SendingFactory {
    let sharedNS: NonSendable = NonSendable() // Not in disconnected region.

    /// ✅ OK: Returns a freshly created value (disconnected region)
    func createNew() -> sending NonSendable {
        return NonSendable(value: 100)
    }

//    /// ❌ Error: actor-isolated values cannot be returned as sending
//     func returnShared() -> sending NonSendable {
//         return sharedNS  // error: main actor-isolated 'self.sharedNS' is returned as a 'sending' result
//     }
}

private func useSendingResult(factory: SendingFactory) async {
    // A sending return value is treated as being in disconnected region at the call site
    let ns = await factory.createNew()

    // Since it's disconnected, it can be sent to another actor
    await acceptOnMainActor(ns)

    // print(ns)
}

// MARK: - 3. Actor initializer and sending

/// Actor initializer parameters are implicitly treated as `sending`.
/// This allows initializing actor state with non-Sendable values.
private actor SendingDemoActor {
    let ns: NonSendable

    init(ns: NonSendable) {
        // ns is sent to the actor's isolation region
        self.ns = ns

        print(self.ns)
        print(self.ns)
        print(self)
        // print(self.ns) Sync-init isolation decay
    }

    func getValue() -> Int {
        ns.value
    }
}

private func demonstrateActorInit() async {
    let ns = NonSendable(value: 999)

    // ✅ OK: ns is in disconnected region
    let actor = SendingDemoActor(ns: ns)

    // ❌ Error: ns has already been sent to the actor
    // print(ns)  // error: 'ns' used after being sent

    print(await actor.getValue())
}

// MARK: - 4. sending and non-Sendable region merge

/// Disconnected values can be merged with other disconnected values.
/// After merging, they remain in disconnected region, so they can still be sent.
/// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md
private func demonstrateRegionMerge(ns0: NonSendable = .init()) async {
    // Both are in disconnected region
    let ns1 = NonSendable(value: 1)
    let ns2 = NonSendable(value: 2)

    // Even when grouped into a tuple, both are disconnected so the whole tuple is disconnected
    let tuple = (ns1, ns2)

    // NOTE: `ns0` is NOT disconnected region if passed from outside.
    // ❌ ERROR: Sending 'tuple.0' risks causing data races
//    let tuple = (ns1, ns0)

    // ✅ OK: the entire tuple can be sent
    await sendTupleToMainActor(tuple)

    //print(ns1)
}

@MainActor
private func sendTupleToMainActor(_ tuple: sending (NonSendable, NonSendable)) {
    print("Received tuple: (\(tuple.0.value), \(tuple.1.value))")
}

// MARK: - 5. Protocol and sending

/// Contravariant/covariant behavior of `sending` in protocol requirements
private protocol SendingDataProvider {
    /// Protocol method with `sending` parameter
    func store(_ data: sending NonSendable)

    /// Protocol method with `sending` return value
    func load() -> sending NonSendable
}

/// A protocol requirement with `sending` parameter can be satisfied by a non-sending implementation (contravariant)
private final class LocalSendingProvider: SendingDataProvider {
    private var storage: NonSendable?

    // ✅ OK: implements sending parameter requirement with a normal parameter
    func store(_ data: NonSendable) {
        storage = data
    }

    // A sending return value requirement must be implemented with a sending return value
    func load() -> sending NonSendable {
        return NonSendable()  // Create and return a fresh instance
    }
}

// MARK: - 6. CheckedContinuation and sending (practical example)

/// `withCheckedContinuation`'s `resume(returning:)` takes a `sending` parameter.
/// This allows non-Sendable values to be safely returned via continuation.
private func fetchNonSendableData() async -> NonSendable {
    await withCheckedContinuation { continuation in
        // Simulate async operation
        Task {
            let result = NonSendable(value: 42)

            // ✅ OK: result is in disconnected region
            continuation.resume(returning: result)

            // ❌ Error: cannot send result consecutively
//            for _ in 0 ..< 1 {
//                continuation.resume(returning: result)
//            }

            // ❌ Error: result has already been sent
            // print(result.value)  // error: 'result' used after being sent
        }
    }
}

// MARK: - 7. Function types and sending (subtyping)

/// `sending` affects function type subtyping
///
/// Summary of `sending` transitive conversion rules:
///
/// ## Parameter Position (Contravariant)
/// ```
/// (T) -> R  CAN convert to  (sending T) -> R
/// (sending T) -> R  CANNOT convert to  (T) -> R
/// ```
///
/// ## Result Position (Covariant)
/// ```
/// () -> sending T  CAN convert to  () -> T
/// () -> T  CANNOT convert to  () -> sending T
/// ```
private func demonstrateFunctionSubtyping() {
    // Parameter: contravariant (sending → normal is OK, reverse is NG)
    let f1: (sending NonSendable) -> Void = { _ in }
    let f2: (NonSendable) -> Void = { _ in }

    let _: (sending NonSendable) -> Void = f1  // ✅ OK
    let _: (sending NonSendable) -> Void = f2  // ✅ OK
    // let _: (NonSendable) -> Void = f1       // ❌ Error

    // Result: covariant (normal → sending is NG, reverse is OK)
    let g1: () -> sending NonSendable = { NonSendable() }
    let g2: () -> NonSendable = { NonSendable() }

    let _: () -> sending NonSendable = g1  // ✅ OK
    // let _: () -> sending NonSendable = g2  // ❌ Error
    let _: () -> NonSendable = g1  // ✅ OK
    _ = g2  // suppress warning
}

// MARK: - 8. consuming sending (combining with ownership)

/// `sending` and `consuming` are orthogonal concepts:
/// - `sending`: Region isolation (the value is sent to another isolation region)
/// - `consuming`: Ownership (ownership is transferred to the function)
///
/// **Important**: For Copyable types (e.g. class), `sending` alone allows reassignment.
/// `consuming sending` is needed for **~Copyable types**.
///
/// For ~Copyable types, `sending` alone is insufficient — `consuming` is required:
/// - `borrowing sending`: ❌ Not allowed
/// - `consuming sending`: ✅ Takes ownership and sends
/// - `inout sending`: ❌ Not allowed (inout writes back to the caller)

/// Copyable type: reassignment is possible with `sending` alone
private func processWithSending(_ x: sending NonSendable) -> sending NonSendable {
    print("sending: \(x.value)")
    // return x // OK

    x = NonSendable(value: x.value + 100)  // ✅ OK: Copyable types can be reassigned
    return x
}

// MARK: consuming sending for ~Copyable types

/// ~Copyable type: `sending` alone is an error (ownership specifier required)
// func processNonCopyable(_ x: sending NonCopyable) { }
// ❌ Error: parameter of noncopyable type must specify ownership

/// ~Copyable type: `consuming sending` takes ownership
private func processNonCopyableConsuming(_ x: consuming sending NonCopyable) {
    print("consuming sending ~Copyable: \(x.value)")
    x.value = 100
    // Ownership of x is taken, so it is destroyed when the function returns
}

// /// ~Copyable type: borrowing sending is not allowed
// func processNonCopyableBorrowing(_ x: borrowing sending NonCopyable) { }
// ❌ Error: 'sending' cannot be used together with 'borrowing'

/// consuming sending demo
private func demonstrateConsumingSending() async {
    print("--- consuming sending demo ---")

    // 1. Copyable type: reassignment possible with sending alone
    let ns1 = NonSendable(value: 10)
    let result1 = processWithSending(ns1)
    print("result1: \(result1.value)")  // 110
    // ns1 has been sent and cannot be used
    // print(ns1.value)  // ❌ Error

    // 2. ~Copyable type: consuming sending
    let resource1 = NonCopyable(value: 42)
    processNonCopyableConsuming(resource1)
    // resource1 has been consumed and cannot be used
    // print(resource1.value)  // ❌ Error

    print("--- demo complete ---")
}

// MARK: - 9. Task and sending (practical example)

/// The Task creation API uses `sending` parameters
private func demonstrateTaskCreation() {
    let ns = NonSendable(value: 123)

    // When a non-Sendable value is captured in a Task closure,
    // the value is treated as "sent" to the Task
    Task {
        // Use ns inside the Task
        print(ns.value)
    }

    // ❌ Error: ns has been sent to the Task
    // print(ns.value)
}

// MARK: - 10. AsyncStream and sending

/// `AsyncStream.Continuation.yield` also takes a `sending` parameter
private func demonstrateAsyncStream() -> AsyncStream<NonSendable> {
    AsyncStream { continuation in
        Task {
            for i in 0..<3 {
                let item = NonSendable(value: i)
                // ✅ OK: item is in disconnected region
                continuation.yield(item)
                // item cannot be used after yield
                // print(item)
            }
            continuation.finish()
        }
    }
}

// MARK: - Demo runner

private func runSendingDemo() async {
    print("=== sending Demo ===\n")

    print("1. Basic sending parameter:")
    await trySendWithoutSending()

    print("\n2. Actor initialization:")
    await demonstrateActorInit()

    print("\n3. Region merge:")
    await demonstrateRegionMerge()

    print("\n4. CheckedContinuation:")
    let data = await fetchNonSendableData()
    print("Fetched: \(data.value)")

    print("\n5. AsyncStream:")
    for await item in demonstrateAsyncStream() {
        print("Stream item: \(item.value)")
    }

    print("\n=== Demo Complete ===")
}
