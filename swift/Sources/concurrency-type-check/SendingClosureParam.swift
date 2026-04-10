// =============================================================================
// MARK: - Exploration: `sending` parameter where the param is a closure
// =============================================================================
//
// Question: Does `sending` behave differently when the parameter is a closure
// (which carries captures) vs a plain NonSendable value?
//
// Key findings:
// - Closure LITERAL passed to `sending` param → isPassedToSendingParameter = true
//   → isolation inference boundary → closure stays nonisolated/disconnected
// - Closure LITERAL passed to non-`sending` param → inherits parent isolation
//   → closure becomes actor-bound → cross-iso transfer fails
// - Pre-stored closure variable → already has inferred isolation → `sending`
//   inference boundary does NOT apply
// - Same-iso: both sending and non-sending keep captures accessible (no bind/consume)
// - Cross-iso sending: ~Sendable captures are consumed (all closure types uniformly)
// - Cross-iso non-sending: closure inherits parent isolation → can't transfer (all types)

// MARK: - Helpers

private actor OtherActor {
    // sending variants
    func runSending(_ f: sending () -> Void) { f() }
    func runSendingAsync(_ f: sending () async -> Void) async { await f() }
    func runSendingIsoAny(_ f: sending @isolated(any) () -> Void) async { await f() }
    func runSendingIsoAnyAsync(_ f: sending @isolated(any) () async -> Void) async { await f() }

    // non-sending variants
    func run(_ f: () -> Void) { f() }
    func runAsync(_ f: () async -> Void) async { await f() }
    func runIsoAny(_ f: @isolated(any) () -> Void) async { await f() }
    func runIsoAnyAsync(_ f: @isolated(any) () async -> Void) async { await f() }
}

@MainActor private func mainActorRunSending(_ f: sending () -> Void) { f() }
@MainActor private func mainActorRunSendingAsync(_ f: sending () async -> Void) async { await f() }
@MainActor private func mainActorRunSendingIsoAny(_ f: sending @isolated(any) () -> Void) async { await f() }
@MainActor private func mainActorRunSendingIsoAnyAsync(_ f: sending @isolated(any) () async -> Void) async { await f() }

@MainActor private func mainActorRun(_ f: () -> Void) { f() }
@MainActor private func mainActorRunAsync(_ f: () async -> Void) async { await f() }
@MainActor private func mainActorRunIsoAny(_ f: @isolated(any) () -> Void) async { await f() }
@MainActor private func mainActorRunIsoAnyAsync(_ f: @isolated(any) () async -> Void) async { await f() }

// =============================================================================
// MARK: - A. Same isolation: `() -> Void` (nonisolated sync)
// =============================================================================

// A1. sending, closure literal
@MainActor
private func sameIso_sending_sync_literal() {
    let x = NonSendable()
    mainActorRunSending { _ = x.value }
    _ = x.value // ✅ still usable (same-iso sending does not consume captures)
}

// A2. non-sending, closure literal
@MainActor
private func sameIso_nonSending_sync_literal() {
    let x = NonSendable()
    mainActorRun { _ = x.value }
    _ = x.value // ✅ still usable (closure capture does not bind x)
}

// A3. sending, then cross-actor
@MainActor
private func sameIso_sending_sync_literal_thenCross() async {
    let x = NonSendable()
    mainActorRunSending { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected after same-iso sending
}

// A4. non-sending, then cross-actor
@MainActor
private func sameIso_nonSending_sync_literal_thenCross() async {
    let x = NonSendable()
    mainActorRun { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ closure capture does not bind x (still disconnected)
}

// =============================================================================
// MARK: - B. Same isolation: `() async -> Void` (nonisolated async)
// =============================================================================

// B1. sending async
@MainActor
private func sameIso_sending_async_literal() async {
    let x = NonSendable()
    await mainActorRunSendingAsync { _ = x.value }
    _ = x.value // ✅ still usable
}

// B2. non-sending async
@MainActor
private func sameIso_nonSending_async_literal() async {
    let x = NonSendable()
    await mainActorRunAsync { _ = x.value }
    _ = x.value // ✅ still usable
}

// B3. sending async, then cross-actor
@MainActor
private func sameIso_sending_async_literal_thenCross() async {
    let x = NonSendable()
    await mainActorRunSendingAsync { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected
}

// B4. non-sending async, then cross-actor
@MainActor
private func sameIso_nonSending_async_literal_thenCross() async {
    let x = NonSendable()
    await mainActorRunAsync { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected (capture does not bind)
}

// =============================================================================
// MARK: - C. Same isolation: `@isolated(any) () -> Void` (isolated-any sync)
// =============================================================================

// C1. sending @isolated(any) sync
@MainActor
private func sameIso_sending_isoAny_sync_literal() async {
    let x = NonSendable()
    await mainActorRunSendingIsoAny { _ = x.value }
    _ = x.value // ✅ still usable
}

// C2. non-sending @isolated(any) sync
@MainActor
private func sameIso_nonSending_isoAny_sync_literal() async {
    let x = NonSendable()
    await mainActorRunIsoAny { _ = x.value }
    _ = x.value // ✅ still usable
}

// C3. sending @isolated(any) sync, then cross-actor
@MainActor
private func sameIso_sending_isoAny_sync_literal_thenCross() async {
    let x = NonSendable()
    await mainActorRunSendingIsoAny { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected
}

// C4. non-sending @isolated(any) sync, then cross-actor
@MainActor
private func sameIso_nonSending_isoAny_sync_literal_thenCross() async {
    let x = NonSendable()
    await mainActorRunIsoAny { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected
}

// =============================================================================
// MARK: - D. Same isolation: `@isolated(any) () async -> Void` (isolated-any async)
// =============================================================================

// D1. sending @isolated(any) async
@MainActor
private func sameIso_sending_isoAny_async_literal() async {
    let x = NonSendable()
    await mainActorRunSendingIsoAnyAsync { _ = x.value }
    _ = x.value // ✅ still usable
}

// D2. non-sending @isolated(any) async
@MainActor
private func sameIso_nonSending_isoAny_async_literal() async {
    let x = NonSendable()
    await mainActorRunIsoAnyAsync { _ = x.value }
    _ = x.value // ✅ still usable
}

// D3. sending @isolated(any) async, then cross-actor
@MainActor
private func sameIso_sending_isoAny_async_literal_thenCross() async {
    let x = NonSendable()
    await mainActorRunSendingIsoAnyAsync { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected
}

// D4. non-sending @isolated(any) async, then cross-actor
@MainActor
private func sameIso_nonSending_isoAny_async_literal_thenCross() async {
    let x = NonSendable()
    await mainActorRunIsoAnyAsync { _ = x.value }
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ still disconnected
}

// =============================================================================
// MARK: - E. Cross isolation: sending closure literal (captures consumed)
// =============================================================================

// E1. cross-iso, sending, sync literal
@MainActor
private func crossIso_sending_sync_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSending { _ = x.value } // ✅ sending literal → inference boundary → disconnected
    // _ = x.value                         // ❌ consumed (see NEGATIVE_CROSS_ISO_SENDING_USE_AFTER_SEND)
}

// E2. cross-iso, sending, async literal
@MainActor
private func crossIso_sending_async_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSendingAsync { _ = x.value } // ✅ sending literal → inference boundary
    // _ = x.value                               // ❌ consumed (see NEGATIVE_CROSS_ISO_SENDING_ASYNC_LITERAL_USE_AFTER)
}

// E3. cross-iso, sending, @isolated(any) sync literal
@MainActor
private func crossIso_sending_isoAny_sync_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSendingIsoAny { _ = x.value } // ✅ sending literal → inference boundary
    // _ = x.value                                // ❌ consumed (see NEGATIVE_CROSS_ISO_SENDING_ISOANY_SYNC_LITERAL_USE_AFTER)
}

// E4. cross-iso, sending, @isolated(any) async literal
@MainActor
private func crossIso_sending_isoAny_async_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSendingIsoAnyAsync { _ = x.value } // ✅ sending literal → inference boundary
    // _ = x.value                                     // ❌ consumed (see NEGATIVE_CROSS_ISO_SENDING_ISOANY_ASYNC_LITERAL_USE_AFTER)
}

// =============================================================================
// MARK: - F. Cross isolation: non-sending closure literal (all fail)
// =============================================================================
//
// Non-sending closure literal inherits parent @MainActor isolation → actor-bound
// → cannot be implicitly transferred cross-iso.
// This is the key difference from `sending`: `sending` makes the literal an
// isolation inference boundary, keeping it disconnected.

#if NEGATIVE_CROSS_ISO_NONSENDING_SYNC_LITERAL
// F1. cross-iso, non-sending, sync literal
@MainActor
private func negative_crossIso_nonSending_sync_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.run { _ = x.value } // ❌ closure inherits @MainActor → can't transfer
}
#endif

#if NEGATIVE_CROSS_ISO_NONSENDING_ASYNC_LITERAL
// F2. cross-iso, non-sending, async literal
@MainActor
private func negative_crossIso_nonSending_async_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runAsync { _ = x.value } // ❌ closure inherits @MainActor → can't transfer
}
#endif

#if NEGATIVE_CROSS_ISO_NONSENDING_ISOANY_SYNC_LITERAL
// F3. cross-iso, non-sending, @isolated(any) sync literal
@MainActor
private func negative_crossIso_nonSending_isoAny_sync_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runIsoAny { _ = x.value } // ❌ closure inherits @MainActor → can't transfer
}
#endif

#if NEGATIVE_CROSS_ISO_NONSENDING_ISOANY_ASYNC_LITERAL
// F4. cross-iso, non-sending, @isolated(any) async literal
@MainActor
private func negative_crossIso_nonSending_isoAny_async_literal() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runIsoAnyAsync { _ = x.value } // ❌ closure inherits @MainActor → can't transfer
}
#endif

// =============================================================================
// MARK: - G. Pre-stored closure variable (vs literal)
// =============================================================================
//
// Pre-stored closure inherits parent isolation at definition site.
// `isPassedToSendingParameter` only applies to closure LITERALS at the call site.

// G1. same-iso, sending, pre-stored
@MainActor
private func sameIso_sending_preStored() {
    let x = NonSendable()
    let closure = { _ = x.value }
    mainActorRunSending(closure)
    closure()   // ✅ still callable (same-iso sending does not consume)
    _ = x.value // ✅ still usable
}

// G2. cross-iso, sending, pre-stored
#if NEGATIVE_CROSS_ISO_SENDING_PRESTORED
@MainActor
private func negative_crossIso_sending_preStored() async {
    let x = NonSendable()
    let closure = { _ = x.value } // inherits @MainActor at definition → bound
    let other = OtherActor()
    await other.runSending(closure) // ❌ pre-stored closure already bound → can't send
}
#endif

// =============================================================================
// MARK: - H. Cross isolation: use-after-send for sending closure (all fail)
// =============================================================================
//
// Cross-iso sending consumes ~Sendable captures uniformly across all closure types.

#if NEGATIVE_CROSS_ISO_SENDING_USE_AFTER_SEND
@MainActor
private func negative_crossIso_sending_sync_literal_useAfter() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSending { _ = x.value }
    _ = x.value // ❌ consumed by closure-sending (cross-iso)
}
#endif

#if NEGATIVE_CROSS_ISO_SENDING_ASYNC_LITERAL_USE_AFTER
@MainActor
private func negative_crossIso_sending_async_literal_useAfter() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSendingAsync { _ = x.value }
    _ = x.value // ❌ consumed by closure-sending (cross-iso)
}
#endif

#if NEGATIVE_CROSS_ISO_SENDING_ISOANY_SYNC_LITERAL_USE_AFTER
@MainActor
private func negative_crossIso_sending_isoAny_sync_literal_useAfter() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSendingIsoAny { _ = x.value }
    _ = x.value // ❌ consumed by closure-sending (cross-iso)
}
#endif

#if NEGATIVE_CROSS_ISO_SENDING_ISOANY_ASYNC_LITERAL_USE_AFTER
@MainActor
private func negative_crossIso_sending_isoAny_async_literal_useAfter() async {
    let x = NonSendable()
    let other = OtherActor()
    await other.runSendingIsoAnyAsync { _ = x.value }
    _ = x.value // ❌ consumed by closure-sending (cross-iso)
}
#endif
