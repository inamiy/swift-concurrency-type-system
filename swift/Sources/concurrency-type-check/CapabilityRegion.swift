// Testing @κ ⊇ ρ access matrix via closure capture
//
// Matrix:
// | @κ \ ρ           | disconnected | isolated(a) | task | _ |
// |------------------|--------------|-------------|------|---|
// | @nonisolated     | †separate rule | ❌          | ✅   | ✅ |
// | @isolated(a)     | †separate rule | ✅*         | ✅   | ✅ |
// | @isolated(any)   | †separate rule | ❌          | ✅   | ✅ |
// | @Sendable        | †separate rule | ❌          | ❌   | ✅ |
//
// Testing approach: closure capture
// - Enclosing context provides values at different regions (ρ)
// - Closure type determines capability (@κ)
// - Can the closure capture the value? → @κ ⊇ ρ

// NonSendable is defined in Fixtures/NonSendable.swift

// =============================================================================
// MARK: - ρ = task (var-nonsendable-connected)
// =============================================================================

/// Test @κ ⊇ task using closure capture
/// Parameter of nonisolated async function is at `task` region
private func testTaskRegionCapture(_ ns: NonSendable) async {
    // ns : NonSendable at task (parameter of nonisolated async)

    // -------------------------------------------------
    // @κ = @nonisolated, ρ = task → ✅
    // -------------------------------------------------
    let nonisoCl: () -> Void = {
        _ = ns  // ✅ @nonisolated ⊇ task
    }
    _ = nonisoCl

    // -------------------------------------------------
    // @κ = @isolated(any), ρ = task → ✅
    // -------------------------------------------------
    let isoAnyCl: @isolated(any) () -> Void = {
        _ = ns  // ✅ @isolated(any) ⊇ task
    }
    _ = isoAnyCl

    // -------------------------------------------------
    // @κ = @MainActor, ρ = task → ❌
    // -------------------------------------------------
    // let mainCl: @MainActor () -> Void = {
    //     _ = ns  // ❌ @MainActor ⊇ task
    // }

    // -------------------------------------------------
    // @κ = @Sendable, ρ = task → ❌
    // -------------------------------------------------
    // let sendableCl: @Sendable () -> Void = {
    //     _ = ns  // ❌ @Sendable ⊇ task
    // }
}

// =============================================================================
// MARK: - ρ = isolated(a) (var-nonsendable-connected)
// =============================================================================

private actor TestActor {
    var state: NonSendable = NonSendable()  // state : NonSendable at isolated(self)

    /// Test @κ ⊇ isolated(self) using closure capture
    func testIsolatedRegionCapture() {
        // state : NonSendable at isolated(self)

        // -------------------------------------------------
        // @κ = @isolated(self), ρ = isolated(self) → ✅*
        // -------------------------------------------------
        let actorCl: @isolated(any) () -> Void = {
            _ = self.state  // ✅ (closure inherits self's isolation when called on self)
        }
        _ = actorCl

        // -------------------------------------------------
        // @κ = @nonisolated, ρ = isolated(self) → ❌
        // -------------------------------------------------
        // let nonisoCl: () -> Void = {
        //     _ = self.state  // ❌ @nonisolated ⊇ isolated(self)
        // }

        // -------------------------------------------------
        // @κ = @Sendable, ρ = isolated(self) → ❌
        // -------------------------------------------------
        // let sendableCl: @Sendable () -> Void = {
        //     _ = self.state  // ❌ @Sendable ⊇ isolated(self)
        // }

        // -------------------------------------------------
        // @κ = @MainActor, ρ = isolated(self) → ❌
        // -------------------------------------------------
        // let mainCl: @MainActor () -> Void = {
        //     _ = self.state  // ❌ @MainActor ⊇ isolated(self)
        // }
    }
}

// =============================================================================
// MARK: - ρ = MainActor (var-nonsendable-connected)
// =============================================================================

@MainActor private var mainNS = NonSendable()

/// Test @κ ⊇ _ using closure capture
/// Sendable values are at `_` region (wildcard)
private func testMainActorRegionCapture() {
    // -------------------------------------------------
    // @κ = @nonisolated, ρ = _ → ✅
    // -------------------------------------------------
    let nonisoCl: () -> Void = {
//        _ = mainNS  // ❌ @nonisolated ⊇ MainActor
    }
    _ = nonisoCl

    // -------------------------------------------------
    // @κ = @isolated(any), ρ = _ → ✅
    // -------------------------------------------------
    let isoAnyCl: @isolated(any) () -> Void = {
//        _ = mainNS  // ❌ @isolated(any) ⊇ MainActor
    }
    _ = isoAnyCl

    // -------------------------------------------------
    // @κ = @MainActor, ρ = _ → ✅
    // -------------------------------------------------
    let mainCl: @MainActor () -> Void = {
        _ = mainNS  // ✅ @MainActor ⊇ MainActor
    }
    _ = mainCl

    let actorCl: (isolated MyActor) -> Void = { _ in
//        _ = mainNS  // ❌ @Sendable ⊇ MainActor
    }
    _ = actorCl

    // -------------------------------------------------
    // @κ = @Sendable, ρ = _ → ✅
    // -------------------------------------------------
    let sendableCl: @Sendable () -> Void = {
//        _ = mainNS  // ❌ @Sendable ⊇ MainActor
    }
    _ = sendableCl
}

// =============================================================================
// MARK: - ρ = _ (Sendable) (var-sendable)
// =============================================================================

let s = MySendable()

/// Test @κ ⊇ _ using closure capture
/// Sendable values are at `_` region (wildcard)
private func testSendableRegionCapture(_ _unused_s: MySendable) {
    // s : MySendable at _ (Sendable)

    // -------------------------------------------------
    // @κ = @nonisolated, ρ = _ → ✅
    // -------------------------------------------------
    let nonisoCl: () -> Void = {
        _ = s  // ✅ @nonisolated ⊇ _
    }
    _ = nonisoCl

    // -------------------------------------------------
    // @κ = @isolated(any), ρ = _ → ✅
    // -------------------------------------------------
    let isoAnyCl: @isolated(any) () -> Void = {
        _ = s  // ✅ @isolated(any) ⊇ _
    }
    _ = isoAnyCl

    // -------------------------------------------------
    // @κ = @MainActor, ρ = _ → ✅
    // -------------------------------------------------
    let mainCl: @MainActor () -> Void = {
        _ = s  // ✅ @MainActor ⊇ _
    }
    _ = mainCl

    let actorCl: (isolated MyActor) -> Void = { _ in
        _ = s  // ✅ @Sendable ⊇ _
    }
    _ = actorCl

    // -------------------------------------------------
    // @κ = @Sendable, ρ = _ → ✅
    // -------------------------------------------------
    let sendableCl: @Sendable () -> Void = {
        _ = s  // ✅ @Sendable ⊇ _
    }
    _ = sendableCl
}

// =============================================================================
// MARK: - ρ = disconnected (var-nonsendable-disconnected-noisolated)
// =============================================================================

/// Test @κ ⊇ ρ using closure capture (sync version)
/// NonSendable parameter of sync function behaves like `task` region
/// (bound to caller's isolation, identity unknown at compile time)
private func testDisconnectedCapture() {
    let ns = NonSendable()

    // -------------------------------------------------
    // @κ = @nonisolated, ρ = disconnected → ✅
    // -------------------------------------------------
    let nonisoCl: () -> Void = {
        _ = ns  // ✅ @nonisolated ⊇ disconnected
    }
    _ = nonisoCl

    // -------------------------------------------------
    // @κ = @isolated(any), ρ = disconnected → ✅
    // -------------------------------------------------
    let isoAnyCl: @isolated(any) () -> Void = {
        _ = ns  // ✅ @isolated(any) ⊇ disconnected
    }
    _ = isoAnyCl

    // -------------------------------------------------
    // @κ = @MainActor, ρ = disconnected → ❌
    // -------------------------------------------------
    let mainCl: @MainActor () -> Void = {
        // _ = ns  // ✅ @MainActor ⊇ disconnected
    }

    // -------------------------------------------------
    // @κ = @Sendable, ρ = disconnected → ❌
    // -------------------------------------------------
    let sendableCl: @Sendable () -> Void = {
        // _ = ns  // ❌ @Sendable ⊇ disconnected
    }

    Task {
        nonisoCl()
    }

//    _ = nonisoCl()
}

private actor MyActor {}
