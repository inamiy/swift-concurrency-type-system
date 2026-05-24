// =============================================================================
// MARK: - `sending` return value: same-isolation and cross-isolation
// =============================================================================
//
// Reproduces the two examples from the Swift Forums thread
// "Region-based isolation, sending return value, actor isolation – expected behavior?"
// https://forums.swift.org/t/region-based-isolation-sending-return-value-actor-isolation-what-is-the-expected-behavior/75455
//
// At the time of the post, the compiler rejected both examples. Under Swift 6.2+
// the `sending` annotation on the return value is honored in both same- and
// cross-isolation calls, so a `~Sendable` result is observed as `disconnected`
// at the call site and can be re-sent to another actor.
//
// - Example 1 corresponds to a new rule [call-same-sending-result]
//   (same isolation, `sending` return → `disconnected`).
// - Example 2 corresponds to the existing [call-cross-sending-result] rule
//   (cross isolation, `sending` return → `disconnected`).

// MARK: - Example 1: same-isolation `sending` result inside an actor body

// [call-same-sending-result] @κ = @ι = @A, sending result is disconnected
private actor ForumSameIsoActor {
    func makeValue() -> sending NonSendable {
        NonSendable()
    }

    @MainActor
    func sendToMain(_ value: NonSendable) {
        _ = value.value
    }

    // Calling `makeValue()` from the same actor body is a same-isolation call
    // (@κ = @ι = @A). The `sending` annotation on the result forces the
    // call-site region of `v` to be `disconnected`, so the subsequent
    // cross-isolation transfer `await sendToMain(v)` succeeds.
    func makeAndSend() async {
        let v = makeValue()       // ✅ v at disconnected (sending result)
        await sendToMain(v)       // ✅ disconnected → @MainActor (implicit transfer)
    }
}

// MARK: - Example 2: cross-isolation `sending` result from a global-actor type

@globalActor
private actor ForumGlobalActor {
    static let shared = ForumGlobalActor()
}

@ForumGlobalActor
private struct ForumGlobalActorBox {
    func getNonSendable() -> sending NonSendable {
        NonSendable()
    }
}

@MainActor
private func forumOnMain(_ value: NonSendable) {
    _ = value.value
}

// [call-cross-sending-result] @κ = @nonisolated, @ι = @ForumGlobalActor
nonisolated private func forumCrossIsoSendingResult_compiles(box: ForumGlobalActorBox) async {
    let ns = await box.getNonSendable() // ✅ cross-iso sending result → disconnected
    await forumOnMain(ns)               // ✅ disconnected → @MainActor (implicit transfer)
}

// MARK: - Negative: same-iso, non-`sending` result → bound to actor region

#if NEGATIVE_SAME_ISO_NON_SENDING_RESULT

private actor ForumSameIsoActor_NoSending {
    // No `sending` on result → falls back to [call-same-nonsendable-merge]
    // and the freshly-created value is bound to `isolated(self)`.
    func makeValue() -> NonSendable {
        NonSendable()
    }

    @MainActor
    func sendToMain(_ value: NonSendable) {
        _ = value.value
    }

    func makeAndSend() async {
        let v = makeValue()       // v at isolated(self) (no `sending`)
        await sendToMain(v)       // ❌ sending 'v' risks causing data races
    }
}

#endif

// MARK: - Negative: cross-iso, non-`sending` result → compile error

#if NEGATIVE_CROSS_ISO_NON_SENDING_RESULT

@ForumGlobalActor
private struct ForumGlobalActorBox_NoSending {
    func getNonSendable() -> NonSendable {
        NonSendable()
    }
}

nonisolated private func negative_forumCrossIso_nonSendingResult_isError(
    box: ForumGlobalActorBox_NoSending
) async {
    // ❌ non-Sendable result crosses isolation boundary without `sending`
    let ns = await box.getNonSendable()
    await forumOnMain(ns)
}

#endif
