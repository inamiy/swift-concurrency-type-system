// Region Merge Example: Same Isolation Call
// Within same isolation, regions are merged but not consumed.
//
// Actual behavior in Swift 6 (verified via `swift build` / Xcode):
// - Same isolation: merge only, reusable
// - Cross isolation: consumed via implicit `sending` (SE-0414)

@MainActor private func process(_ ns: NonSendable) {
    ns.value += 1
}

// =============================================================================
// MARK: - Example 1: Same Isolation (Region Merge)
// =============================================================================
//
// Same-isolation call:
// - x's region merges from disconnected → MainActor
// - x is not consumed (remains in the output context)
// - x is still accessible after the call

@MainActor private func example1_sameIsolation() async {
    let x = NonSendable()       // x : NonSendable at disconnected
    // Γ = { x : NonSendable at disconnected }

    process(x)                  // same isolation (@MainActor → @MainActor)
    // Region merge: disconnected ∪ MainActor = MainActor
    // Γ' = { x : NonSendable at MainActor }

    print(x.value)              // ✅ OK: x is still usable (within MainActor region)
    process(x)                  // ✅ OK: can call again
    print(x.value)              // ✅ OK
}

// =============================================================================
// MARK: - Example 2: Cross Isolation (Implicit Transfer - SE-0414)
// =============================================================================
//
// Cross-isolation call (without `sending`):
// - SE-0414: cross-isolation calls are treated as implicit `sending`
// - After the call, x is consumed and inaccessible

private actor OtherActor {
    func use(_ ns: NonSendable) {
        ns.value += 1
    }
}

@MainActor private func example2_crossIsolation_withoutSending() async {
    let x = NonSendable()       // x : NonSendable at disconnected
    let other = OtherActor()

    // ❌ Error: "sending 'x' risks causing data races"
    // await other.use(x)          // Cross isolation (@MainActor → @isolated(other))
    //
    // SE-0414: implicit `sending` occurs
    // x is transferred and consumed

    print(x.value)              // ❌ x is consumed

    // ❌ Error: "sending 'x' risks causing data races"
    // await other.use(x)          // ❌ x is consumed

    print(x.value)              // ❌ x is consumed
}

// =============================================================================
// MARK: - Example 3: Cross Isolation - Actor Stores the Value (No `sending`)
// =============================================================================
//
// Actor stores the value (without `sending`):
// - SE-0414: cross-isolation calls are treated as implicit `sending`
// - After the call, x is consumed

private actor StoringActor {
    var stored: NonSendable?

    func store(_ ns: NonSendable) {
        stored = ns  // actor stores the value (dangerous!)
    }
}

@MainActor private func example3_crossIsolation_stored_noSending() async {
    let x = NonSendable()
    let storing = StoringActor()

    // ❌ Error: "sending 'x' risks causing data races"
    // await storing.store(x)      // Cross isolation + actor stores x
    //
    // SE-0414: implicit `sending` occurs, x is consumed

    print(x.value)              // ❌ x is consumed
}

// =============================================================================
// MARK: - Example 4: Explicit `sending` - Consumption Expected
// =============================================================================
//
// Explicit `sending` parameter:
// - SE-0430: x is consumed after the call
// - Consumed regardless of same or cross isolation

private actor SendingActor {
    var stored: NonSendable?

    func store(_ ns: sending NonSendable) {
        stored = ns
    }
}

@MainActor private func example4_explicitSending() async {
    let x = NonSendable()
    let actor = SendingActor()

    // ❌ Error: "sending 'x' risks causing data races"
    // await actor.store(x)        // explicit `sending`
    //
    // SE-0430: x is consumed

    print(x.value)              // ❌ x is consumed
}

// =============================================================================
// MARK: - Summary
// =============================================================================
//
// Actual behavior in Swift 6 (verified via `swift build` / Xcode):
//
// | Case                                    | Access after call     |
// |-----------------------------------------|-----------------------|
// | Same isolation (merge)                  | ✅ Accessible         |
// | Cross isolation (without sending)       | ❌ Inaccessible (implicit transfer) |
// | Cross isolation (with sending)          | ❌ Inaccessible (explicit transfer) |
// | Same isolation (with sending)           | ❌ Inaccessible (explicit transfer) |
//
// SE-0414/SE-0430 typing rules:
// - Same isolation: Region merge (`disconnected ∪ @κ = @κ`), no consumption
// - Cross isolation: implicit `sending`, consumed
// - Explicit `sending`: always consumed (regardless of isolation)
