import Testing
@testable import concurrency_type_check

/// When a `~Sendable` value is captured in an `@isolated(any)` closure inside a `nonisolated async` function,
/// the task region is not an actor, so `.isolation` returns `nil`.
@Test func isolatedAnyIsolation_taskRegionCapture_isNil() async throws {
    let isolation = await isolatedAny_isolationProperty_taskRegionCapture_returnsNil()
    #expect(isolation == nil)
}

/// Converting `@MainActor () -> Void` → `@isolated(any) () -> Void` preserves
/// the actor identity, so `.isolation` returns `MainActor.shared`.
@Test func isolatedAnyIsolation_mainActorCapture_isMainActor() async throws {
    let isolation = await isolatedAny_isolationProperty_mainActorCapture_returnsMainActor()
    let main = try #require(isolation as? MainActor)
    #expect(main === MainActor.shared)
}

/// Going through `() -> Void` (nonisolated function type) erases the actor identity.
/// Coercing to `@isolated(any)` afterwards does not restore it, so `.isolation` returns `nil`.
@Test func isolatedAnyIsolation_mainActorCapture_plainClosureThenCoerce_isNil() async throws {
    let isolation = await isolatedAny_isolationProperty_mainActorCapture_returnsMainActor2()
    #expect(isolation == nil)
}

/// When an `@isolated(any) () -> Void` is created directly from a closure literal in a
/// `@MainActor` context, closure isolation inference preserves the actor identity,
/// so `.isolation` returns `MainActor.shared`.
@Test func isolatedAnyIsolation_mainActorCapture_isolatedAnyClosureLiteral_isMainActor() async throws {
    let isolation = await isolatedAny_isolationProperty_mainActorCapture_returnsMainActor3()
    let main = try #require(isolation as? MainActor)
    #expect(main === MainActor.shared)
}
