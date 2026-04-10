// SE-0418: Inferring Sendable for methods and key path literals
// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0418-inferring-sendable-for-methods.md
//
// Verifies 5 changes:
//   1. @Sendable inference for unapplied method references of Sendable types
//   2. @Sendable inference for partially-applied method references of Sendable types
//   3. @Sendable / & Sendable inference for KeyPath literals based on captures
//   4. @Sendable inference for non-local (global/static) function references
//   5. Prohibition of @Sendable on methods of non-Sendable types

// MARK: - Fixtures

private struct SendablePoint: Sendable {
    var value: Int
    func compute(_ x: Int) -> Int { value + x }
    static func staticCompute(_ x: Int) -> Int { x * 2 }
}

private class NonSendableCounter {
    var value: Int = 0
    func increment() { value += 1 }
    static func staticHelper() -> Int { 0 }
}

private struct UserProfile {
    var name: String
    @MainActor var age: Int { get { 0 } }
    subscript(info: NonSendableCounter) -> String { "entry" }
}

// MARK: - Section A: Non-local function references (SE-0418 change 4)
//
// Compiler: TypeOfReference.cpp:1013-1018
//   DC->isModuleScopeContext() → unconditionally @Sendable

private func topLevelCompute() -> Int { 42 }

private func inferSendable_nonlocal_topLevel() {
    let f = topLevelCompute
    let _: @Sendable () -> Int = f // ✅ top-level function is always @Sendable
}

private func inferSendable_nonlocal_static() {
    let f = SendablePoint.staticCompute
    let _: @Sendable (Int) -> Int = f // ✅ static method is always @Sendable
}

// Static method of non-Sendable type is also @Sendable
// Compiler: metatype is always Sendable → static methods always @Sendable
private func inferSendable_nonlocal_static_nonSendableType() {
    let f = NonSendableCounter.staticHelper
    let _: @Sendable () -> Int = f // ✅ static method is always @Sendable (metatype is Sendable)
}

// MARK: - Section B: Unapplied method references (SE-0418 change 1)
//
// Compiler: TypeOfReference.cpp:1019-1056
//   Outer type: ALWAYS @Sendable ("fully uncurried type doesn't capture anything")
//   Inner type: @Sendable only when T: Sendable (shouldMarkMemberTypeSendable)

private func inferSendable_method_sendableType() {
    let f = SendablePoint.compute
    // Both outer AND inner are @Sendable when T: Sendable
    let _: @Sendable (SendablePoint) -> @Sendable (Int) -> Int = f // ✅
}

private func inferSendable_method_nonSendableType() {
    let f = NonSendableCounter.increment
    // Outer is @Sendable (no capture), inner is NOT (captures non-Sendable self)
    let _: @Sendable (NonSendableCounter) -> () -> Void = f // ✅ outer @Sendable
}

#if NEGATIVE_UNAPPLIED_NON_SENDABLE_INNER
func negative_inferSendable_method_nonSendableType_inner() {
    let f = NonSendableCounter.increment
    // ❌ error: inner function captures non-Sendable self → cannot be @Sendable
    let _: @Sendable (NonSendableCounter) -> @Sendable () -> Void = f
}
#endif

// MARK: - Section C: KeyPath Sendable inference (SE-0418 change 3)
//
// Compiler: ConstraintSystem.cpp:5141-5324 (inferKeyPathLiteralCapability)
//   isSendable starts true, set to false when:
//   - Any captured argument is non-Sendable (line 5193)
//   - Any component is actor-isolated: ActorInstance or GlobalActor (line 5273-5275)

private func inferSendable_keypath_noCapture() {
    let kp = \UserProfile.name
    let _: WritableKeyPath<UserProfile, String> & Sendable = kp // ✅ no non-Sendable captures
}

private func inferSendable_keypath_functionConversion() {
    let _: @Sendable (UserProfile) -> String = \.name // ✅ KeyPath → @Sendable closure conversion
}

#if NEGATIVE_KEYPATH_ACTOR_ISOLATED
func negative_inferSendable_keypath_actorIsolated() {
    // ❌ error: actor-isolated property 'age' cannot be referenced from a Sendable key path
    let _: KeyPath<UserProfile, Int> & Sendable = \.age
}
#endif

#if NEGATIVE_KEYPATH_NON_SENDABLE_CAPTURE
func negative_inferSendable_keypath_nonSendableCapture() {
    let info = NonSendableCounter()
    // ❌ error: cannot form key path that captures non-sendable type
    let _: KeyPath<UserProfile, String> & Sendable = \UserProfile.[info]
}
#endif
