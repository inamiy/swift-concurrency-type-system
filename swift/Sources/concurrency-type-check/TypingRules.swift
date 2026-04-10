// =============================================================================
// MARK: - var
// =============================================================================

// [var] Sendable at _ → accessible from any capability
private func varSendable_accessibleFromAnyCapability() {
    let s = MySendable()

    let f0: () -> MySendable = { s }
    let f1: @MainActor () -> MySendable = { s }
    let f2: @isolated(any) () -> MySendable = { s }
    let f3: @Sendable () -> MySendable = { s }

    _ = (f0(), f1, f2, f3)
    _ = s // not consumed
}

// [var] isolated(MainActor) ∈ accessible(@MainActor)
@MainActor
private var mainActorConnectedVar = NonSendable()

@MainActor
private func varConnected_mainActor_canAccessConnectedVar() {
    _ = mainActorConnectedVar.value
}

#if NEGATIVE_VAR_CONNECTED_MAINACTOR_ACCESS

// [var] isolated(MainActor) ∉ accessible(@nonisolated)
private func negative_varConnected_nonisolatedCannotAccessMainActorVar_isError() {
    _ = mainActorConnectedVar.value // ❌
}

#endif

// [var] disconnected ∈ accessible(@κ) for all @κ
private func varDisconnected_nonSendableClosuresCanCaptureDisconnected() {
    let x = NonSendable()

    let _: @isolated(any) () -> Void = { _ = x.value }
    let _: () -> Void = { _ = x.value }
    let _: @MainActor () -> Void = { _ = x.value }
}

#if NEGATIVE_VAR_DISCONNECTED_SENDABLE_CAPTURE

// [closure-no-inherit-parent] @Sendable cannot capture ~Sendable
private func negative_noInherit_sendableCannotCaptureNonSendable_isError() {
    let x = NonSendable()
    let _: @Sendable () -> Void = { _ = x.value } // ❌
}

#endif

// =============================================================================
// MARK: - seq
// =============================================================================

// [seq] e1; e2 — sequential composition
@MainActor
private func seq_asyncThenSync_compiles() async {
    let other = SendableActor()
    let x = MySendable()

    _ = await other.echoAsync(x)
    _ = x.value
}

// =============================================================================
// MARK: - disconnected-intro / struct-intro
// =============================================================================

// [struct-intro] pair of disconnected values → aggregate is disconnected
@MainActor
private func structIntro_pairOfDisconnected_canBeSent() async {
    let pair = Pair(a: NonSendable(), b: NonSendable())
    let other = OtherActor()
    await other.useNonSendablePairSending(pair)
}

#if NEGATIVE_STRUCT_INTRO_BOUND_FIELD

// [struct-intro] bound field → aggregate is not disconnected
@MainActor
private func negative_structIntro_boundFieldMakesAggregateNotDisconnected_isError() async {
    let a = NonSendable()
    mainActorUseNonSendable(a) // binds `a` → isolated(MainActor)

    let pair = Pair(a: a, b: NonSendable())
    let other = OtherActor()

    // ❌ pair is not disconnected
    await other.useNonSendablePairSending(pair)
}

#endif

// =============================================================================
// MARK: - region-merge
// =============================================================================

// [region-merge] store into @MainActor field → merge regions
@MainActor
private func regionMerge_storeIntoMainActorField_compiles() {
    let x = NonSendable()
    mainActorHolder.field = x
    _ = mainActorHolder.field?.value
}

#if NEGATIVE_REGION_MERGE_STORE_THEN_SEND

// [region-merge] store binds x → isolated(MainActor) → cannot send cross-iso
@MainActor
private func negative_regionMerge_storeThenSend_isError() async {
    let x = NonSendable()
    mainActorHolder.field = x // merge into @MainActor region

    let other = OtherActor()
    await other.useNonSendableSending(x) // ❌ not disconnected
}

#endif

// =============================================================================
// MARK: - sendable-transfer / call-cross-sending-result
// =============================================================================

// [var] Sendable return from cross-actor → at _ → accessible everywhere
@MainActor
private func sendableTransfer_crossActorReturnSendable_compiles() async {
    let actor = SendableActor()
    let s = await actor.make()

    let _: @Sendable () -> MySendable = { s }
    _ = s.value
}

// =============================================================================
// MARK: - call-same-sync-sendable
// =============================================================================

// [call-same-sync-sendable] A: Sendable, B: Sendable
@MainActor
private func callSameSync_mainActorFunction_noAwaitNeeded() {
    let f: @MainActor (MySendable) -> MySendable = { $0 }
    let x = MySendable()
    _ = f(x)
}

// [call-same-sync-sendable] A: Sendable, B: ~Sendable, ρ = disconnected (closure literal)
@MainActor
private func callSameSync_nonSendableReturn() {
    let f: @MainActor (MySendable) -> NonSendable = { _ in NonSendable() }
    let x = MySendable()
    let y = f(x) // ✅ same-iso sync, no `await` needed
    _ = y.value   // ✅ y ∈ accessible(@MainActor)
}

// [call-same-sync-sendable] B: ~Sendable, closure literal → ρ = disconnected
@MainActor
private func callSameSync_nonSendableReturn_thenCrossActor() async {
    let f: @MainActor (MySendable) -> NonSendable = { _ in NonSendable() }
    let x = MySendable()
    let y = f(x)
    _ = y.value // ✅ still usable on @MainActor
}

// [call-same-sync-sendable] B: ~Sendable, closure literal → ρ = disconnected (can send cross-iso)
@MainActor
private func callSameSync_nonSendableReturn_crossIso_works() async {
    let f: @MainActor (MySendable) -> NonSendable = { _ in NonSendable() }
    let x = MySendable()
    let y = f(x)
    await OtherActor().useNonSendableSending(y) // ✅ y is disconnected (can send cross-iso)
}

// [call-same-sync-sendable] B: ~Sendable, named func → ρ = isolated(MainActor)
@MainActor private var mainActorState = NonSendable()
@MainActor private func makeFromActorState() -> NonSendable { mainActorState }

@MainActor
private func callSameSync_nonSendableReturn_fromActorState() async {
    let y = makeFromActorState()
    _ = y.value // ✅ y at isolated(MainActor), accessible from @MainActor
}

#if NEGATIVE_CALL_SAME_SYNC_NONSENDABLE_RETURN_CROSS_ISO
// [call-same-sync-sendable] B: ~Sendable, named func → ρ = isolated(MainActor) → cannot send cross-iso
@MainActor
private func negative_callSameSync_nonSendableReturn_crossIso() async {
    let y = makeFromActorState()
    await OtherActor().useNonSendableSending(y) // ❌ y is isolated(MainActor), not disconnected
}
#endif

// =============================================================================
// MARK: - call-same-async-sendable
// =============================================================================

// [call-same-async-sendable] same-iso async requires `await`
@MainActor
private func callSameAsync_mainActorFunction_requiresAwait() async {
    let f: @MainActor (MySendable) async -> MySendable = { $0 }
    let x = MySendable()
    _ = await f(x)
}

// [call-same-async-sendable] B: ~Sendable, fresh async result stays disconnected
@MainActor
private func callSameAsync_nonSendableReturn_crossIso_works() async {
    let f: @MainActor () async -> NonSendable = { NonSendable() }
    let y = await f()
    _ = y.value

    // Fresh result remains disconnected and can be re-sent.
    await OtherActor().useNonSendableSending(y)
}

// [call-same-async-sendable] B: ~Sendable, actor-state result stays actor-bound
@MainActor
private func callSameAsync_nonSendableReturn_fromActorState() async {
    let f: @MainActor () async -> NonSendable = { mainActorState }
    let y = await f()
    _ = y.value // ✅ y remains main actor-isolated
}

#if NEGATIVE_AWAIT_IN_SYNC_BODY

// [call-same-async-sendable] α = sync → cannot write `await`
@MainActor
private func negative_awaitInSyncBody_isError() {
    let other = SendableActor()
    let x = MySendable()

    // ❌ error: `await` requires `async` context
    _ = await other.echoAsync(x)
}

#endif

#if NEGATIVE_CALL_SAME_ASYNC_MISSING_AWAIT

// [call-same-async-sendable] missing `await`
@MainActor
private func negative_callSameAsync_missingAwait_isError() async {
    let f: @MainActor (MySendable) async -> MySendable = { $0 }
    let x = MySendable()
    _ = f(x) // ❌ error: missing `await`
}

#endif

// =============================================================================
// MARK: - call-cross-sendable
// =============================================================================

// [call-cross-sendable] cross-iso sync call requires `await`
@MainActor
private func callCrossSendableSync_requiresAwait() async {
    let other = SendableActor()
    let x = MySendable()
    _ = await other.echo(x)
}

#if NEGATIVE_CALL_CROSS_SENDABLE_SYNC_MISSING_AWAIT

// [call-cross-sendable] missing `await` on cross-iso sync
@MainActor
private func negative_callCrossSendableSync_missingAwait_isError() async {
    let other = SendableActor()
    let x = MySendable()
    _ = other.echo(x) // ❌ error: missing `await` due to hop
}

#endif

// [call-cross-sendable] cross-iso async call requires `await`
@MainActor
private func callCrossSendableAsync_requiresAwait() async {
    let other = SendableActor()
    let x = MySendable()
    _ = await other.echoAsync(x)
}

#if NEGATIVE_CALL_CROSS_SENDABLE_ASYNC_MISSING_AWAIT

// [call-cross-sendable] missing `await` on cross-iso async
@MainActor
private func negative_callCrossSendableAsync_missingAwait_isError() async {
    let other = SendableActor()
    let x = MySendable()
    _ = other.echoAsync(x) // ❌ error: missing `await`
}

#endif

// =============================================================================
// MARK: - call-nonisolated-async-inherit (SE-0461)
// =============================================================================

// [call-nonisolated-async-inherit] nonisolated sync param capture
private func nonisolated_paramCaptureExample(_ x: NonSendable) {
    // Capturable from @nonisolated / @isolated(any) contexts.
    let nonisoCl: () -> Void = { _ = x.value }
    let isoAnyCl: @isolated(any) () -> Void = { _ = x.value }
    _ = (nonisoCl, isoAnyCl)
}

// [call-nonisolated-async-inherit] nonisolated sync → param stays accessible
@MainActor
private func nonisolated_paramCapture_compiles() {
    let x = NonSendable()
    nonisolated_paramCaptureExample(x)
}

// [call-nonisolated-async-inherit] nonisolated async → param becomes task-isolated
@MainActor
private func nonisolatedAsync_paramBehavesLikeTaskRegion() async {
    nonisolated func helper(_ x: NonSendable) async {
        // In a `nonisolated async` function body, non-Sendable parameters are task-isolated.
        let noniso: () -> Void = { _ = x.value }
        let isoAny: @isolated(any) () -> Void = { _ = x.value }
        _ = (noniso, isoAny)
    }

    let x = NonSendable()
    await helper(x)
}

#if NEGATIVE_NONISOLATED_SYNC_PARAM_MAINACTOR_CAPTURE

// [call-nonisolated-async-inherit] task-isolated param cannot be captured by @MainActor closure
private func negative_nonisolated_parameterCannotBeCapturedByMainActorClosure_isError(
    _ x: NonSendable
) {
    // ❌ nonisolated sync param is task-like → cannot capture in @MainActor closure
    let _: @MainActor () -> Void = { _ = x.value }
}

#endif

#if NEGATIVE_NONISOLATED_ASYNC_PARAM_MAINACTOR_CAPTURE

// [call-nonisolated-async-inherit] task-isolated param cannot be captured by @MainActor closure (async)
private func negative_nonisolatedAsync_parameterCannotBeCapturedByMainActorClosure_isError(
    _ x: NonSendable
) async {
    // ❌ nonisolated async param is task-isolated → cannot capture in @MainActor closure
    let _: @MainActor () -> Void = { _ = x.value }
}

#endif

// [closure-inherit-parent] @MainActor param is actor-isolated → capturable by @MainActor closure
@MainActor
private func mainActor_paramCapture_isActorIsolated_compiles(_ x: NonSendable) {
    let _: @MainActor () -> Void = { _ = x.value }
}

#if NEGATIVE_MAINACTOR_PARAM_SEND_ACROSS_ACTOR

private actor MainActorParamProbeActor {
    func useSending(_ x: sending NonSendable) {}
}

// [call-nonsendable-consume] actor-bound param cannot be sent cross-iso
@MainActor
private func negative_mainActorParamSendAcrossActor_isError(_ x: NonSendable) async {
    let other = MainActorParamProbeActor()
    // Expect: ❌ error because `x` is main actor-isolated (not disconnected).
    await other.useSending(x)
}

#endif

// [call-nonisolated-async-inherit] nonisolated async does not consume/bind disconnected arg
@MainActor
private func nonisolatedAsync_callThenSend_compiles() async {
    nonisolated func useNonSendable(_ x: NonSendable) async { _ = x.value }

    let x = NonSendable() // disconnected

    await useNonSendable(x)

    let other = OtherActor()
    await other.useNonSendableSending(x) // still disconnected (then consumed by `sending`)
}

// [call-nonisolated-async-inherit] + [call-nonsendable-consume] sending consumes
@MainActor
private func nonisolatedAsync_sendingParam_compilesAndConsumes() async {
    nonisolated func useNonSendableSending(_ x: sending NonSendable) async { _ = x.value }

    let x = NonSendable() // disconnected
    await useNonSendableSending(x) // consumed by explicit `sending`
    // _ = x.value // ❌ error: use-after-consume (see NEGATIVE_NONISOLATED_ASYNC_USE_AFTER_SENDING)
}

// [call-nonisolated-async-inherit] arg and result both stay disconnected
@MainActor
private func nonisolatedAsync_callThenSend_argAndResult_compiles() async {
    nonisolated func useAndMakeNonSendable(_ x: NonSendable) async -> NonSendable {
        _ = x.value
        return NonSendable()
    }

    let x = NonSendable() // disconnected

    let y = await useAndMakeNonSendable(x)

    let other = OtherActor()
    await other.useNonSendableSending(y) // result is disconnected
    await other.useNonSendableSending(x) // argument remains disconnected
}

// [call-nonisolated-async-inherit] return value from nonisolated async is disconnected
@MainActor
private func nonisolatedAsync_returnNonSendable_canBeSent() async {
    nonisolated func makeNonSendable() async -> NonSendable { NonSendable() }

    let x = await makeNonSendable()

    let other = OtherActor()
    await other.useNonSendableSending(x)
}

#if NEGATIVE_NONISOLATED_ASYNC_RETURN_BOUND_THEN_SEND

// [call-nonisolated-async-inherit] actor-bound input → return is still actor-bound
@MainActor
private func negative_nonisolatedAsync_returnBoundThenSend_isError() async {
    nonisolated func id(_ x: NonSendable) async -> NonSendable { x }

    let y = await id(mainActorConnectedVar)

    let other = OtherActor()

    // ❌ returned value is still actor-bound (not disconnected)
    await other.useNonSendableSending(y)
}

#endif

#if NEGATIVE_NONISOLATED_ASYNC_TASK_RESULT_THEN_SEND

// [call-nonisolated-async-inherit] task-isolated input → return is still task-isolated
private func negative_nonisolatedAsync_taskResultThenSend_isError(_ x: NonSendable) async {
    nonisolated func id(_ x: NonSendable) async -> NonSendable { x }

    // x : NonSendable at task (SE-0414)
    let y = await id(x)
    // y : NonSendable at task (not disconnected)

    let other = OtherActor()

    // ❌ y is task-isolated (not disconnected)
    await other.useNonSendableSending(y)
}

#endif

#if NEGATIVE_NONISOLATED_ASYNC_USE_AFTER_SENDING

// [call-nonsendable-consume] use-after-consume via sending
@MainActor
private func negative_nonisolatedAsync_useAfterSendingParam_isError() async {
    nonisolated func useNonSendableSending(_ x: sending NonSendable) async { _ = x.value }

    let x = NonSendable()
    await useNonSendableSending(x)

    // ❌ use-after-consume
    _ = x.value
}

#endif

// =============================================================================
// MARK: - call-nonisolated-sync
// =============================================================================

// Helper: nonisolated sync function taking NonSendable
private func nonisolatedSyncHelper(_ x: NonSendable) -> NonSendable {
    _ = x.value
    return NonSendable()
}

// [call-nonisolated-sync] @MainActor can call nonisolated sync without await
@MainActor
private func nonisolatedSync_callFromMainActor_noAwait() async {
    let x = NonSendable() // disconnected

    // call-nonisolated-sync: @κ = @MainActor, @ι = @nonisolated, sync → no await
    let y = nonisolatedSyncHelper(x)
    _ = y.value // ✅ result accessible
}

// [call-nonisolated-sync] local nonisolated func (NOT @Sendable) also callable from @MainActor
@MainActor
private func nonisolatedSync_localNonSendableFunc_callFromMainActor() {
    nonisolated func localHelper(_ x: NonSendable) {
        _ = x.value
    }
    // localHelper is a local function → NOT @Sendable by SE-0418
    let x = NonSendable()
    localHelper(x) // ✅ call-nonisolated-sync: no @Sendable required
}

// [call-nonisolated-sync] nonisolated sync does not bind ~Sendable arg
@MainActor
private func nonisolatedSync_nonSendableArg_noBinding() async {
    let x = NonSendable() // disconnected

    let _ = nonisolatedSyncHelper(x)

    // x is NOT bound (Γ₂, not Γ₂[x ↦ ...]) — still disconnected
    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ still disconnected, can send
}

// [call-nonisolated-sync + closure] same-isolation closure wrapping works
@MainActor
private func nonisolatedSync_sameIsolationClosureWrapping_compiles() {
    // g is declared in @MainActor context → g at isolated(MainActor)
    let g: () -> Void = {}
    // Closure inferred as @MainActor from assignment target.
    // Capture: g at isolated(MainActor) → @MainActor closure = same-isolation ✅
    // Call:    g() is nonisolated sync from @MainActor body = call-nonisolated-sync ✅
    let f: @MainActor () -> Void = { g() }
    _ = f
}

// [call-nonisolated-sync + closure] nonisolated local (disconnected) → @MainActor closure wrapping works
// When g is a local variable (disconnected), capture into @MainActor closure binds it.
private func nonisolatedSync_disconnectedClosureWrapping_compiles() {
    let g: () -> Void = {}              // g at disconnected (freshly created)
    let f: @MainActor () -> Void = { g() } // ✅ capture disconnected → MainActor (binding)
    _ = f                                   //    call: call-nonisolated-sync ✅
}

#if NEGATIVE_NONISOLATED_SYNC_PARAM_CLOSURE_WRAPPING

// [call-nonisolated-sync + closure] nonisolated PARAMETER (task) → @MainActor closure wrapping fails
// Parameters have `task` region, not `disconnected` — cannot be captured cross-isolation.
private func negative_nonisolatedSync_paramClosureWrapping_isError(
    _ g: @escaping () -> Void
) {
    // g is a parameter → g at task region
    let _: @MainActor () -> Void = { g() } // ❌ task region → @MainActor capture blocked
}

#endif

// [call-nonisolated-sync + closure] `sending` parameter (disconnected) → @MainActor closure wrapping works
// `sending` gives the parameter `disconnected` region, enabling cross-isolation capture.
private func nonisolatedSync_sendingParamClosureWrapping_compiles(
    _ g: sending @escaping () -> Void
) {
    // g is `sending` → g at disconnected (not task)
    let f: @MainActor () -> Void = { g() } // ✅ capture: disconnected → binding
    _ = f                                   //    call: call-nonisolated-sync ✅
}

// =============================================================================
// MARK: - call-concurrent-sendable / call-concurrent-nonsendable (SE-0461)
// =============================================================================

// [closure-inherit-parent] normal async closure literal inherits @MainActor
@MainActor
private func normalAsyncClosureLiteral_inheritsMainActorIsolation() {
    let f: () async -> Void = {
        _ = mainActorConnectedVar.value
    }
    _ = f
}

// [call-concurrent-sendable] @concurrent async with Sendable args
private func concurrentAsync_callFromNonisolated_compiles() async {
    let f: @concurrent (MySendable) async -> MySendable = { $0 }
    let x = MySendable()
    _ = await f(x)
}

// [closure-inherit-parent] closure literal inherits @MainActor even in @concurrent type
@MainActor
private func concurrentAsyncClosureLiteral_canAccessMainActorState_compiles() {
    let f: @concurrent () async -> Void = {
        _ = mainActorConnectedVar.value
    }
    _ = f
}

// [call-concurrent-nonsendable] disconnected ~Sendable can be passed to @concurrent
@MainActor
private func concurrentAsync_callWithDisconnectedNonSendable_compiles() async {
    let x = NonSendable() // disconnected
    let f: @concurrent (NonSendable) async -> Void = { _ in }
    await f(x)
}

// [call-concurrent-nonsendable] arg stays disconnected after @concurrent call
@MainActor
private func concurrentAsync_callThenSend_compiles() async {
    let x = NonSendable() // disconnected
    let f: @concurrent (NonSendable) async -> Void = { _ in }

    await f(x)

    // Still disconnected after the call.
    let other = OtherActor()
    await other.useNonSendableSending(x)
}

#if NEGATIVE_CONCURRENT_CALL_ACTOR_BOUND_ARG

// [call-concurrent-nonsendable] actor-bound arg cannot be passed to @concurrent
@MainActor
private func negative_concurrentAsync_callWithActorBoundNonSendable_isError() async {
    let f: @concurrent (NonSendable) async -> Void = { _ in }
    await f(mainActorConnectedVar) // ❌ actor-bound argument
}

#endif

#if NEGATIVE_CONCURRENT_SYNC_IS_INVALID

// @concurrent is async-only — sync @concurrent is invalid
private func negative_concurrentSyncType_isError() {
    let _: @concurrent () -> Void = {} // ❌ @concurrent only exists in async
}

#endif

// =============================================================================
// MARK: - isolated-any-isolation-prop (SE-0431)
// =============================================================================

// [isolated-any-isolation-prop] f.isolation returns (any Actor)?
private func isolatedAny_isolationProperty_typechecks() {
    let f0: @isolated(any) () -> Void = {}
    let _: (any Actor)? = f0.isolation
}

// [call-cross-sendable] sync @isolated(any) call still requires `await`
@MainActor
private func isolatedAny_call_coercedFromMainActor_requiresAwait() async {
    let fMain: @MainActor () -> Void = {}
    let fAny: @isolated(any) () -> Void = fMain
    await fAny()
}

// [call-cross-sending-result] `sending` result from @isolated(any) is disconnected
@MainActor
private func isolatedAny_call_returnSendingNonSendable_compiles() async {
    let fMain: @MainActor () -> sending NonSendable = { NonSendable() }
    let fAny: @isolated(any) () -> sending NonSendable = fMain
    let x = await fAny()
    await OtherActor().useNonSendableSending(x)
}

#if NEGATIVE_ISOLATED_ANY_NON_SENDABLE_RESULT

// [call-cross-nonsending-result-error] non-`sending` ~Sendable result from @isolated(any) is rejected
@MainActor
private func negative_isolatedAny_call_returnNonSendable_isError() async {
    let fMain: @MainActor () -> NonSendable = { NonSendable() }
    let fAny: @isolated(any) () -> NonSendable = fMain
    let x = await fAny() // ❌ non-Sendable result crosses isolation boundary
    _ = x.value
}

#endif

// Runtime checks (executed from `swift test`) ---------------------------------

// [isolated-any-isolation-prop] task-region capture → f.isolation == nil
func isolatedAny_isolationProperty_taskRegionCapture_returnsNil() async -> (any Actor)? {
    let x = NonSendable()
    return await isolatedAny_isolationProperty_taskRegionCapture_returnsNil_impl(x)
}

private func isolatedAny_isolationProperty_taskRegionCapture_returnsNil_impl(
    _ x: NonSendable
) async -> (any Actor)? {
    // nonisolated async → param is task-isolated (SE-0414)
    let f: @isolated(any) () -> Void = { _ = x.value }
    return f.isolation // nil (dynamically nonisolated; task ≠ actor)
}

// [isolated-any-isolation-prop] @MainActor closure → f.isolation == MainActor.shared
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor() -> (any Actor)? {
    let fMain: @MainActor () -> Void = { _ = mainActorConnectedVar.value }
    let fAny: @isolated(any) () -> Void = fMain
    return fAny.isolation // MainActor.shared
}

// [isolated-any-isolation-prop] actor identity erased via `() -> Void` → f.isolation == nil
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor2() -> (any Actor)? {
    let fMain: () -> Void = { _ = mainActorConnectedVar.value }
    let fAny: @isolated(any) () -> Void = fMain
    return fAny.isolation // nil (actor identity erased by `() -> Void` type)
}

// [isolated-any-isolation-prop] direct @isolated(any) literal → f.isolation == MainActor.shared
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor3() -> (any Actor)? {
    let fAny: @isolated(any) () -> Void = { _ = mainActorConnectedVar.value }
    return fAny.isolation // MainActor.shared
}

// =============================================================================
// MARK: - closure-inherit-parent / closure-no-inherit-parent / closure-sending
// =============================================================================

// [closure-inherit-parent] capture does not consume
private func nonSendableClosureCapture_doesNotConsume() {
    let x = NonSendable()
    let f = { x.value += 1 }
    x.value += 1
    f()
}

// [closure-inherit-parent] @MainActor closure capture does not consume
@MainActor
private func mainActorClosureCapture_doesNotConsume() {
    let x = NonSendable()
    let f: @MainActor () -> Void = { x.value += 1 }
    x.value += 1
    f()
}

// [closure-no-inherit-parent] @Sendable closure → body uses @ι from contextual type, not parent's @κ
// Case 1: @Sendable () → @ι = @nonisolated → body is nonisolated
private func noInherit_sendableNonisolated_compiles() {
    let s = MySendable()
    let f: @Sendable () -> MySendable = { s } // ✅ Sendable capture, nonisolated body
    _ = f().value
}

// [closure-no-inherit-parent] Case 2: @Sendable @MainActor () → @ι = @MainActor → body is @MainActor
@MainActor
private func noInherit_sendableMainActor_compiles() {
    let f: @Sendable @MainActor () -> Void = {
        _ = mainActorConnectedVar.value // ✅ body is @MainActor (from @ι, not inherited)
    }
    f()
}

// =============================================================================
// MARK: - call-same-nonsendable-merge / call-nonsendable-noconsume / call-nonsendable-consume
// =============================================================================

@MainActor
private func mainActorUseNonSendable(_ x: NonSendable) {
    x.value += 1
}

@MainActor
private func mainActorUseNonSendableSending(_ x: sending NonSendable) {
    x.value += 1
}

@MainActor
private func mainActorUseNonSendableSendingAsync(_ x: sending NonSendable) async {
    x.value += 1
}

// Helper: nonisolated sync function with `sending` parameter
private func nonisolatedSyncUseSending(_ x: sending NonSendable) {
    _ = x.value
}

// [call-nonsendable-noconsume] same-iso sync sending does not consume
@MainActor
private func noconsume_sameIsoSyncSending_compiles() {
    let x = NonSendable()
    mainActorUseNonSendableSending(x)
}

// [call-nonsendable-noconsume] same-iso sync sending preserves actor-bound region too
@MainActor
private func noconsume_sameIsoSyncSending_actorBound_compiles() {
    let y = mainActorConnectedVar
    mainActorUseNonSendableSending(y)
    _ = y.value // ✅ remains main actor-isolated, not consumed
}

// [call-nonsendable-noconsume] x stays disconnected after same-iso sync sending
@MainActor
private func noconsume_sameIsoSyncSending_thenUse_compiles() {
    let x = NonSendable()
    mainActorUseNonSendableSending(x)
    _ = x.value // ✅ not consumed — still usable
}

// [call-nonsendable-noconsume] x stays disconnected → can send cross-actor afterwards
@MainActor
private func noconsume_sameIsoSyncSending_thenCrossSend_compiles() async {
    let x = NonSendable()
    mainActorUseNonSendableSending(x)
    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ still disconnected
}

// [call-nonsendable-noconsume] can pass to same-iso sync sending repeatedly
@MainActor
private func noconsume_sameIsoSyncSending_twice_compiles() {
    let x = NonSendable()
    mainActorUseNonSendableSending(x)
    mainActorUseNonSendableSending(x) // ✅
}

// [call-nonsendable-noconsume] same-iso async sending does not consume
@MainActor
private func noconsume_sameIsoAsyncSending_compiles() async {
    let x = NonSendable()
    await mainActorUseNonSendableSendingAsync(x) // ✅ noconsume (same isolation, async)
    _ = x.value                                   // ✅ still usable
    await mainActorUseNonSendableSendingAsync(x) // ✅ can pass again
}

// [call-same-nonsendable-merge] same-iso non-sending binds but does not consume
@MainActor
private func merge_sameIso_doesNotConsume() {
    let x = NonSendable()
    mainActorUseNonSendable(x)
    _ = x.value
    mainActorUseNonSendable(x)
}

// [var] read does not bind → x stays disconnected
@MainActor
private func mainActor_readDoesNotPreventSendingFromDisconnected() async {
    let x = NonSendable()
    _ = x.value

    let other = OtherActor()
    await other.useNonSendableSending(x)
}

// [call-nonsendable-consume] nonisolated sync sending consumes
private func consume_nonisolatedSyncSending_compiles() {
    let x = NonSendable()
    nonisolatedSyncUseSending(x) // ✅ compiles — x is consumed
}

// [call-nonsendable-consume] @MainActor caller → nonisolated sync sending (no await for sync)
@MainActor
private func consume_nonisolatedSyncSending_fromMainActor_compiles() {
    let x = NonSendable()
    nonisolatedSyncUseSending(x) // ✅ compiles — x is consumed (sync cross-isolation)
}

// [call-nonsendable-consume] cross-iso explicit sending consumes
@MainActor
private func consume_crossIsoExplicitSending_compiles() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendableSending(x)
    // x is consumed (see NEGATIVE_USE_AFTER_EXPLICIT_SENDING)
}

#if NEGATIVE_NONISOLATED_SYNC_SENDING_USE_AFTER

// [call-nonsendable-consume] nonisolated sync sending use-after-send
private func negative_consume_nonisolatedSyncSending_useAfter_isError() {
    let x = NonSendable()
    nonisolatedSyncUseSending(x)
    _ = x.value // ❌ sending 'x' risks causing data races
}

#endif

#if NEGATIVE_NONISOLATED_SYNC_SENDING_TWICE

// [call-nonsendable-consume] nonisolated sync sending cannot pass twice
private func negative_consume_nonisolatedSyncSending_twice_isError() {
    let x = NonSendable()
    nonisolatedSyncUseSending(x)
    nonisolatedSyncUseSending(x) // ❌ sending 'x' risks causing data races
}

#endif

// [call-nonsendable-consume] cross-iso implicit transfer consumes
@MainActor
private func consume_crossIsoImplicit_compiles() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendable(x)

    // NOTE: `x` should be considered consumed after the call (negative test below).
}

// [call-cross-sending-result] sending result is disconnected
@MainActor
private func crossActor_sendingResult_compiles() async {
    let actor = ResultActor()
    let x = await actor.makeSending()
    _ = x.value

    // sending result is disconnected → can be transferred again
    let other = OtherActor()
    await other.useNonSendableSending(x)
}

// =============================================================================
// MARK: - closure-sending (Task capture)
// =============================================================================

// [closure-sending] Task.init can capture disconnected NonSendable in inherited actor context
private func taskInit_canCaptureDisconnectedNonSendable() {
    let x = NonSendable()
    Task {
        _ = x.value
    }
}

// [closure-sending] same-actor Task.init does not consume disconnected captures
@MainActor
private func taskInit_sameActorDisconnectedCaptureDoesNotConsume() {
    let x = NonSendable()
    Task {
        _ = x.value
    }
    _ = x.value
}

// [closure-sending] same-actor Task.init also preserves actor-bound captures
@MainActor
private func taskInit_sameActorBoundCaptureDoesNotConsume() {
    let y = mainActorConnectedVar
    Task {
        _ = y.value
    }
    _ = y.value
}

// [closure-sending] Task.detached captures via sending → disconnected accepted
private func taskDetached_canCaptureDisconnectedNonSendable() {
    let x = NonSendable()
    Task.detached {
        _ = x.value
    }
}

#if NEGATIVE_USE_AFTER_IMPLICIT_TRANSFER

// [call-nonsendable-consume] cross-iso implicit use-after-send
@MainActor
private func negative_consume_crossIsoImplicit_useAfter_isError() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendable(x)

    // ❌ use-after-send (x was implicitly transferred)
    _ = x.value
}

#endif

#if NEGATIVE_DOUBLE_CALL

// [call-nonsendable-consume] cross-iso implicit double call
@MainActor
private func negative_consume_crossIsoImplicit_twice_isError() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendable(x)

    // ❌ second call uses already-sent value
    await other.useNonSendable(x)
}

#endif

#if NEGATIVE_USE_AFTER_EXPLICIT_SENDING

// [call-nonsendable-consume] cross-iso explicit sending use-after-consume
@MainActor
private func negative_consume_crossIsoExplicitSending_useAfter_isError() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendableSending(x)

    // ❌ use-after-consume
    _ = x.value
}

#endif

#if NEGATIVE_SEND_AFTER_MAINACTOR_USE

// [call-same-nonsendable-merge] bind removes disconnected → [call-nonsendable-consume] fails
@MainActor
private func negative_merge_thenCrossSend_isError() async {
    let x = NonSendable()
    mainActorUseNonSendable(x) // binds x → isolated(MainActor)

    let other = OtherActor()

    // ❌ x is no longer disconnected
    await other.useNonSendableSending(x)
}

#endif

#if NEGATIVE_TASKINIT_USE_AFTER_SEND

// [closure-sending] nonisolated Task.init capture is rejected as a sending data-race risk
private func negative_taskInit_useAfterSend_isError() {
    let x = NonSendable()
    Task {
        _ = x.value
    }

    // ❌ x was captured by sending Task initializer
    _ = x.value
}

#endif

#if NEGATIVE_TASKDETACHED_USE_AFTER_SEND

// [closure-sending] Task.detached sending consumes → use-after-send
private func negative_taskDetached_useAfterSend_isError() {
    let x = NonSendable()
    Task.detached {
        _ = x.value
    }

    // ❌ x was captured by sending detached task
    _ = x.value
}

#endif

#if NEGATIVE_TASKDETACHED_CAPTURE_ACTOR_BOUND

// [closure-no-inherit-parent] actor-bound value cannot be captured by detached task
@MainActor
private var mainActorBoundGlobal = NonSendable()

private func negative_taskDetached_captureActorBound_isError() {
    // ❌ actor-bound value cannot be captured from detached task
    Task.detached {
        _ = mainActorBoundGlobal.value
    }
}

#endif

#if NEGATIVE_RESULT

// [call-cross-nonsending-result-error] ~Sendable result without sending crosses iso boundary
private actor NonSendingResultActor {
    func make() -> NonSendable {
        NonSendable()
    }
}

@MainActor
private func negative_crossActor_nonSendingResult_isError() async {
    let actor = NonSendingResultActor()

    // ❌ non-Sendable result crosses isolation boundary
    let x = await actor.make()
    _ = x.value
}

#endif

// =============================================================================
// MARK: - call-isolated-param-semantics (SE-0313)
// =============================================================================

// [call-isolated-param-semantics] sync access to actor state via `isolated` param
private func isolatedParam_syncAccessInSameIsolation(actor: isolated LocalActor) {
    _ = actor.state // ✅ sync access (no `await`)
}

// [call-isolated-param-semantics] cross-isolation requires `await`
@MainActor
private func isolatedParam_crossIsolation_requiresAwait() async {
    let actor = LocalActor()
    _ = await actor.getState() // ✅ cross-iso → await
}

// [call-same-nonsendable-merge] via isolated param → binds x to actor region
private func isolatedParam_nonsendableArg_bindToActorRegion(
    actor: isolated LocalActor
) {
    let x = NonSendable() // disconnected
    actor.useNonSendable(x) // ✅ same-iso call, binds x
    _ = x.value // ✅ still accessible (bound, not consumed)
}

// [call-isolated-param-semantics] actor method self is implicitly isolated
private func isolatedParam_actorSelfIsImplicitIsolated(
    actor: isolated LocalActor
) {
    _ = actor.state // ✅ direct state access
}

// --- Caller-side: calling a function with `isolated` parameter ---

// [call-same-nonsendable-merge] helper with isolated param
private func isolatedParamFunc_useNonSendable(
    actor: isolated LocalActor, _ x: NonSendable
) {
    actor.useNonSendable(x)
}

// [call-nonsendable-noconsume] helper with isolated param + sending
private func isolatedParamFunc_useNonSendableSending(
    actor: isolated LocalActor, _ x: sending NonSendable
) {
    actor.useNonSendableSending(x)
}

// [call-isolated-param-semantics] cross-iso call (MainActor ≠ LocalActor) requires `await`
@MainActor
private func callerSide_isolatedParam_crossIsolation_requiresAwait() async {
    let actor = LocalActor()
    let x = NonSendable()
    await isolatedParamFunc_useNonSendable(actor: actor, x) // ✅ cross-iso → await
}

// [call-isolated-param-semantics] same-iso (both have isolated LocalActor) → no await
private func callerSide_isolatedParam_sameIsolation_noAwait(
    actor: isolated LocalActor
) {
    let x = NonSendable()
    isolatedParamFunc_useNonSendable(actor: actor, x) // ✅ same-iso → no await
    _ = x.value // ✅ still accessible (bound, not consumed)
}

// [call-nonsendable-consume] cross-iso with sending via isolated param
@MainActor
private func callerSide_isolatedParam_crossIsolation_sending() async {
    let actor = LocalActor()
    let x = NonSendable()
    await isolatedParamFunc_useNonSendableSending(actor: actor, x) // ✅ sending consumes
    // _ = x.value // ❌ would be use-after-send
}

#if NEGATIVE_ISOLATED_PARAM_MULTIPLE

// [call-isolated-param-semantics] only one `isolated` param allowed
private func negative_isolatedParam_multipleIsolated_isError(
    a: isolated LocalActor,
    b: isolated LocalActor
) {
    // ❌ only one `isolated` parameter is allowed per function
    _ = a.state
    _ = b.state
}

#endif

// =============================================================================
// MARK: - call-isolation-macro-semantics (SE-0420)
// =============================================================================

// [call-isolation-macro-semantics] helper with `#isolation`
private func measureTime<T, E: Error>(
    _ f: () async throws(E) -> T,
    isolation: isolated (any Actor)? = #isolation
) async throws(E) -> T {
    try await f()
}

// [decl-fun-isolation-inheriting] body is @nonisolated
private func isolationInheriting_bodyIsNonisolated<T>(
    _ f: () async throws -> T,
    isolation: isolated (any Actor)? = #isolation
) async rethrows -> T {
    return try await f()
}

// [call-isolation-macro-semantics] #isolation → same-iso → closure doesn't need @Sendable
@MainActor
private func isolationMacro_closureDoesNotNeedSendable() async {
    await measureTime {
        print("same isolation as caller")
    }
}

// [call-isolation-macro-semantics] #isolation → same-iso → inout var accessible
@MainActor
private func isolationMacro_inoutVarAccessible() async {
    var progress = 0
    await measureTime {
        progress += 1       // ✅ inout access (same isolation)
        await Task.yield()
    }
    _ = progress
}

// [call-isolation-macro-semantics] #isolation → same-iso → non-Sendable not consumed
@MainActor
private func isolationMacro_nonSendableNotConsumed() async {
    let x = NonSendable()
    await measureTime {
        _ = x.value // ✅ non-Sendable captured without @Sendable
    }
    _ = x.value // ✅ still usable (same isolation)
}

#if NEGATIVE_ISOLATION_MACRO_SENDABLE_MUTATION

// [closure-no-inherit-parent] @Sendable closure cannot mutate captured var
private func requiresSendable<T>(_ f: @Sendable () -> T) -> T {
    f()
}

@MainActor
private func negative_isolationMacro_sendableClosureCannotMutateCapture_isError() {
    var progress = 0
    _ = requiresSendable {
        progress += 1 // ❌ mutating capture in @Sendable closure
        return progress
    }
}

#endif

#if NEGATIVE_ISOLATION_INHERITING_BODY_CANNOT_ACCESS_ACTOR_STATE

// [decl-fun-isolation-inheriting] body is @nonisolated → cannot access @MainActor state
private func negative_isolationInheriting_bodyCannotAccessActorState(
    isolation: isolated (any Actor)? = #isolation
) async {
    // ❌ body is @nonisolated
    _ = mainActorConnectedVar.value
}

#endif

// MARK: - Helpers

private actor LocalActor {
    var state: Int = 0
    func getState() -> Int { state }
    func useNonSendable(_ x: NonSendable) { x.value += state }
    func useNonSendableSending(_ x: sending NonSendable) { x.value += state }
}

private actor OtherActor {
    func useNonSendable(_ x: NonSendable) {
        x.value += 1
    }

    func useNonSendableSending(_ x: sending NonSendable) {
        x.value += 1
    }

    func useNonSendablePairSending(_ x: sending Pair) {
        x.a.value += 1
        x.b.value += 1
    }
}

private actor ResultActor {
    func makeSending() -> sending NonSendable {
        NonSendable()
    }
}

private actor SendableActor {
    func make() -> MySendable {
        MySendable()
    }

    func echo(_ x: MySendable) -> MySendable {
        x
    }

    func echoAsync(_ x: MySendable) async -> MySendable {
        x
    }
}

private struct Pair {
    var a: NonSendable
    var b: NonSendable
}

@MainActor
private var mainActorHolder = MainActorHolder()

@MainActor
private final class MainActorHolder {
    var field: NonSendable? = nil
}

// =============================================================================
// MARK: - closure-inherit-parent / closure-no-inherit-parent (Isolation Inheritance)
// =============================================================================

// [closure-inherit-parent] non-@Sendable closure inherits @MainActor from parent
@MainActor
private func closureIsolationInherit_nonSendableInheritsMainActor() {
    let handler: () -> Void = {
        _ = mainActorConnectedVar.value // ✅ @MainActor inherited
    }
    handler()
}

#if NEGATIVE_CLOSURE_SENDABLE_LOSES_ISOLATION
// [closure-no-inherit-parent] @Sendable → isolation inference boundary → nonisolated
@MainActor
private func negative_noInherit_sendableLosesIsolation_isError() {
    let handler: @Sendable () -> Void = {
        _ = mainActorConnectedVar.value // ❌ @Sendable breaks isolation inheritance
    }
    _ = handler
}
#endif

// =============================================================================
// MARK: - closure-inherit-parent: actor-instance capture requirement (SE-0461/SE-0420)
// =============================================================================

// [closure-inherit-parent] Actor-instance isolation requires capturing the isolated param.
// When parent context is isolated to an actor instance (not a global actor),
// the closure must reference the isolated parameter in its body to inherit isolation.
// Without the capture, the closure becomes nonisolated.

// Case 1: Closure in actor method captures self → inherits actor isolation
private extension LocalActor {
    func closureInActorMethod_capturesSelf_inheritsIsolation() {
        let cl: @isolated(any) () -> Void = {
            _ = self.state // captures self → inherits actor-instance isolation
        }
        _ = cl
    }
}

// Case 2: Closure in actor method does NOT capture self → becomes nonisolated
private extension LocalActor {
    func closureInActorMethod_noCaptureOfSelf_becomesNonisolated() {
        let cl: @isolated(any) () -> Void = {
            // no reference to self → nonisolated
        }
        _ = cl
    }
}

// Case 3: Closure with isolated parameter captures it → inherits isolation
private func closureWithIsolatedParam_capturesParam_inheritsIsolation(
    actor: isolated LocalActor
) {
    let cl: @isolated(any) () -> Void = {
        _ = actor // captures isolated param → inherits actor isolation
    }
    _ = cl
}

// Case 4: Closure with isolated parameter does NOT capture it → nonisolated
private func closureWithIsolatedParam_noCaptureOfParam_becomesNonisolated(
    actor: isolated LocalActor
) {
    let cl: @isolated(any) () -> Void = {
        // no capture of isolated param → nonisolated
    }
    _ = cl
}

// Runtime verification functions via @isolated(any).isolation

// Actor-instance: with capture → .isolation returns the actor
private extension LocalActor {
    func closureActorInstanceCapture_withCapture_returnsActor() -> (any Actor)? {
        let cl: @isolated(any) () -> Void = {
            _ = self.state // captures self → isolated to this actor
        }
        return cl.isolation
    }
}

// Actor-instance: without capture → .isolation returns nil (nonisolated)
private extension LocalActor {
    func closureActorInstanceCapture_withoutCapture_returnsNil() -> (any Actor)? {
        let cl: @isolated(any) () -> Void = {
            // no capture → nonisolated
        }
        return cl.isolation
    }
}

// Isolated param: with capture → .isolation returns the actor
private func closureIsolatedParam_withCapture_returnsActor(
    actor: isolated LocalActor
) -> (any Actor)? {
    let cl: @isolated(any) () -> Void = {
        _ = actor // captures isolated param → inherits isolation
    }
    return cl.isolation
}

// Isolated param: without capture → .isolation returns nil
private func closureIsolatedParam_withoutCapture_returnsNil(
    actor: isolated LocalActor
) -> (any Actor)? {
    let cl: @isolated(any) () -> Void = {
        // no capture of isolated param → nonisolated
    }
    return cl.isolation
}

// Global actor (@MainActor): no capture needed — always inherits
@MainActor
package func closureGlobalActor_noCaptureNeeded_inheritsIsolation() -> (any Actor)? {
    let cl: @isolated(any) () -> Void = {
        // no capture needed for global actor — isolation is type-level
    }
    return cl.isolation
}

// Package-accessible wrapper for runtime tests
package func testClosureActorInstanceIsolationInference() async {
    let actor = LocalActor()

    // With capture: isolation should be the actor
    let withCapture = await actor.closureActorInstanceCapture_withCapture_returnsActor()
    assert(withCapture != nil, "Expected actor isolation when self is captured")
    assert(withCapture === actor, "Expected same actor instance")

    // Without capture: isolation should be nil (nonisolated)
    let withoutCapture = await actor.closureActorInstanceCapture_withoutCapture_returnsNil()
    assert(withoutCapture == nil, "Expected nil isolation when self is NOT captured")

    // Isolated param with capture
    let paramWithCapture = await closureIsolatedParam_withCapture_returnsActor(actor: actor)
    assert(paramWithCapture != nil, "Expected actor isolation when isolated param is captured")
    assert(paramWithCapture === actor, "Expected same actor instance")

    // Isolated param without capture
    let paramWithoutCapture = await closureIsolatedParam_withoutCapture_returnsNil(actor: actor)
    assert(paramWithoutCapture == nil, "Expected nil isolation when isolated param is NOT captured")
}

// =============================================================================
// MARK: - async let
// =============================================================================

// Helper: @MainActor async function for cross-isolation tests
@MainActor
private func mainActorAsyncIdentity(_ x: NonSendable) async -> NonSendable { x }

@MainActor
private func mainActorAsyncInt<T>(_ x: T) async -> Int { 0 }

// Helper: nonisolated async function
private func nonisolatedAsyncIdentity(_ x: NonSendable) async -> NonSendable { x }

private func nonisolatedAsyncInt<T>(_ x: T) async -> Int { 0 }

// [async-let] basic: async let captures disconnected ~Sendable and binds result
private func asyncLet_captureDisconnectedNonSendable_compiles() async {
    let x = NonSendable()
    async let y = nonisolatedAsyncInt(x)
    let _ = await y
    // After await, x is usable (undoSend in nonisolated case)
    _ = x.value
}

// [async-let] Sendable capture does not consume
private func asyncLet_sendableCapture_doesNotConsume() async {
    let s = MySendable()
    async let y = nonisolatedAsyncInt(s)
    _ = s.value   // ✅ Sendable capture is not consumed
    let _ = await y
    _ = s.value   // ✅ still accessible after await
}

// [async-let] bound variable type is T, not Task<T, ...>
private func asyncLet_resultTypeIsT_notTask() async {
    async let y: Int = nonisolatedAsyncInt(42)
    let result: Int = await y  // ✅ type of y is Int
    _ = result
}

// [async-let] async let result for NonSendable is disconnected
// The result can be re-captured by another async let (which requires disconnected for ~Sendable).
// Note: sending the result cross-isolation requires scope separation (do { async let ... }),
// because the SIL region analysis ties `result` and the async-let binding `y` to the same region
// within the same scope. Separating the scope severs this link.
private func asyncLet_nonSendableResult_isDisconnected() async {
    // Verify 1: result can be re-captured by another async let (disconnected required)
    async let y = nonisolatedAsyncIdentity(NonSendable())
    let result = await y
    async let z = nonisolatedAsyncInt(result)
    let _ = await z
}

// [async-let] scope-separated async let result can be sent cross-isolation
private func asyncLet_nonSendableResult_scopeSeparated_canSend() async {
    let result: NonSendable
    do {
        async let y: NonSendable = NonSendable()
        result = await y
    } // async let y goes out of scope → region link severed
    await OtherActor().useNonSendableSending(result) // ✅ disconnected → sendable
}

// [async-let] same-actor caller: captures still consumed (async let is always nonisolated boundary)
// Consumption verified by: NEGATIVE_ASYNCLET_CROSS_ISO_USE_AFTER_AWAIT
// (x is sent to @MainActor within child task → not restored by undoSend)
@MainActor
private func asyncLet_mainActorCaller_capturesConsumed() async {
    let x = NonSendable()
    async let y = mainActorAsyncInt(x)
    // NOTE: Unlike Task { ... } with @_inheritActorContext which can be noconsume
    // for same-actor, async let always acts as a nonisolated boundary.
    // Child task is nonisolated → calling mainActorAsyncInt is cross-isolation → x is consumed.
    let _ = await y
}

#if NEGATIVE_ASYNCLET_USE_BEFORE_AWAIT

// [async-let] use before await → error (data race between parent and child task)
private func negative_asyncLet_useBeforeAwait_isError() async {
    let x = NonSendable()
    async let y = nonisolatedAsyncInt(x)
    _ = x.value  // ❌ access can happen concurrently with child task
    let _ = await y
}

#endif

#if NEGATIVE_ASYNCLET_CROSS_ISO_USE_AFTER_AWAIT

// [async-let] cross-isolation send within body → use after await is also error
// undoSend does not restore x because x ∉ dom(Γ'_{child}) (consumed by cross-iso call)
private func negative_asyncLet_crossIsolation_useAfterAwait_isError() async {
    let x = NonSendable()
    async let y = mainActorAsyncInt(x)  // child: nonisolated → @MainActor (cross-iso)
    let _ = await y
    _ = x.value  // ❌ x was sent to MainActor within child task body
}

#endif

#if NEGATIVE_ASYNCLET_TASK_REGION_CAPTURE

// [async-let] task-region capture → error
// nonisolated async function parameter is at task region, not disconnected
private func negative_asyncLet_taskRegionCapture_isError(_ x: NonSendable) async {
    async let y = nonisolatedAsyncInt(x)  // ❌ task-region value cannot be sent to child task
    let _ = await y
}

#endif

#if NEGATIVE_ASYNCLET_ACTOR_BOUND_CAPTURE

// [async-let] actor-bound capture → error
// @MainActor global variable is at isolated(MainActor), not disconnected
@MainActor
private func negative_asyncLet_actorBoundCapture_isError() async {
    let g = mainActorConnectedVar  // g at isolated(MainActor)
    async let y = nonisolatedAsyncInt(g)  // ❌ actor-bound value cannot exit isolation context
    let _ = await y
}

#endif
