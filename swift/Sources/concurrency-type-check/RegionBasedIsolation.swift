// MARK: - Region-based Isolation
// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md

private func actorImplicitSending() async {
    let ns = NonSendable()
    let actor = MyActor()
//    let actor = MyActor(ns: ns)

    await actor.receive(ns: ns) // sending to actor

    // ns.value = 10 // Not allowed
}

private func classNonsending() async {
    let ns = NonSendable()
    let cls = MyClass()
//    let cls = MyClass(ns: ns)

    cls.receive(ns: ns) // non-sending to class

    ns.value = 10 // allowed
}

private func nonIsolatedCallee(_ x: NonSendable) async {}

private func nonIsolatedCaller(_ x: NonSendable) async {
    // Regions: [{(x), Task1}]

    // Not a transfer! Same Task!
    await nonIsolatedCallee(x)

    // ❌ Error!
    // await transferToMainActor(x)
}

// MARK: - Private

private actor MyActor {
    init(ns: NonSendable = .init()) {}

    // In actor, params are implicitly 'sending'.
    func receive(ns: NonSendable) {}
}

private class MyClass {
    init(ns: NonSendable = .init()) {}

    /// `nonisolated` async functions have no persistent isolated state, so the value "comes back" after the call (non-sending)
    func receive(ns: NonSendable) {}
}

@MainActor private func transferToMainActor(_ x: NonSendable) async {}
