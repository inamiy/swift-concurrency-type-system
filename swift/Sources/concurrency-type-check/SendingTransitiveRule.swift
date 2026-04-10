// MARK: - Sending Transitive Rule (SE-0430)
// https://github.com/apple/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md

// Conversions from/to normal/sending/Sendable.

// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md
//
private enum ProposalExample {
    private static func sendingParameterConversions(
        f1: @escaping (sending NonSendable) -> Void,
        f2: @escaping (NonSendable) -> Void
    ) {
        let _: (sending NonSendable) -> Void = f1 // ✅ identity
        let _: (sending NonSendable) -> Void = f2 // ✅ (T -> Void) -> ((sending T) -> Void)
        //    let _: (NonSendable) -> Void = f1 // ❌
    }

    private static func sendingResultConversions(
        f1: @escaping () -> sending NonSendable,
        f2: @escaping () -> NonSendable
    ) {
        let _: () -> sending NonSendable = f1 // ✅ identity
        //    let _: () -> sending NonSendable = f2 // ❌
        let _: () -> NonSendable = f1 // ✅ sending T -> T
    }
}

// MARK: - Value conversion

private enum ValueConversion {
    // ✅ T -> T
    // ✅ T -> T where T: Sendable
    private static func normalToNormal<T>(_ x: T) -> T {
        x
    }

    // ❌ T -> sending T
//    private static func normalToSending<T>(_ x: T) -> sending T {
//        x
//    }

    // ✅ T -> sending T where T: Sendable
    private static func sendableToSending<T: Sendable>(_ x: T) -> sending T {
        x
    }

    // ✅ sending T -> T
    // ✅ sending T -> T where T: Sendable
    private static func sendingToNormal<T>(_ x: sending T) -> T {
        x
    }

    // ✅ sending T -> sending T
    // ✅ sending T -> sending T where T: Sendable
    private static func sendingToSending<T>(_ x: sending T) -> sending T {
        x
    }
}

// MARK: - Contravariant Closure conversion

private enum ContravariantClosureConversion {

    // MARK: From: `T -> Void`

    // ✅ (T -> Void) -> (T -> Void)
    // ✅ (T -> Void) -> (T -> Void) where T: Sendable
    private static func normalToNormal<T>(_ f: @escaping (T) -> Void) -> (T) -> Void {
        f
    }

    // ✅ (T -> Void) -> ((sending T) -> Void)
    // ✅ (T -> Void) -> ((sending T) -> Void) where T: Sendable
    private static func sendingToNormal<T>(_ f: @escaping (T) -> Void) -> (sending T) -> Void {
        f
    }

    // ❌ (T -> Void) -> (sending (T -> Void))
    // ❌ (T -> Void) -> (sending (T -> Void)) where T: Sendable
//    private static func sendingToNormal2<T: Sendable>(_ f: @escaping (T) -> Void) -> sending (T) -> Void {
//        f
//    }

    // ❌ ((T) -> Void) -> (@Sendable (T -> Void))
    // ❌ ((T) -> Void) -> (@Sendable (T -> Void)) where T: Sendable
//    private static func sendingToSendable<T: Sendable>(_ f: @escaping (T) -> Void) -> @Sendable (T) -> Void {
//        { f($0) }
//    }

    // MARK: From: `(sending T) -> Void`

    // ❌ ((sending T) -> Void) -> (T -> Void)
    //private static func sendingToNormal<T>(_ f: @escaping (sending T) -> Void) -> (T) -> Void {
    //    // f // ❌ Converting a value of type '(sending T) -> Void' to type '(T) -> Void' risks causing data races
    //
    //    { f($0) } // ❌ Sending '$0' risks causing data races
    //}

    // ✅ ((sending T) -> Void) -> (T -> Void) where T: Sendable
    private static func sendingToNormal<T: Sendable>(_ f: @escaping (sending T) -> Void) -> (T) -> Void {
        // ❌ Converting a value of type '(sending T) -> Void' to type '(T) -> Void' risks causing data races
        // Ideally, this should be coercible.
        //
        // f

        { f($0) } // ✅ OK: `$0` is Sendable
    }

    // ✅ ((sending T) -> Void) -> ((sending T) -> Void)
    // ✅ ((sending T) -> Void) -> ((sending T) -> Void) where T: Sendable
    private static func sendingToSending<T>(_ f: @escaping (sending T) -> Void) -> (sending T) -> Void {
        f
    }

    // ❌ ((sending T) -> Void) -> (sending (T -> Void))
    // ❌ ((sending T) -> Void) -> (sending (T -> Void)) where T: Sendable
//    private static func sendingToSending<T: Sendable>(_ f: @escaping (sending T) -> Void) -> sending (T) -> Void {
//        { f($0) }
//    }

    // ❌ ((sending T) -> Void) -> (@Sendable (T -> Void))
    // ❌ ((sending T) -> Void) -> (@Sendable (T -> Void)) where T: Sendable
//    private static func sendingToSendable<T: Sendable>(_ f: @escaping (sending T) -> Void) -> @Sendable (T) -> Void {
//        { f($0) }
//    }

    // MARK: From: `sending (T -> Void)`

    // ✅ (sending (T -> Void)) -> (T -> Void)
    // ✅ (sending (T -> Void)) -> (T -> Void) where T: Sendable
    private static func sendingToNormal<T>(_ f: sending @escaping (T) -> Void) -> (T) -> Void {
        f
    }

    // ✅ (sending (T -> Void)) -> ((sending T) -> Void)
    // ✅ (sending (T -> Void)) -> ((sending T) -> Void) where T: Sendable
    private static func sendingToSending<T>(_ f: sending @escaping (T) -> Void) -> (sending T) -> Void {
        f
    }

    // ✅ (sending (T -> Void)) -> (sending (T -> Void))
    // ✅ (sending (T -> Void)) -> (sending (T -> Void)) where T: Sendable
    private static func sendingToSending<T>(_ f: sending @escaping (T) -> Void) -> sending (T) -> Void {
        f
    }

    // ❌ (sending (T -> Void)) -> (@Sendable (T -> Void))
    // ❌ (sending (T -> Void)) -> (@Sendable (T -> Void)) where T: Sendable
//    private static func sendingToSendable<T: Sendable>(_ f: sending @escaping (T) -> Void) -> @Sendable (T) -> Void {
//        f
//    }
}

// MARK: - Covariant closure conversion

private enum CovariantClosureConversion {

    // MARK: From: `() -> T`

    // ✅ (() -> T) -> (() -> T)
    // ✅ (() -> T) -> (() -> T) where T: Sendable
    private static func normalToSending<T>(_ f: @escaping () -> T) -> () -> T {
        f
    }

    // ❌ (() -> T) -> (sending () -> T)
    // ❌ (() -> T) -> (sending () -> T) where T: Sendable
//    private static func normalToSending2<T: Sendable>(_ f: @escaping () -> T) -> sending () -> T {
//        f
//    }

    // ❌ (() -> T) -> (@Sendable () -> T)
    // ❌ (() -> T) -> (@Sendable () -> T) where T: Sendable
//    private static func normalToSendable<T: Sendable>(_ f: @escaping () -> T) -> @Sendable () -> T {
//        f
//    }

    // MARK: From: `sending (() -> T)`

    // ✅ (sending () -> T) -> (() -> T)
    // ✅ (sending () -> T) -> (() -> T) where T: Sendable
    private static func sendingToSendable<T>(_ f: sending @escaping () -> T) -> () -> T {
        f
    }

    // ✅ (sending () -> T) -> (sending () -> T)
    // ✅ (sending () -> T) -> (sending () -> T) where T: Sendable
    private static func sendingToSendable2<T>(_ f: sending @escaping () -> T) -> sending () -> T {
        f
    }

    // ❌ (sending () -> T) -> (@Sendable () -> T)
    // ❌ (sending () -> T) -> (@Sendable () -> T) where T: Sendable
//    private static func sendingToSendable<T: Sendable>(_ f: sending @escaping () -> T) -> @Sendable () -> T {
//        { f() }
//    }

    // MARK: From: `@Sendable (() -> T)`

    // ✅ (@Sendable () -> T) -> (() -> T)
    // ✅ (@Sendable () -> T) -> (() -> T) where T: Sendable
    private static func sendingToSendable<T>(_ f: @escaping @Sendable () -> T) -> () -> T {
        f
    }

    // ✅ (@Sendable () -> T) -> (sending () -> T)
    // ✅ (@Sendable () -> T) -> (sending () -> T) where T: Sendable
    private static func sendingToSendable2<T>(_ f: @escaping @Sendable () -> T) -> sending () -> T {
        f
    }

    // ✅ (@Sendable () -> T) -> (@Sendable () -> T)
    // ✅ (@Sendable () -> T) -> (@Sendable () -> T) where T: Sendable
    private static func sendingToSendable<T>(_ f: @escaping @Sendable () -> T) -> @Sendable () -> T {
        f
    }
}

// MARK: - Global / Local funcs

// SE-0418 "Inferring Sendable for methods and key path literals":
// Global free functions are implicitly @Sendable
private func globalNormalF() -> NonSendable { fatalError() }

@Sendable private func globalSendableF() -> NonSendable { fatalError() } // same as `globalNormalF`

private class LocalClass {
    private static func localNormalF() -> NonSendable { fatalError() }
    private static func localStaticNormalF() -> NonSendable { fatalError() }

    private static func test() {
        let f1 = globalNormalF
        let f2 = localNormalF
        let f3 = globalSendableF
        let f4 = Self.localStaticNormalF

        let _: @Sendable () -> NonSendable = f1 // ✅
        // let _: @Sendable () -> NonSendable = f2 // ❌
        let _: @Sendable () -> NonSendable = f3 // ✅
        let _: @Sendable () -> NonSendable = f4 // ✅
    }
}

// MARK: - `#isolation`

//----------------------------------------
// ✅ (A -> T) -> U ===> (A -> T) -> U
// ✅ (A -> T) -> U ===> (A -> T, #isolation) -> U
// ⚠️ (A -> T) -> U ===> (@isolated(any) A -> T) -> U
// ✅ (A -> T) -> U ===> (sending A -> T) -> U
// ✅ (A -> T) -> U ===> (@Sendable A -> T) -> U
// ✅ (A -> T, #isolation) -> U ===> (A -> T) -> U
// ✅ (A -> T, #isolation) -> U ===> (A -> T, #isolation) -> U
// ⚠️ (A -> T, #isolation) -> U ===> (@isolated(any) A -> T) -> U
// ✅ (A -> T, #isolation) -> U ===> (sending A -> T) -> U
// ✅ (A -> T, #isolation) -> U ===> (@Sendable A -> T) -> U
// ✅ (@isolated(any) A -> T) -> U ===> (A -> T) -> U
// ✅ (@isolated(any) A -> T) -> U ===> (A -> T, #isolation) -> U
// ✅ (@isolated(any) A -> T) -> U ===> (@isolated(any) A -> T) -> U
// ✅ (@isolated(any) A -> T) -> U ===> (sending A -> T) -> U
// ✅ (@isolated(any) A -> T) -> U ===> (@Sendable A -> T) -> U
// ❌ (sending A -> T) -> U ===> (A -> T) -> U
// ❌ (sending A -> T) -> U ===> (A -> T, #isolation) -> U
// ❌ (sending A -> T) -> U ===> (@isolated(any) A -> T) -> U
// ✅ (sending A -> T) -> U ===> (sending A -> T) -> U
// ✅ (sending A -> T) -> U ===> (@Sendable A -> T) -> U
// ❌ (@Sendable A -> T) -> U ===> (A -> T) -> U
// ❌ (@Sendable A -> T) -> U ===> (A -> T, #isolation) -> U
// ❌ (@Sendable A -> T) -> U ===> (@isolated(any) A -> T) -> U
// ❌ (@Sendable A -> T) -> U ===> (sending A -> T) -> U
// ✅ (@Sendable A -> T) -> U ===> (@Sendable A -> T) -> U
//
//    | From ↓ / To → | Normal | Isolation | IsolatedAny | Sending | Sendable |
//    |---------------|--------|-----------|-------------|---------|----------|
//    | Normal        | ✅ id  | ✅        | ⚠️          | ✅      | ✅       |
//    | Isolation     | ✅     | ✅ id     | ⚠️          | ✅      | ✅       |
//    | IsolatedAny   | ✅     | ✅        | ✅ id       | ✅      | ✅       |
//    | Sending       | ❌     | ❌        | ❌          | ✅ id   | ✅       |
//    | Sendable      | ❌     | ❌        | ❌          | ❌      | ✅ id    |
//
// NOTE: Same applies to async functions
//----------------------------------------

private enum IsolationMacroConversion {
    // ✅ (A -> T) -> U ===> (A -> T) -> U
    // ✅ (A -> T, #isolation) -> U ===> (A -> T) -> U
    // ✅ (@isolated(any) A -> T) -> U ===> (A -> T) -> U
    // ❌ (sending A -> T) -> U ===> (A -> T) -> U
    // ❌ (@Sendable A -> T) -> U ===> (A -> T) -> U
    private static func measureTime<A, T, U>(
        _ f: (A) -> T
    ) -> U {
        //    measureTime(f) // ✅ identity
        //    measureTimeIsolation(f) // ✅
        measureTimeIsolatedAny(f) // ✅
        //    measureTimeSending(f) // ❌
        //    measureTimeSendable(f) // ❌
    }

    // ✅ (A -> T) -> U ===> (A -> T, #isolation) -> U
    // ✅ (A -> T, #isolation) -> U ===> (A -> T, #isolation) -> U
    // ✅ (@isolated(any) A -> T) -> U ===> (A -> T, #isolation) -> U
    // ❌ (sending A -> T) -> U ===> (A -> T, #isolation) -> U
    // ❌ (@Sendable A -> T) -> U ===> (A -> T, #isolation) -> U
    private static func measureTimeIsolation<A, T, U>(
        _ f: (A) -> T,
        isolation: isolated (any Actor)? = #isolation
    ) -> U {
        //    measureTime(f) // ✅
        //    measureTimeIsolation(f) // ✅ identity
        measureTimeIsolatedAny(f) // ✅
        //    measureTimeSending(f) // ❌
        //    measureTimeSendable(f) // ❌
    }

    // ⚠️ (A -> T) -> U ===> (@isolated(any) A -> T) -> U
    // ⚠️ (A -> T, #isolation) -> U ===> (@isolated(any) A -> T) -> U
    // ✅ (@isolated(any) A -> T) -> U ===> (@isolated(any) A -> T) -> U
    // ❌ (sending A -> T) -> U ===> (@isolated(any) A -> T) -> U
    // ❌ (@Sendable A -> T) -> U ===> (@isolated(any) A -> T) -> U
    private static func measureTimeIsolatedAny<A, T, U>(
        _ f: @isolated(any) (A) -> T
    ) -> U {
        //    measureTime(f) // ⚠️ Error in future Swift
        //    measureTimeIsolation(f) // ⚠️ Error in future Swift
        measureTimeIsolatedAny(f) // ✅ identity
        //    measureTimeSending(f) // ❌
        //    measureTimeSendable(f) // ❌
    }

    // ✅ (A -> T) -> U ===> (sending A -> T) -> U
    // ✅ (A -> T, #isolation) -> U ===> (sending A -> T) -> U
    // ✅ (@isolated(any) A -> T) -> U ===> (sending A -> T) -> U
    // ✅ (sending A -> T) -> U ===> (sending A -> T) -> U
    // ❌ (@Sendable A -> T) -> U ===> (sending A -> T) -> U
    private static func measureTimeSending<A, T, U>(
        _ f: sending (A) -> T
    ) -> U {
        //    measureTime(f) // ✅
        //    measureTimeIsolation(f) // ✅
        measureTimeIsolatedAny(f) // ✅
        //    measureTimeSending(f) // ✅ identity
        //    measureTimeSendable(f) // ❌
    }

    // ✅ (A -> T) -> U ===> (@Sendable A -> T) -> U
    // ✅ (A -> T, #isolation) -> U ===> (@Sendable A -> T) -> U
    // ✅ (@isolated(any) A -> T) -> U ===> (@Sendable A -> T) -> U
    // ✅ (sending A -> T) -> U ===> (@Sendable A -> T) -> U
    // ✅ (@Sendable A -> T) -> U ===> (@Sendable A -> T) -> U
    private static func measureTimeSendable<A, T, U>(
        _ f: @Sendable (A) -> T
    ) -> U {
        //    measureTime(f) // ✅
        //    measureTimeIsolation(f) // ✅
        measureTimeIsolatedAny(f) // ✅
        //    measureTimeSending(f) // ✅
        //    measureTimeSendable(f) // ✅ identity
    }
}
