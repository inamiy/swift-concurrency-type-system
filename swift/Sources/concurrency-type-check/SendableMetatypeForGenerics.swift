// SendableMetatype rule: when a generic parameter carries a non-marker
// protocol conformance, its `T.Type` (= a metatype that ships a witness
// table) cannot be captured into a `@Sendable` closure.
//
// The check is per-conformance-witness, not per-generic-parameter:
//   - `actor A<State>`                                          → no witness          → no warning
//   - `actor A<State> where State: Equatable`                   → Equatable witness   → warning
//   - `actor A<State> where State: SendableMetatype & Equatable` → metatype is Sendable → no warning
//   - `actor A<State> where State: Sendable`                    → Sendable implies SendableMetatype → no warning
//
// Compiler implementation:
//   - lib/AST/ConformanceLookup.cpp: `metatypeWithInstanceTypeIsSendable`
//     Decides based on whether archetype->getConformsTo() contains any non-marker protocol.
//   - lib/Sema/TypeCheckConcurrency.cpp: `non_sendable_metatype_capture`
//     Filters captured archetypes of a `@Sendable` closure through
//     mayHaveIsolatedConformance, then diagnoses metatype sendability.
//   - stdlib/public/core/Sendable.swift:
//     `protocol Sendable: SendableMetatype, ~Copyable, ~Escapable { }`

// MARK: - Section A: Positive — no witness or SendableMetatype satisfied

/// With no conformance requirement on `State`, `State.Type` ships no
/// witness table and is therefore Sendable.
/// → Capturing self into a `@Sendable` closure raises no warning.
private actor ActorWithUnconstrainedGeneric<State> {
    var state: State

    init(_ state: State) {
        self.state = state
    }

    func detachToTask() {
        Task.detached { [self] in
            _ = self // ✅ State.Type has no witness, so it is Sendable
        }
    }
}

/// Requiring `State: SendableMetatype` guarantees `State.Type` is Sendable.
/// No warning even with another non-marker conformance such as `Equatable`.
private actor ActorWithSendableMetatypeAndEquatable<State> where State: SendableMetatype & Equatable {
    var state: State

    init(_ state: State) {
        self.state = state
    }

    func detachToTask() {
        Task.detached { [self] in
            _ = self // ✅ SendableMetatype directly guarantees metatype sendability
        }
    }
}

/// `State: Sendable` implies `SendableMetatype` via the inheritance
/// `Sendable: SendableMetatype`.
private actor ActorWithSendableState<State> where State: Sendable {
    var state: State

    init(_ state: State) {
        self.state = state
    }

    func detachToTask() {
        Task.detached { [self] in
            _ = self // ✅ Sendable ⇒ SendableMetatype ⇒ metatype is Sendable
        }
    }
}

// MARK: - Section B: Negative — non-marker witness without SendableMetatype

#if NEGATIVE_ACTOR_GENERIC_EQUATABLE_NO_SENDABLE_METATYPE
/// With only `State: Equatable`, the `Equatable` witness table can be
/// carried across the actor boundary, so capturing self into a `@Sendable`
/// closure is diagnosed.
private actor NegativeActorWithEquatableState<State> where State: Equatable {
    var state: State

    init(_ state: State) {
        self.state = state
    }

    func detachToTask() {
        Task.detached { [self] in
            _ = self // ❌ warning: capture of non-Sendable type 'State.Type' in an isolated closure
        }
    }
}
#endif

#if NEGATIVE_GENERIC_FUNC_PROTOCOL_NO_SENDABLE_METATYPE
private protocol HasG {
    static func g()
}

/// The same rule applies outside of actors — any `@Sendable` capture of a
/// generic parameter with a non-marker conformance is diagnosed.
private func negative_passMetaVal<T: HasG>(_: T.Type) {
    let x = T.self
    Task.detached {
        _ = x // ❌ warning: capture of non-Sendable type 'T.Type'
    }
}
#endif
