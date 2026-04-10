import Testing
@testable import concurrency_type_check

/// Closure in actor method that captures `self` → inherits actor-instance isolation.
/// Closure that does NOT capture → becomes nonisolated.
/// Global actor (@MainActor) always inherits without capture.
@Test func closureActorInstanceIsolation_captureInference() async {
    await testClosureActorInstanceIsolationInference()
}

/// Global actor: no capture needed for isolation inheritance.
@Test func closureGlobalActor_noCaptureNeeded() async {
    let isolation = await closureGlobalActor_noCaptureNeeded_inheritsIsolation()
    #expect(isolation != nil)
    #expect(isolation is MainActor)
}
