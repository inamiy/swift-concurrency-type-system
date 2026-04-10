import Foundation

// MARK: - Sync Conversion

private enum SyncFuncConversion {
    /// Sync conversion test using closure wrapping (without `@MainActor` on outer function).
    ///
    /// - For `@MainActor` sources: inner closure must also be `@MainActor` isolated
    /// - For `@isolated(any)` sources: cannot call synchronously from nonisolated context
    ///
    /// This demonstrates the difference between:
    /// - Type coercion (assignment): changes the "view" of the function type
    /// - Manual wrapping: creates a NEW closure that must satisfy call-site requirements
    private enum CompileSyncConversionTest {
        // MARK: Source: normal

        // ✅ normal -> normal
        func normalToNormal(_ f: @escaping () -> Void) -> () -> Void {
            f
        }

        //    // ❌ normal -> @Sendable
        //    func normalToSendable(_ f: @escaping () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ normal -> @MainActor
        //    func normalToMainActor(_ f: @escaping () -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ normal -> @MainActor @Sendable
        //    func normalToMainActorSendable(_ f: @escaping () -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ normal -> @isolated(any)
        func normalToIsolatedAny(_ f: @escaping () -> Void) -> @isolated(any) () -> Void {
            f
        }

        //    // ❌ normal -> @isolated(any) @Sendable
        //    func normalToIsolatedAnySendable(_ f: @escaping () -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ normal -> isolated LocalActor
        //    func normalToNormal(_ f: @escaping () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ normal -> isolated LocalActor @Sendable
        //    func normalToNormal(_ f: @escaping () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @Sendable

        // ✅ @Sendable -> normal
        func sendableToNormal(_ f: @escaping @Sendable () -> Void) -> () -> Void {
            f
        }

        // ✅ @Sendable -> @Sendable
        func sendableToSendable(_ f: @escaping @Sendable () -> Void) -> @Sendable () -> Void {
            f
        }

        // ✅ @Sendable -> @MainActor
        func sendableToMainActor(_ f: @escaping @Sendable () -> Void) -> @MainActor () -> Void {
            f
        }

        // ✅ @Sendable -> @MainActor @Sendable
        func sendableToMainActorSendable(_ f: @escaping @Sendable () -> Void) -> @MainActor @Sendable () -> Void {
            f
        }

        // ✅ @Sendable -> @isolated(any)
        func sendableToIsolatedAny(_ f: @escaping @Sendable () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @Sendable -> @isolated(any) @Sendable
        func sendableToIsolatedAnySendable(_ f: @escaping @Sendable () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        // ✅ @Sendable -> isolated LocalActor
        func sendableToIsolatedLocalActor(_ f: @escaping @Sendable () -> Void) -> (isolated LocalActor) -> Void {
            { _ in f() }
        }

        // ✅ @Sendable -> isolated LocalActor @Sendable
        func sendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable () -> Void) -> @Sendable (isolated LocalActor) -> Void {
            { _ in f() }
        }

        // MARK: Source: @MainActor

        //    // ❌ @MainActor -> normal
        //    func mainActorToNormal(_ f: @escaping @MainActor () -> Void) -> () -> Void {
        //        { f() }
        //    }

        //    // ❌ @MainActor -> @Sendable
        //    func mainActorToSendable(_ f: @escaping @MainActor () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @MainActor -> @MainActor
        func mainActorToMainActor(_ f: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
            f
        }

        // ✅ @MainActor -> @MainActor @Sendable
        func mainActorToMainActorSendable(_ f: @escaping @MainActor () -> Void) -> @MainActor @Sendable () -> Void {
            f
        }

        // ✅ @MainActor -> @isolated(any)
        func mainActorToIsolatedAny(_ f: @escaping @MainActor () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @MainActor -> @isolated(any) @Sendable
        func mainActorToIsolatedAnySendable(_ f: @escaping @MainActor () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        //    // ❌ @MainActor -> isolated LocalActor
        //    func mainActorToIsolatedLocalActor(_ f: @escaping @MainActor () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @MainActor -> isolated LocalActor @Sendable
        //    func mainActorToIsolatedLocalActorSendable(_ f: @escaping @MainActor () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @MainActor @Sendable

        //    // ❌ @MainActor @Sendable -> normal
        //    func mainActorSendableToNormal(_ f: @escaping @MainActor @Sendable () -> Void) -> () -> Void {
        //        { f() }
        //    }

        //    // ❌ @MainActor @Sendable -> @Sendable
        //    func mainActorSendableToSendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @MainActor @Sendable -> @MainActor
        func mainActorSendableToMainActor(_ f: @escaping @MainActor @Sendable () -> Void) -> @MainActor () -> Void {
            f
        }

        // ✅ @MainActor @Sendable -> @MainActor @Sendable
        func mainActorSendableToMainActorSendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @MainActor @Sendable () -> Void {
            f
        }

        // ✅ @MainActor @Sendable -> @isolated(any)
        func mainActorSendableToIsolatedAny(_ f: @escaping @MainActor @Sendable () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @MainActor @Sendable -> @isolated(any) @Sendable
        func mainActorSendableToIsolatedAnySendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        //    // ❌ @MainActor @Sendable -> isolated LocalActor
        //    func mainActorSendableToIsolatedLocalActor(_ f: @escaping @MainActor @Sendable () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @MainActor @Sendable -> isolated LocalActor @Sendable
        //    func mainActorSendableToIsolatedLocalActorSendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @isolated(any)

        // ⚠️ @isolated(any) -> normal (warning: will be error in future Swift)
        func isolatedAnyToNormal(_ f: @escaping @isolated(any) () -> Void) -> () -> Void {
            f // Direct coercion (with warning)

            // ERROR: Call to @isolated(any) parameter 'f' in a synchronous nonisolated context
            // { f() }
        }

        //    // ❌ @isolated(any) -> @Sendable
        //    func isolatedAnyToSendable(_ f: @escaping @isolated(any) () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) -> @MainActor
        //    func isolatedAnyToMainActor(_ f: @escaping @isolated(any) () -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) -> @MainActor @Sendable
        //    func isolatedAnyToMainActorSendable(_ f: @escaping @isolated(any) () -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @isolated(any) -> @isolated(any)
        func isolatedAnyToIsolatedAny(_ f: @escaping @isolated(any) () -> Void) -> @isolated(any) () -> Void {
            f
        }

        //    // ❌ @isolated(any) -> @isolated(any) @Sendable
        //    func isolatedAnyToIsolatedAnySendable(_ f: @escaping @isolated(any) () -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) -> isolated LocalActor
        //    func isolatedAnyToIsolatedLocalActor(_ f: @escaping @isolated(any) () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @isolated(any) -> isolated LocalActor @Sendable
        //    func isolatedAnyToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @isolated(any) @Sendable

        // ⚠️ @isolated(any) @Sendable -> normal (warning: will be error in future Swift)
        func isolatedAnySendableToNormal(_ f: @escaping @isolated(any) @Sendable () -> Void) -> () -> Void {
            f // Direct coercion (warning: will be error in future Swift)

            // { f() } // ERROR: explict closure wrapping https://github.com/swiftlang/swift/issues/86055
        }

        // ⚠️ @isolated(any) @Sendable -> @Sendable (warning: will be error in future Swift)
        func isolatedAnySendableToSendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @Sendable () -> Void {
            f // Direct coercion (warning: will be error in future Swift)

            // { f() } // ERROR: explict closure wrapping https://github.com/swiftlang/swift/issues/86055
        }

        //    // ❌ @isolated(any) @Sendable -> @MainActor
        //    func isolatedAnySendableToMainActor(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) @Sendable -> @MainActor @Sendable
        //    func isolatedAnySendableToMainActorSendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @isolated(any) @Sendable -> @isolated(any)
        func isolatedAnySendableToIsolatedAny(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable -> @isolated(any) @Sendable
        func isolatedAnySendableToIsolatedAnySendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        //    // ❌ @isolated(any) @Sendable -> isolated LocalActor
        //    func isolatedAnySendableToIsolatedLocalActor(_ f: @escaping @isolated(any) @Sendable () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @isolated(any) @Sendable -> isolated LocalActor @Sendable
        //    func isolatedAnySendableToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: isolated LocalActor

        //    // ❌ isolated LocalActor -> normal
        //    func isolatedLocalActorToNormal(_ f: @escaping (isolated LocalActor) -> Void) -> () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @Sendable
        //    func isolatedLocalActorToSendable(_ f: @escaping (isolated LocalActor) -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @MainActor
        //    func isolatedLocalActorToMainActor(_ f: @escaping (isolated LocalActor) -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @MainActor @Sendable
        //    func isolatedLocalActorToMainActorSendable(_ f: @escaping (isolated LocalActor) -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @isolated(any)
        //    func isolatedLocalActorToIsolatedAny(_ f: @escaping (isolated LocalActor) -> Void) -> @isolated(any) () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @isolated(any) @Sendable
        //    func isolatedLocalActorToIsolatedAnySendable(_ f: @escaping (isolated LocalActor) -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ isolated LocalActor -> isolated LocalActor
        func isolatedLocalActorToIsolatedLocalActor(_ f: @escaping (isolated LocalActor) -> Void) -> (isolated LocalActor) -> Void {
            f
        }

        //    // ❌ isolated LocalActor -> isolated LocalActor @Sendable
        //    func isolatedLocalActorToIsolatedLocalActorSendable(_ f: @escaping (isolated LocalActor) -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { actor in f(actor) }
        //    }

        // MARK: Source: isolated LocalActor @Sendable

        //    // ❌ isolated LocalActor @Sendable -> normal
        //    func isolatedLocalActorSendableToNormal(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @Sendable
        //    func isolatedLocalActorSendableToSendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @MainActor
        //    func isolatedLocalActorSendableToMainActor(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @MainActor @Sendable
        //    func isolatedLocalActorSendableToMainActorSendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @isolated(any)
        //    func isolatedLocalActorSendableToIsolatedAny(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @isolated(any) () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @isolated(any) @Sendable
        //    func isolatedLocalActorSendableToIsolatedAnySendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ isolated LocalActor @Sendable -> isolated LocalActor
        func isolatedLocalActorSendableToIsolatedLocalActor(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> (isolated LocalActor) -> Void {
            f
        }

        // ✅ isolated LocalActor @Sendable -> isolated LocalActor @Sendable
        func isolatedLocalActorSendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @Sendable (isolated LocalActor) -> Void {
            f
        }
    }

    /// Sync conversion test with `@MainActor` on each inner function.
    /// This tests if isolation context affects conversion rules.
    ///
    /// ## ❌ to ✅ Changes (4 cases)
    ///
    /// | Conversion                                        | Original | @MainActor | Reason |
    /// |---------------------------------------------------|----------|------------|--------|
    /// | `normal -> @MainActor`                            | ❌       | ✅         | Requires closure wrapping `{ f() }`. Inner closure inherits @MainActor isolation, allowing non-Sendable `f` capture. |
    /// | `normal -> @MainActor @Sendable`                  | ❌       | ✅         | Same reason |
    /// | `@MainActor -> normal`                            | ❌       | ✅         | Direct coercion `f` works. @MainActor func context allows the conversion. |
    /// | `@MainActor @Sendable -> normal`                  | ❌       | ✅         | Same reason |
    ///
    /// ## ✅ to ❌ Changes (0 cases)
    ///
    /// None! All original ✅ conversions remain ✅ with `@MainActor` on the outer function.
    ///
    /// ## Key Insight
    ///
    /// - `normal -> @MainActor*`: Requires closure wrapping `{ f() }` (direct coercion `f` fails)
    /// - `@MainActor* -> normal` or `@MainActor* -> @isolated(any) @Sendable`: Direct coercion `f` works
    private enum CompileSyncConversionTest_MainActor {
        // MARK: Source: normal

        // ✅ normal -> normal
        @MainActor func normalToNormal(_ f: @escaping () -> Void) -> () -> Void {
            f
        }

        // ❌ normal -> @Sendable
        //    @MainActor func normalToSendable(_ f: @escaping () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ normal -> @MainActor (was ❌ without @MainActor on func, requires closure wrapping)
        @MainActor func normalToMainActor(_ f: @escaping () -> Void) -> @MainActor () -> Void {
            // ERROR: Using non-Sendable parameter 'f' in a context expecting a '@Sendable' closure
            // f

            { f() } // Explicit closure wrapping.
        }

        // ✅ normal -> @MainActor @Sendable (was ❌ without @MainActor on func, requires closure wrapping)
        @MainActor func normalToMainActorSendable(_ f: @escaping () -> Void) -> @MainActor @Sendable () -> Void {
            // ERROR: Using non-Sendable parameter 'f' in a context expecting a '@Sendable' closure
            // f

            { f() } // Explicit closure wrapping.
        }

        // ✅ normal -> @isolated(any)
        @MainActor func normalToIsolatedAny(_ f: @escaping () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ❌ normal -> @isolated(any) @Sendable
        //    @MainActor func normalToIsolatedAnySendable(_ f: @escaping () -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ normal -> isolated LocalActor
        //    @MainActor func sendableToIsolatedLocalActor(_ f: @escaping () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ normal -> isolated LocalActor @Sendable
        //    @MainActor func sendableToIsolatedLocalActorSendable(_ f: @escaping () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @Sendable

        // ✅ @Sendable -> normal
        @MainActor func sendableToNormal(_ f: @escaping @Sendable () -> Void) -> () -> Void {
            f
        }

        // ✅ @Sendable -> @Sendable
        @MainActor func sendableToSendable(_ f: @escaping @Sendable () -> Void) -> @Sendable () -> Void {
            f
        }

        // ✅ @Sendable -> @MainActor
        @MainActor func sendableToMainActor(_ f: @escaping @Sendable () -> Void) -> @MainActor () -> Void {
            f
        }

        // ✅ @Sendable -> @MainActor @Sendable
        @MainActor func sendableToMainActorSendable(_ f: @escaping @Sendable () -> Void) -> @MainActor @Sendable () -> Void {
            f
        }

        // ✅ @Sendable -> @isolated(any)
        @MainActor func sendableToIsolatedAny(_ f: @escaping @Sendable () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @Sendable -> @isolated(any) @Sendable
        @MainActor func sendableToIsolatedAnySendable(_ f: @escaping @Sendable () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        // ✅ @Sendable -> isolated LocalActor
        @MainActor func sendableToIsolatedLocalActor(_ f: @escaping @Sendable () -> Void) -> (isolated LocalActor) -> Void {
            { _ in f() }
        }

        // ✅ @Sendable -> isolated LocalActor @Sendable
        @MainActor func sendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable () -> Void) -> @Sendable (isolated LocalActor) -> Void {
            { _ in f() }
        }

        // MARK: Source: @MainActor

        // ✅ @MainActor -> normal (was ❌ without @MainActor on func)
        @MainActor func mainActorToNormal(_ f: @escaping @MainActor () -> Void) -> () -> Void {
            f
        }

        // ❌ @MainActor -> @Sendable
        //    @MainActor func mainActorToSendable(_ f: @escaping @MainActor () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @MainActor -> @MainActor
        @MainActor func mainActorToMainActor(_ f: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
            f
        }

        // ✅ @MainActor -> @MainActor @Sendable
        @MainActor func mainActorToMainActorSendable(_ f: @escaping @MainActor () -> Void) -> @MainActor @Sendable () -> Void {
            f
        }

        // ✅ @MainActor -> @isolated(any)
        @MainActor func mainActorToIsolatedAny(_ f: @escaping @MainActor () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @MainActor -> @isolated(any) @Sendable
        @MainActor func mainActorToIsolatedAnySendable(_ f: @escaping @MainActor () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        //    // ❌ @MainActor -> isolated LocalActor
        //    @MainActor func mainActorToIsolatedLocalActor(_ f: @escaping @MainActor () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @MainActor -> isolated LocalActor @Sendable
        //    @MainActor func mainActorToIsolatedLocalActorSendable(_ f: @escaping @MainActor () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @MainActor @Sendable

        // ✅ @MainActor @Sendable -> normal (was ❌ without @MainActor on func)
        @MainActor func mainActorSendableToNormal(_ f: @escaping @MainActor @Sendable () -> Void) -> () -> Void {
            f
        }

        // ❌ @MainActor @Sendable -> @Sendable
        //    @MainActor func mainActorSendableToSendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @MainActor @Sendable -> @MainActor
        @MainActor func mainActorSendableToMainActor(_ f: @escaping @MainActor @Sendable () -> Void) -> @MainActor () -> Void {
            f
        }

        // ✅ @MainActor @Sendable -> @MainActor @Sendable
        @MainActor func mainActorSendableToMainActorSendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @MainActor @Sendable () -> Void {
            f
        }

        // ✅ @MainActor @Sendable -> @isolated(any)
        @MainActor func mainActorSendableToIsolatedAny(_ f: @escaping @MainActor @Sendable () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @MainActor @Sendable -> @isolated(any) @Sendable
        @MainActor func mainActorSendableToIsolatedAnySendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        //    // ❌ @MainActor @Sendable -> isolated LocalActor
        //    @MainActor func mainActorSendableToIsolatedLocalActor(_ f: @escaping @MainActor @Sendable () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @MainActor @Sendable -> isolated LocalActor @Sendable
        //    @MainActor func mainActorSendableToIsolatedLocalActorSendable(_ f: @escaping @MainActor @Sendable () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @isolated(any)

        // ⚠️ @isolated(any) -> normal (warning: will be error in future Swift)
        @MainActor func isolatedAnyToNormal(_ f: @escaping @isolated(any) () -> Void) -> () -> Void {
            f // Direct coercion (warning: will be error in future Swift)

            // { f() } // ERROR: explict closure wrapping https://github.com/swiftlang/swift/issues/86055
        }

        //    // ❌ @isolated(any) -> @Sendable
        //    @MainActor func isolatedAnyToSendable(_ f: @escaping @isolated(any) () -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) -> @MainActor
        //    @MainActor func isolatedAnyToMainActor(_ f: @escaping @isolated(any) () -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) -> @MainActor @Sendable
        //    @MainActor func isolatedAnyToMainActorSendable(_ f: @escaping @isolated(any) () -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @isolated(any) -> @isolated(any)
        @MainActor func isolatedAnyToIsolatedAny(_ f: @escaping @isolated(any) () -> Void) -> @isolated(any) () -> Void {
            f
        }

        //    // ❌ @isolated(any) -> @isolated(any) @Sendable
        //    @MainActor func isolatedAnyToIsolatedAnySendable(_ f: @escaping @isolated(any) () -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) -> isolated LocalActor
        //    @MainActor func isolatedAnyToIsolatedLocalActor(_ f: @escaping @isolated(any) () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @isolated(any) -> isolated LocalActor @Sendable
        //    @MainActor func isolatedAnyToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: @isolated(any) @Sendable

        // ⚠️ @isolated(any) @Sendable -> normal (warning: will be error in future Swift)
        @MainActor func isolatedAnySendableToNormal(_ f: @escaping @isolated(any) @Sendable () -> Void) -> () -> Void {
            f // Direct coercion (warning: will be error in future Swift)
        }

        // ⚠️ @isolated(any) @Sendable -> @Sendable (warning: will be error in future Swift)
        @MainActor func isolatedAnySendableToSendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @Sendable () -> Void {
            f // Direct coercion (warning: will be error in future Swift)
        }

        //    // ❌ @isolated(any) @Sendable -> @MainActor
        //    @MainActor func isolatedAnySendableToMainActor(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ @isolated(any) @Sendable -> @MainActor @Sendable
        //    @MainActor func isolatedAnySendableToMainActorSendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ @isolated(any) @Sendable -> @isolated(any)
        @MainActor func isolatedAnySendableToIsolatedAny(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @isolated(any) () -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable -> @isolated(any) @Sendable
        @MainActor func isolatedAnySendableToIsolatedAnySendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @isolated(any) @Sendable () -> Void {
            f
        }

        //    // ❌ @isolated(any) @Sendable -> isolated LocalActor
        //    @MainActor func isolatedAnySendableToIsolatedLocalActor(_ f: @escaping @isolated(any) @Sendable () -> Void) -> (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        //    // ❌ @isolated(any) @Sendable -> isolated LocalActor @Sendable
        //    @MainActor func isolatedAnySendableToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { _ in f() }
        //    }

        // MARK: Source: isolated LocalActor

        //    // ❌ isolated LocalActor -> normal
        //    @MainActor func isolatedLocalActorToNormal(_ f: @escaping (isolated LocalActor) -> Void) -> () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @Sendable
        //    @MainActor func isolatedLocalActorToSendable(_ f: @escaping (isolated LocalActor) -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @MainActor
        //    @MainActor func isolatedLocalActorToMainActor(_ f: @escaping (isolated LocalActor) -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @MainActor @Sendable
        //    @MainActor func isolatedLocalActorToMainActorSendable(_ f: @escaping (isolated LocalActor) -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @isolated(any)
        //    @MainActor func isolatedLocalActorToIsolatedAny(_ f: @escaping (isolated LocalActor) -> Void) -> @isolated(any) () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor -> @isolated(any) @Sendable
        //    @MainActor func isolatedLocalActorToIsolatedAnySendable(_ f: @escaping (isolated LocalActor) -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ isolated LocalActor -> isolated LocalActor
        @MainActor func isolatedLocalActorToIsolatedLocalActor(_ f: @escaping (isolated LocalActor) -> Void) -> (isolated LocalActor) -> Void {
            f
        }

        //    // ❌ isolated LocalActor -> isolated LocalActor @Sendable
        //    @MainActor func isolatedLocalActorToIsolatedLocalActorSendable(_ f: @escaping (isolated LocalActor) -> Void) -> @Sendable (isolated LocalActor) -> Void {
        //        { actor in f(actor) }
        //    }

        // MARK: Source: isolated LocalActor @Sendable

        //    // ❌ isolated LocalActor @Sendable -> normal
        //    @MainActor func isolatedLocalActorSendableToNormal(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @Sendable
        //    @MainActor func isolatedLocalActorSendableToSendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @MainActor
        //    @MainActor func isolatedLocalActorSendableToMainActor(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @MainActor () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @MainActor @Sendable
        //    @MainActor func isolatedLocalActorSendableToMainActorSendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @MainActor @Sendable () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @isolated(any)
        //    @MainActor func isolatedLocalActorSendableToIsolatedAny(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @isolated(any) () -> Void {
        //        { f() }
        //    }

        //    // ❌ isolated LocalActor @Sendable -> @isolated(any) @Sendable
        //    @MainActor func isolatedLocalActorSendableToIsolatedAnySendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @isolated(any) @Sendable () -> Void {
        //        { f() }
        //    }

        // ✅ isolated LocalActor @Sendable -> isolated LocalActor
        @MainActor func isolatedLocalActorSendableToIsolatedLocalActor(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> (isolated LocalActor) -> Void {
            f
        }

        // ✅ isolated LocalActor @Sendable -> isolated LocalActor @Sendable
        @MainActor func isolatedLocalActorSendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable (isolated LocalActor) -> Void) -> @Sendable (isolated LocalActor) -> Void {
            f
        }
    }
}

// MARK: - Async Conversion

private enum AsyncFuncConversion {
    /// Async conversion test using closure wrapping.
    ///
    /// NOTE: Unlike sync, async functions allow runtime actor hopping via suspension.
    /// This enables more conversions (e.g., @MainActor async -> normal async).
    ///
    /// For @MainActor sources: inner closure uses `{ @MainActor in await f() }`
    /// For @isolated(any) sources: can use direct coercion `f` since async preserves isolation at runtime
    /// For @concurrent sources: inner closure uses `{ await f() }` (nonisolated)
    private enum CompileAsyncConversionTest {
        // MARK: Source: normal async

        // ✅ normal async -> normal async
        func normalToNormal(_ f: @escaping () async -> Void) -> () async -> Void {
            f
        }

        //    // ❌ normal async -> @Sendable async
        //    func normalToSendable(_ f: @escaping () async -> Void) -> @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ normal async -> @MainActor async
        //    func normalToMainActor(_ f: @escaping () async -> Void) -> @MainActor () async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //        { await f() }
        //    }

        //    // ❌ normal async -> @MainActor @Sendable async
        //    func normalToMainActorSendable(_ f: @escaping () async -> Void) -> @MainActor @Sendable () async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //        { await f() }
        //    }

        // ✅ normal async -> @concurrent async
        func normalToConcurrent(_ f: @escaping () async -> Void) -> @concurrent () async -> Void {
            f
        }

        //    // ❌ normal async -> @concurrent @Sendable async
        //    func normalToConcurrentSendable(_ f: @escaping () async -> Void) -> @concurrent @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ normal async -> @isolated(any) async
        func normalToIsolatedAny(_ f: @escaping () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        //    // ❌ normal async -> @isolated(any) @Sendable async
        //    func normalToIsolatedAnySendable(_ f: @escaping () async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ normal async -> isolated LocalActor async
        //    func normalToIsolatedLocalActor(_ f: @escaping () async -> Void) -> (isolated LocalActor) async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { _ in await f() }
        //    }

        //    // ❌ normal async -> isolated LocalActor @Sendable async
        //    func normalToIsolatedLocalActorSendable(_ f: @escaping () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { _ in await f() }
        //    }

        // MARK: Source: @Sendable async

        // ✅ @Sendable async -> normal async
        func sendableToNormal(_ f: @escaping @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @Sendable async -> @Sendable async
        func sendableToSendable(_ f: @escaping @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> @MainActor async
        func sendableToMainActor(_ f: @escaping @Sendable () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @Sendable async -> @MainActor @Sendable async
        func sendableToMainActorSendable(_ f: @escaping @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> @concurrent async
        func sendableToConcurrent(_ f: @escaping @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @Sendable async -> @concurrent @Sendable async
        func sendableToConcurrentSendable(_ f: @escaping @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> @isolated(any) async
        func sendableToIsolatedAny(_ f: @escaping @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @Sendable async -> @isolated(any) @Sendable async
        func sendableToIsolatedAnySendable(_ f: @escaping @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> isolated LocalActor async
        func sendableToIsolatedLocalActor(_ f: @escaping @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @Sendable async -> isolated LocalActor @Sendable async
        func sendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @MainActor async

        // ✅ @MainActor async -> normal async (unlike non-async!)
        func mainActorToNormal(_ f: @escaping @MainActor () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @MainActor async -> @Sendable async (unlike non-async!)
        func mainActorToSendable(_ f: @escaping @MainActor () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> @MainActor async
        func mainActorToMainActor(_ f: @escaping @MainActor () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @MainActor async -> @MainActor @Sendable async
        func mainActorToMainActorSendable(_ f: @escaping @MainActor () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> @concurrent async
        func mainActorToConcurrent(_ f: @escaping @MainActor () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @MainActor async -> @concurrent @Sendable async
        func mainActorToConcurrentSendable(_ f: @escaping @MainActor () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> @isolated(any) async
        func mainActorToIsolatedAny(_ f: @escaping @MainActor () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @MainActor async -> @isolated(any) @Sendable async
        func mainActorToIsolatedAnySendable(_ f: @escaping @MainActor () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> isolated LocalActor async
        func mainActorToIsolatedLocalActor(_ f: @escaping @MainActor () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @MainActor async -> isolated LocalActor @Sendable async
        func mainActorToIsolatedLocalActorSendable(_ f: @escaping @MainActor () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @MainActor @Sendable async

        // ✅ @MainActor @Sendable async -> normal async (unlike non-async!)
        func mainActorSendableToNormal(_ f: @escaping @MainActor @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @Sendable async (unlike non-async!)
        func mainActorSendableToSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @MainActor async
        func mainActorSendableToMainActor(_ f: @escaping @MainActor @Sendable () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @MainActor @Sendable async
        func mainActorSendableToMainActorSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @concurrent async
        func mainActorSendableToConcurrent(_ f: @escaping @MainActor @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @concurrent @Sendable async
        func mainActorSendableToConcurrentSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @isolated(any) async
        func mainActorSendableToIsolatedAny(_ f: @escaping @MainActor @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @isolated(any) @Sendable async
        func mainActorSendableToIsolatedAnySendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> isolated LocalActor async
        func mainActorSendableToIsolatedLocalActor(_ f: @escaping @MainActor @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @MainActor @Sendable async -> isolated LocalActor @Sendable async
        func mainActorSendableToIsolatedLocalActorSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @concurrent async

        // ✅ @concurrent async -> normal async
        func concurrentToNormal(_ f: @escaping @concurrent () async -> Void) -> () async -> Void {
            f
        }

        //    // ❌ @concurrent async -> @Sendable async
        //    func concurrentToSendable(_ f: @escaping @concurrent () async -> Void) -> @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ @concurrent async -> @MainActor async
        //    func concurrentToMainActor(_ f: @escaping @concurrent () async -> Void) -> @MainActor () async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { await f() }
        //    }

        //    // ❌ @concurrent async -> @MainActor @Sendable async
        //    func concurrentToMainActorSendable(_ f: @escaping @concurrent () async -> Void) -> @MainActor @Sendable () async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { await f() }
        //    }

        // ✅ @concurrent async -> @concurrent async
        func concurrentToConcurrent(_ f: @escaping @concurrent () async -> Void) -> @concurrent () async -> Void {
            f
        }

        //    // ❌ @concurrent async -> @concurrent @Sendable async
        //    func concurrentToConcurrentSendable(_ f: @escaping @concurrent () async -> Void) -> @concurrent @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ @concurrent async -> @isolated(any) async
        func concurrentToIsolatedAny(_ f: @escaping @concurrent () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        //    // ❌ @concurrent async -> @isolated(any) @Sendable async
        //    func concurrentToIsolatedAnySendable(_ f: @escaping @concurrent () async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ @concurrent async -> isolated LocalActor async
        //    func concurrentToIsolatedLocalActor(_ f: @escaping @concurrent () async -> Void) -> (isolated LocalActor) async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { _ in await f() }
        //    }

        //    // ❌ @concurrent async -> isolated LocalActor @Sendable async
        //    func concurrentToIsolatedLocalActorSendable(_ f: @escaping @concurrent () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { _ in await f() }
        //    }

        // MARK: Source: @concurrent @Sendable async

        // ✅ @concurrent @Sendable async -> normal async
        func concurrentSendableToNormal(_ f: @escaping @concurrent @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @Sendable async
        func concurrentSendableToSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @MainActor async
        func concurrentSendableToMainActor(_ f: @escaping @concurrent @Sendable () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @MainActor @Sendable async
        func concurrentSendableToMainActorSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @concurrent async
        func concurrentSendableToConcurrent(_ f: @escaping @concurrent @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @concurrent @Sendable async
        func concurrentSendableToConcurrentSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @isolated(any) async
        func concurrentSendableToIsolatedAny(_ f: @escaping @concurrent @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @isolated(any) @Sendable async
        func concurrentSendableToIsolatedAnySendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> isolated LocalActor async
        func concurrentSendableToIsolatedLocalActor(_ f: @escaping @concurrent @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @concurrent @Sendable async -> isolated LocalActor @Sendable async
        func concurrentSendableToIsolatedLocalActorSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @isolated(any) async

        // ✅ @isolated(any) async -> normal async
        func isolatedAnyToNormal(_ f: @escaping @isolated(any) () async -> Void) -> () async -> Void {
            f
        }

        //    // ❌ @isolated(any) async -> @Sendable async
        //    func isolatedAnyToSendable(_ f: @escaping @isolated(any) () async -> Void) -> @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ @isolated(any) async -> @MainActor async
        //    func isolatedAnyToMainActor(_ f: @escaping @isolated(any) () async -> Void) -> @MainActor () async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { await f() }
        //    }

        //    // ❌ @isolated(any) async -> @MainActor @Sendable async
        //    func isolatedAnyToMainActorSendable(_ f: @escaping @isolated(any) () async -> Void) -> @MainActor @Sendable () async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { await f() }
        //    }

        // ✅ @isolated(any) async -> @concurrent async
        func isolatedAnyToConcurrent(_ f: @escaping @isolated(any) () async -> Void) -> @concurrent () async -> Void {
            f
        }

        //    // ❌ @isolated(any) async -> @concurrent @Sendable async
        //    func isolatedAnyToConcurrentSendable(_ f: @escaping @isolated(any) () async -> Void) -> @concurrent @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ @isolated(any) async -> @isolated(any) async
        func isolatedAnyToIsolatedAny(_ f: @escaping @isolated(any) () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        //    // ❌ @isolated(any) async -> @isolated(any) @Sendable async
        //    func isolatedAnyToIsolatedAnySendable(_ f: @escaping @isolated(any) () async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ @isolated(any) async -> isolated LocalActor async
        //    func isolatedAnyToIsolatedLocalActor(_ f: @escaping @isolated(any) () async -> Void) -> (isolated LocalActor) async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { _ in await f() }
        //    }

        //    // ❌ @isolated(any) async -> isolated LocalActor @Sendable async
        //    func isolatedAnyToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { _ in await f() }
        //    }

        // MARK: Source: @isolated(any) @Sendable async

        // ✅ @isolated(any) @Sendable async -> normal async
        func isolatedAnySendableToNormal(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @Sendable async
        func isolatedAnySendableToSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ❌ @isolated(any) @Sendable async -> @MainActor async (direct coercion)
        // ✅ @isolated(any) @Sendable async -> @MainActor async (explicit closure wrapping)
        func isolatedAnySendableToMainActor(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @MainActor () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ❌ @isolated(any) @Sendable async -> @MainActor @Sendable async (direct coercion)
        // ✅ @isolated(any) @Sendable async -> @MainActor @Sendable async (explicit closure wrapping)
        func isolatedAnySendableToMainActorSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ @isolated(any) @Sendable async -> @concurrent async
        func isolatedAnySendableToConcurrent(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @concurrent @Sendable async
        func isolatedAnySendableToConcurrentSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @isolated(any) async
        func isolatedAnySendableToIsolatedAny(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @isolated(any) @Sendable async
        func isolatedAnySendableToIsolatedAnySendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> isolated LocalActor async
        func isolatedAnySendableToIsolatedLocalActor(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @isolated(any) @Sendable async -> isolated LocalActor @Sendable async
        func isolatedAnySendableToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: isolated LocalActor async

        // ✅ isolated LocalActor async -> normal async
        func isolatedLocalActorToNormal(_ f: @escaping (isolated LocalActor) async -> Void) -> () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        //    // ❌ isolated LocalActor async -> @Sendable async
        //    func isolatedLocalActorToSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        //    // ❌ isolated LocalActor async -> @MainActor async
        //    func isolatedLocalActorToMainActor(_ f: @escaping (isolated LocalActor) async -> Void) -> @MainActor () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        //    // ❌ isolated LocalActor async -> @MainActor @Sendable async
        //    func isolatedLocalActorToMainActorSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @MainActor @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        // ✅ isolated LocalActor async -> @concurrent async
        func isolatedLocalActorToConcurrent(_ f: @escaping (isolated LocalActor) async -> Void) -> @concurrent () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        //    // ❌ isolated LocalActor async -> @concurrent @Sendable async
        //    func isolatedLocalActorToConcurrentSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @concurrent @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        // ✅ isolated LocalActor async -> @isolated(any) async
        func isolatedLocalActorToIsolatedAny(_ f: @escaping (isolated LocalActor) async -> Void) -> @isolated(any) () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        //    // ❌ isolated LocalActor async -> @isolated(any) @Sendable async
        //    func isolatedLocalActorToIsolatedAnySendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        // ✅ isolated LocalActor async -> isolated LocalActor async
        func isolatedLocalActorToIsolatedLocalActor(_ f: @escaping (isolated LocalActor) async -> Void) -> (isolated LocalActor) async -> Void {
            f
        }

        //    // ❌ isolated LocalActor async -> isolated LocalActor @Sendable async
        //    func isolatedLocalActorToIsolatedLocalActorSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { actor in await f(actor) }
        //    }

        // MARK: Source: isolated LocalActor @Sendable async

        // ✅ isolated LocalActor @Sendable async -> normal async
        func isolatedLocalActorSendableToNormal(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @Sendable async
        func isolatedLocalActorSendableToSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @MainActor async
        func isolatedLocalActorSendableToMainActor(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @MainActor () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @MainActor @Sendable async
        func isolatedLocalActorSendableToMainActorSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @MainActor @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @concurrent async
        func isolatedLocalActorSendableToConcurrent(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @concurrent () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @concurrent @Sendable async
        func isolatedLocalActorSendableToConcurrentSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @concurrent @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @isolated(any) async
        func isolatedLocalActorSendableToIsolatedAny(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @isolated(any) () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @isolated(any) @Sendable async
        func isolatedLocalActorSendableToIsolatedAnySendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @isolated(any) @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> isolated LocalActor async
        func isolatedLocalActorSendableToIsolatedLocalActor(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> (isolated LocalActor) async -> Void {
            f
        }

        // ✅ isolated LocalActor @Sendable async -> isolated LocalActor @Sendable async
        func isolatedLocalActorSendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            f
        }
    }

    /// Async conversion test with `@MainActor` on each inner function.
    /// This tests if isolation context affects conversion rules.
    ///
    /// ## ❌ to ✅ Changes (0 cases)
    ///
    /// None! The conversions that were previously ❌ → ✅ with @MainActor context
    /// (`normal async -> @MainActor async`, `@concurrent async -> @MainActor async`, etc.)
    /// are now ✅ even in nonisolated context.
    ///
    /// ## ✅ to ❌ Changes (0 cases)
    ///
    /// None! Unlike sync, async @MainActor sources can use direct coercion `f` for all targets.
    ///
    /// ## Key Insight
    ///
    /// Async allows more implicit conversions than sync:
    /// - `@MainActor async` sources can use direct coercion `f` to any target type
    /// - This is because async functions allow runtime actor hopping via suspension
    private enum CompileAsyncConversionTest_MainActor {
        // MARK: Source: normal async

        // ✅ normal async -> normal async
        @MainActor func normalToNormal(_ f: @escaping () async -> Void) -> () async -> Void {
            f
        }

        //    // ❌ normal async -> @Sendable async
        //    @MainActor func normalToSendable(_ f: @escaping () async -> Void) -> @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ normal async -> @MainActor async
        @MainActor func normalToMainActor(_ f: @escaping () async -> Void) -> @MainActor () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ normal async -> @MainActor @Sendable async
        @MainActor func normalToMainActorSendable(_ f: @escaping () async -> Void) -> @MainActor @Sendable () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ normal async -> @concurrent async
        @MainActor func normalToConcurrent(_ f: @escaping () async -> Void) -> @concurrent () async -> Void {
            f
        }

        //    // ❌ normal async -> @concurrent @Sendable async
        //    @MainActor func normalToConcurrentSendable(_ f: @escaping () async -> Void) -> @concurrent @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ normal async -> @isolated(any) async
        @MainActor func normalToIsolatedAny(_ f: @escaping () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        //    // ❌ normal async -> @isolated(any) @Sendable async
        //    @MainActor func normalToIsolatedAnySendable(_ f: @escaping () async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ normal async -> isolated LocalActor async
        //    @MainActor func normalToIsolatedLocalActor(_ f: @escaping () async -> Void) -> (isolated LocalActor) async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { _ in await f() }
        //    }

        //    // ❌ normal async -> isolated LocalActor @Sendable async
        //    @MainActor func normalToIsolatedLocalActorSendable(_ f: @escaping () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { _ in await f() }
        //    }

        // MARK: Source: @Sendable async

        // ✅ @Sendable async -> normal async
        @MainActor func sendableToNormal(_ f: @escaping @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @Sendable async -> @Sendable async
        @MainActor func sendableToSendable(_ f: @escaping @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> @MainActor async
        @MainActor func sendableToMainActor(_ f: @escaping @Sendable () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @Sendable async -> @MainActor @Sendable async
        @MainActor func sendableToMainActorSendable(_ f: @escaping @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> @concurrent async
        @MainActor func sendableToConcurrent(_ f: @escaping @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @Sendable async -> @concurrent @Sendable async
        @MainActor func sendableToConcurrentSendable(_ f: @escaping @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> @isolated(any) async
        @MainActor func sendableToIsolatedAny(_ f: @escaping @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @Sendable async -> @isolated(any) @Sendable async
        @MainActor func sendableToIsolatedAnySendable(_ f: @escaping @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @Sendable async -> isolated LocalActor async
        @MainActor func sendableToIsolatedLocalActor(_ f: @escaping @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @Sendable async -> isolated LocalActor @Sendable async
        @MainActor func sendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @MainActor async

        // ✅ @MainActor async -> normal async
        @MainActor func mainActorToNormal(_ f: @escaping @MainActor () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @MainActor async -> @Sendable async
        @MainActor func mainActorToSendable(_ f: @escaping @MainActor () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> @MainActor async
        @MainActor func mainActorToMainActor(_ f: @escaping @MainActor () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @MainActor async -> @MainActor @Sendable async
        @MainActor func mainActorToMainActorSendable(_ f: @escaping @MainActor () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> @concurrent async
        @MainActor func mainActorToConcurrent(_ f: @escaping @MainActor () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @MainActor async -> @concurrent @Sendable async
        @MainActor func mainActorToConcurrentSendable(_ f: @escaping @MainActor () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> @isolated(any) async
        @MainActor func mainActorToIsolatedAny(_ f: @escaping @MainActor () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @MainActor async -> @isolated(any) @Sendable async
        @MainActor func mainActorToIsolatedAnySendable(_ f: @escaping @MainActor () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor async -> isolated LocalActor async
        @MainActor func mainActorToIsolatedLocalActor(_ f: @escaping @MainActor () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @MainActor async -> isolated LocalActor @Sendable async
        @MainActor func mainActorToIsolatedLocalActorSendable(_ f: @escaping @MainActor () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @MainActor @Sendable async

        // ✅ @MainActor @Sendable async -> normal async
        @MainActor func mainActorSendableToNormal(_ f: @escaping @MainActor @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @Sendable async
        @MainActor func mainActorSendableToSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @MainActor async
        @MainActor func mainActorSendableToMainActor(_ f: @escaping @MainActor @Sendable () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @MainActor @Sendable async
        @MainActor func mainActorSendableToMainActorSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @concurrent async
        @MainActor func mainActorSendableToConcurrent(_ f: @escaping @MainActor @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @concurrent @Sendable async
        @MainActor func mainActorSendableToConcurrentSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @isolated(any) async
        @MainActor func mainActorSendableToIsolatedAny(_ f: @escaping @MainActor @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> @isolated(any) @Sendable async
        @MainActor func mainActorSendableToIsolatedAnySendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @MainActor @Sendable async -> isolated LocalActor async
        @MainActor func mainActorSendableToIsolatedLocalActor(_ f: @escaping @MainActor @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @MainActor @Sendable async -> isolated LocalActor @Sendable async
        @MainActor func mainActorSendableToIsolatedLocalActorSendable(_ f: @escaping @MainActor @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @concurrent async

        // ✅ @concurrent async -> normal async
        @MainActor func concurrentToNormal(_ f: @escaping @concurrent () async -> Void) -> () async -> Void {
            f
        }

        //    // ❌ @concurrent async -> @Sendable async
        //    @MainActor func concurrentToSendable(_ f: @escaping @concurrent () async -> Void) -> @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ @concurrent async -> @MainActor async
        @MainActor func concurrentToMainActor(_ f: @escaping @concurrent () async -> Void) -> @MainActor () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ @concurrent async -> @MainActor @Sendable async
        @MainActor func concurrentToMainActorSendable(_ f: @escaping @concurrent () async -> Void) -> @MainActor @Sendable () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ @concurrent async -> @concurrent async
        @MainActor func concurrentToConcurrent(_ f: @escaping @concurrent () async -> Void) -> @concurrent () async -> Void {
            f
        }

        //    // ❌ @concurrent async -> @concurrent @Sendable async
        //    @MainActor func concurrentToConcurrentSendable(_ f: @escaping @concurrent () async -> Void) -> @concurrent @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ @concurrent async -> @isolated(any) async
        @MainActor func concurrentToIsolatedAny(_ f: @escaping @concurrent () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        //    // ❌ @concurrent async -> @isolated(any) @Sendable async
        //    @MainActor func concurrentToIsolatedAnySendable(_ f: @escaping @concurrent () async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ @concurrent async -> isolated LocalActor async
        //    @MainActor func concurrentToIsolatedLocalActor(_ f: @escaping @concurrent () async -> Void) -> (isolated LocalActor) async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { _ in await f() }
        //    }

        //    // ❌ @concurrent async -> isolated LocalActor @Sendable async
        //    @MainActor func concurrentToIsolatedLocalActorSendable(_ f: @escaping @concurrent () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { _ in await f() }
        //    }

        // MARK: Source: @concurrent @Sendable async

        // ✅ @concurrent @Sendable async -> normal async
        @MainActor func concurrentSendableToNormal(_ f: @escaping @concurrent @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @Sendable async
        @MainActor func concurrentSendableToSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @MainActor async
        @MainActor func concurrentSendableToMainActor(_ f: @escaping @concurrent @Sendable () async -> Void) -> @MainActor () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @MainActor @Sendable async
        @MainActor func concurrentSendableToMainActorSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @concurrent async
        @MainActor func concurrentSendableToConcurrent(_ f: @escaping @concurrent @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @concurrent @Sendable async
        @MainActor func concurrentSendableToConcurrentSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @isolated(any) async
        @MainActor func concurrentSendableToIsolatedAny(_ f: @escaping @concurrent @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> @isolated(any) @Sendable async
        @MainActor func concurrentSendableToIsolatedAnySendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @concurrent @Sendable async -> isolated LocalActor async
        @MainActor func concurrentSendableToIsolatedLocalActor(_ f: @escaping @concurrent @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @concurrent @Sendable async -> isolated LocalActor @Sendable async
        @MainActor func concurrentSendableToIsolatedLocalActorSendable(_ f: @escaping @concurrent @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: @isolated(any) async

        // ✅ @isolated(any) async -> normal async
        @MainActor func isolatedAnyToNormal(_ f: @escaping @isolated(any) () async -> Void) -> () async -> Void {
            f
        }

        //    // ❌ @isolated(any) async -> @Sendable async
        //    @MainActor func isolatedAnyToSendable(_ f: @escaping @isolated(any) () async -> Void) -> @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ❌ @isolated(any) async -> @MainActor async (direct coercion)
        // ✅ @isolated(any) async -> @MainActor async (explicit closure wrapping)
        @MainActor func isolatedAnyToMainActor(_ f: @escaping @isolated(any) () async -> Void) -> @MainActor () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ❌ @isolated(any) async -> @MainActor @Sendable async (direct coercion)
        // ✅ @isolated(any) async -> @MainActor @Sendable async (explicit closure wrapping)
        @MainActor func isolatedAnyToMainActorSendable(_ f: @escaping @isolated(any) () async -> Void) -> @MainActor @Sendable () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ @isolated(any) async -> @concurrent async
        @MainActor func isolatedAnyToConcurrent(_ f: @escaping @isolated(any) () async -> Void) -> @concurrent () async -> Void {
            f
        }

        //    // ❌ @isolated(any) async -> @concurrent @Sendable async
        //    @MainActor func isolatedAnyToConcurrentSendable(_ f: @escaping @isolated(any) () async -> Void) -> @concurrent @Sendable () async -> Void {
        //        { await f() }
        //    }

        // ✅ @isolated(any) async -> @isolated(any) async
        @MainActor func isolatedAnyToIsolatedAny(_ f: @escaping @isolated(any) () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        //    // ❌ @isolated(any) async -> @isolated(any) @Sendable async
        //    @MainActor func isolatedAnyToIsolatedAnySendable(_ f: @escaping @isolated(any) () async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        { await f() }
        //    }

        //    // ❌ @isolated(any) async -> isolated LocalActor async
        //    @MainActor func isolatedAnyToIsolatedLocalActor(_ f: @escaping @isolated(any) () async -> Void) -> (isolated LocalActor) async -> Void {
        //        // f // ERROR: Direct coercion doesn't work
        //
        //        { _ in await f() }
        //    }

        //    // ❌ @isolated(any) async -> isolated LocalActor @Sendable async
        //    @MainActor func isolatedAnyToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { _ in await f() }
        //    }

        // MARK: Source: @isolated(any) @Sendable async

        // ✅ @isolated(any) @Sendable async -> normal async
        @MainActor func isolatedAnySendableToNormal(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @Sendable async
        @MainActor func isolatedAnySendableToSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @Sendable () async -> Void {
            f
        }

        // ❌ @isolated(any) @Sendable async -> @MainActor async (direct coercion)
        // ✅ @isolated(any) @Sendable async -> @MainActor async (explicit closure wrapping)
        @MainActor func isolatedAnySendableToMainActor(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @MainActor () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ❌ @isolated(any) @Sendable async -> @MainActor @Sendable async (direct coercion)
        // ✅ @isolated(any) @Sendable async -> @MainActor @Sendable async (explicit closure wrapping)
        @MainActor func isolatedAnySendableToMainActorSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @MainActor @Sendable () async -> Void {
            // f // ERROR: Direct coercion doesn't work

            { await f() }
        }

        // ✅ @isolated(any) @Sendable async -> @concurrent async
        @MainActor func isolatedAnySendableToConcurrent(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @concurrent @Sendable async
        @MainActor func isolatedAnySendableToConcurrentSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @concurrent @Sendable () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @isolated(any) async
        @MainActor func isolatedAnySendableToIsolatedAny(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> @isolated(any) @Sendable async
        @MainActor func isolatedAnySendableToIsolatedAnySendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @isolated(any) @Sendable () async -> Void {
            f
        }

        // ✅ @isolated(any) @Sendable async -> isolated LocalActor async
        @MainActor func isolatedAnySendableToIsolatedLocalActor(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // ✅ @isolated(any) @Sendable async -> isolated LocalActor @Sendable async
        @MainActor func isolatedAnySendableToIsolatedLocalActorSendable(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            { _ in await f() }
        }

        // MARK: Source: isolated LocalActor async

        // ✅ isolated LocalActor async -> normal async
        @MainActor func isolatedLocalActorToNormal(_ f: @escaping (isolated LocalActor) async -> Void) -> () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        //    // ❌ isolated LocalActor async -> @Sendable async
        //    @MainActor func isolatedLocalActorToSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        // ✅ isolated LocalActor async -> @MainActor async
        @MainActor func isolatedLocalActorToMainActor(_ f: @escaping (isolated LocalActor) async -> Void) -> @MainActor () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor async -> @MainActor @Sendable async
        @MainActor func isolatedLocalActorToMainActorSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @MainActor @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor async -> @concurrent async
        @MainActor func isolatedLocalActorToConcurrent(_ f: @escaping (isolated LocalActor) async -> Void) -> @concurrent () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        //    // ❌ isolated LocalActor async -> @concurrent @Sendable async
        //    @MainActor func isolatedLocalActorToConcurrentSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @concurrent @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        // ✅ isolated LocalActor async -> @isolated(any) async
        @MainActor func isolatedLocalActorToIsolatedAny(_ f: @escaping (isolated LocalActor) async -> Void) -> @isolated(any) () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        //    // ❌ isolated LocalActor async -> @isolated(any) @Sendable async
        //    @MainActor func isolatedLocalActorToIsolatedAnySendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @isolated(any) @Sendable () async -> Void {
        //        let actor = LocalActor()
        //        return { await f(actor) }
        //    }

        // ✅ isolated LocalActor async -> isolated LocalActor async
        @MainActor func isolatedLocalActorToIsolatedLocalActor(_ f: @escaping (isolated LocalActor) async -> Void) -> (isolated LocalActor) async -> Void {
            f
        }

        //    // ❌ isolated LocalActor async -> isolated LocalActor @Sendable async
        //    @MainActor func isolatedLocalActorToIsolatedLocalActorSendable(_ f: @escaping (isolated LocalActor) async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
        //        { actor in await f(actor) }
        //    }

        // MARK: Source: isolated LocalActor @Sendable async

        // ✅ isolated LocalActor @Sendable async -> normal async
        @MainActor func isolatedLocalActorSendableToNormal(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @Sendable async
        @MainActor func isolatedLocalActorSendableToSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @MainActor async
        @MainActor func isolatedLocalActorSendableToMainActor(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @MainActor () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @MainActor @Sendable async
        @MainActor func isolatedLocalActorSendableToMainActorSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @MainActor @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @concurrent async
        @MainActor func isolatedLocalActorSendableToConcurrent(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @concurrent () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @concurrent @Sendable async
        @MainActor func isolatedLocalActorSendableToConcurrentSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @concurrent @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @isolated(any) async
        @MainActor func isolatedLocalActorSendableToIsolatedAny(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @isolated(any) () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> @isolated(any) @Sendable async
        @MainActor func isolatedLocalActorSendableToIsolatedAnySendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @isolated(any) @Sendable () async -> Void {
            let actor = LocalActor()
            return { await f(actor) }
        }

        // ✅ isolated LocalActor @Sendable async -> isolated LocalActor async
        @MainActor func isolatedLocalActorSendableToIsolatedLocalActor(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> (isolated LocalActor) async -> Void {
            f
        }

        // ✅ isolated LocalActor @Sendable async -> isolated LocalActor @Sendable async
        @MainActor func isolatedLocalActorSendableToIsolatedLocalActorSendable(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> @Sendable (isolated LocalActor) async -> Void {
            f
        }
    }
}

// MARK: - Misc

private enum Misc {
    // MARK: - Sync @isolated(any) to Async Conversion (SE-0431)

    /// SE-0431 specifies:
    /// "If only F specifies @isolated(any), then G must be an async function type."
    ///
    /// This means sync @isolated(any) can be converted to async non-@isolated(any).
    /// The target G:
    /// - Must be async
    /// - May have any isolation specifier, but it will be **ignored** at runtime
    /// - The function will run with the **original** dynamic isolation of F
    /// - Arguments and result must be sendable across isolation boundary
    ///
    /// Key insight: This is a form of "type erasure" - the type system loses track
    /// of the isolation info, but the function still has its dynamic isolation at runtime.
    /// However, `.isolation` property is no longer accessible.
    ///
    /// Reference: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md#conversions
    private enum CompileSyncIsolatedAnyToAsyncConversionTest {
        // MARK: Source: @isolated(any) sync -> async (SE-0431 Rule)

        // ✅ @isolated(any) sync -> normal async
        // The resulting async function will run with F's original dynamic isolation
        func isolatedAnySyncToNormalAsync(_ f: @escaping @isolated(any) () -> Void) -> () async -> Void {
            f
        }

        // ❌ @isolated(any) sync -> @MainActor async
        // Cannot convert to a specific global actor isolation.
        // @isolated(any) = "some unknown isolation" ≠ "definitely MainActor"
        //    func isolatedAnySyncToMainActorAsync(_ f: @escaping @isolated(any) @Sendable () -> Void) -> @MainActor () async -> Void {
        //        f // Error: cannot convert return expression
        //    }

        // ✅ @isolated(any) sync -> @concurrent async
        // @concurrent = nonisolated, so this is allowed (isolation erasure to nonisolated)
        func isolatedAnySyncToConcurrentAsync(_ f: @escaping @isolated(any) () -> Void) -> @concurrent () async -> Void {
            f
        }

        // ✅ @isolated(any) sync -> @isolated(any) async
        // Both F and G are @isolated(any), dynamic isolation is preserved
        func isolatedAnySyncToIsolatedAnyAsync(_ f: @escaping @isolated(any) () -> Void) -> @isolated(any) () async -> Void {
            f
        }

        // MARK: Comparison - other sync to async conversions (all work!)

        // ✅ normal sync -> normal async (sync to async is always allowed)
        func normalSyncToNormalAsync(_ f: @escaping () -> Void) -> () async -> Void {
            f
        }

        // ✅ @MainActor sync -> normal async
        func mainActorSyncToNormalAsync(_ f: @escaping @MainActor () -> Void) -> () async -> Void {
            f
        }

        // MARK: Key insight from SE-0431
        //
        // The special rule is NOT that @isolated(any) sync can convert to async
        // (all sync functions can convert to async).
        //
        // The special rule is:
        // - @isolated(any) sync -> sync (without @isolated(any)) = ⚠️ WARNING (future error)
        // - @isolated(any) sync -> async (without @isolated(any)) = ✅ ALLOWED (isolation erasure)
        //
        // This is "type erasure" - the @isolated(any) info is erased from the type,
        // but the dynamic isolation is preserved at runtime.
    }

    // MARK: - `normal sync` vs `normal async`: Isolation Semantics (SE-0461)

    /// Demonstrates that BOTH `normal sync` and `normal async` closure literals
    /// can inherit isolation from context.
    ///
    /// Reference: SE-0461 - Run nonisolated async functions on the caller's actor by default
    /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md
    ///
    /// Key insight from SE-0461 Section "Isolation inference for closures":
    /// "If the contextual type of the closure is neither @Sendable nor sending,
    ///  the inferred isolation of the closure is the same as the enclosing context"
    private enum CompileNormalSyncVsNormalAsyncTest {

        // MARK: Both sync and async closure literals inherit isolation from context

        @MainActor func bothInheritIsolation() {
            // ✅ normal sync: closure literal inherits @MainActor from context
            let f1: () -> Void = {
                // This closure IS @MainActor isolated (inferred from context)
                MainActor.assertIsolated()
            }

            // ✅ normal async: closure literal inherits @MainActor from context
            let f2: () async -> Void = {
                // This closure IS @MainActor isolated (inferred from context)
                MainActor.assertIsolated()
            }

            _ = (f1, f2)
        }

        // MARK: SE-0461 terminology

        // | Type          | SE-0461 Formal Name        |
        // |---------------|----------------------------|
        // | normal sync   | nonisolated                |
        // | normal async  | nonisolated(nonsending)    |
        // | @concurrent   | @concurrent (explicit)     |

        // MARK: The difference is in execution semantics, not closure inference

        // Before SE-0461 (SE-0338):
        // - nonisolated sync: runs on caller's executor (no switch)
        // - nonisolated async: switches OFF the actor (requires Sendable checking)
        //
        // After SE-0461:
        // - nonisolated sync: runs on caller's executor (no switch)
        // - nonisolated(nonsending) async: runs on caller's actor (no switch, like sync)
        // - @concurrent async: switches OFF the actor (explicit opt-in)

        // MARK: @Sendable changes inference behavior

        @MainActor func sendableChangesInference() {
            // When contextual type is @Sendable, closure becomes nonisolated
            // (SE-0461: "If the type of the closure is @Sendable... the closure is inferred to be nonisolated")

            // @Sendable sync: becomes nonisolated (does NOT inherit @MainActor)
            let f1: @Sendable () -> Void = {
                // This closure is nonisolated, NOT @MainActor
                // MainActor.assertIsolated()  // Would fail at runtime!
            }

            // @Sendable async: becomes nonisolated (does NOT inherit @MainActor)
            let f2: @Sendable () async -> Void = {
                // This closure is nonisolated, NOT @MainActor
                // MainActor.assertIsolated()  // Would fail at runtime!
            }

            _ = (f1, f2)
        }
    }

    // MARK: - `normal async` vs `@concurrent async`: Closure Literal Inference

    /// Demonstrates the difference between `normal async` and `@concurrent async`.
    ///
    /// Note: `@concurrent` only exists in the **async** world.
    ///
    /// Key insight: The difference is about **closure literal inference**, not type conversion.
    /// - `normal async` closure literals may inherit isolation from context
    /// - `@concurrent async` closure literals are always nonisolated regardless of context
    ///
    /// The conversion table looks identical for both because it tests **existing function values**,
    /// not closure literal inference.
    private enum CompileNormalAsyncVsConcurrentAsyncTest {

        // MARK: Type Conversion - Both behave the same

        // In nonisolated context, both `normal async` and `@concurrent async`
        // have identical conversion patterns.

        // ❌ normal async -> @MainActor async (in nonisolated context)
        //    func normalToMainActor(_ f: @escaping () async -> Void) -> @MainActor () async -> Void {
        //        { await f() }  // Error: inner closure is nonisolated
        //    }

        // ❌ @concurrent async -> @MainActor async (in nonisolated context)
        //    func concurrentToMainActor(_ f: @escaping @concurrent () async -> Void) -> @MainActor () async -> Void {
        //        { await f() }  // Error: inner closure is nonisolated
        //    }

        // In @MainActor context, BOTH can convert via closure wrapping
        // because the NEW inner closure inherits @MainActor.

        // ✅ normal async -> @MainActor async (in @MainActor context)
        @MainActor func normalToMainActor(_ f: @escaping () async -> Void) -> @MainActor () async -> Void {
            { await f() }  // OK: inner closure inherits @MainActor
        }

        // ✅ @concurrent async -> @MainActor async (in @MainActor context)
        @MainActor func concurrentToMainActor(_ f: @escaping @concurrent () async -> Void) -> @MainActor () async -> Void {
            { await f() }  // OK: inner closure inherits @MainActor (f is just called inside)
        }

        // MARK: Closure Literal Inference - The real difference

        // The difference appears when you write a closure literal with explicit type annotation.

        @MainActor func closureLiteralInference() {
            // normal async: closure literal INHERITS @MainActor from context
            let f1: () async -> Void = {
                // This closure IS @MainActor isolated (inferred from context)
                // Can access @MainActor state without await
                MainActor.assertIsolated()
            }

            // @concurrent async: closure literal is EXPLICITLY nonisolated, never inherits
            let f2: @concurrent () async -> Void = {
                // This closure is nonisolated regardless of context
                // Cannot access @MainActor state without await
                // MainActor.assertIsolated()  // Would fail at runtime!
            }
        }

        // MARK: Why conversion table looks the same

        // Both `normal async` and `@concurrent async` have the same conversion patterns
        // because the table tests converting EXISTING function values, not creating
        // new closure literals.
        //
        // When you do `{ await f() }`, you create a NEW closure whose isolation
        // is determined by WHERE it's written, not by what `f` is.
    }

    // MARK: - SE-0461: Function Conversions (Global Actor → MainActor)

    /// Verifies the SE-0461 example that a function conversion can change isolation by
    /// inserting a thunk closure.
    ///
    /// Reference:
    /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md#function-conversions
    @MyGlobalActor
    private static func se0461_otherActorClosure() {}

    private static func compileSE0461_functionConversion_globalActorToMainActorTest() {
        func convert(closure: @escaping @MyGlobalActor () -> Void) {
            #if SE0461_DIRECT_CONVERSION
            // NOTE: As of Swift 6.2.1, this does NOT compile:
            // "cannot convert value actor-isolated to 'MyGlobalActor' to specified type actor-isolated to 'MainActor'".
            //
            // Keep it behind a flag so we can re-test future toolchains.
            let mainActorFn: @MainActor () async -> Void = closure
            #else
            let mainActorFn: @MainActor () async -> Void = {
                await closure()
            }
            #endif

            let mainActorEquivalent: @MainActor () async -> Void = {
                await closure()
            }

            _ = (mainActorFn, mainActorEquivalent)
        }

        convert(closure: Self.se0461_otherActorClosure)
    }
}

// MARK: - Private

private actor LocalActor {
    var x: Int = 0
}
