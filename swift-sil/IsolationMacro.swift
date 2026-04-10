// #isolation macro exploration
// Compare: default param vs explicit passing

// MARK: - Function with #isolation as default param

func withDefaultIsolation<T>(
    _ body: () throws -> T,
    isolation: isolated (any Actor)? = #isolation
) rethrows -> T {
    try body()
}

// MARK: - Function WITHOUT default param (requires explicit passing)

func withExplicitIsolation<T>(
    _ body: () throws -> T,
    isolation: isolated (any Actor)?
) rethrows -> T {
    try body()
}

// MARK: - Callers

@MainActor
func callerMainActor() {
    // Case 1: Using default #isolation
    withDefaultIsolation {
        print("default isolation")
    }

    // Case 2: Explicit #isolation passing
    withExplicitIsolation({
        print("explicit isolation")
    }, isolation: #isolation)

    // Case 3: Passing nil explicitly
    withDefaultIsolation({
        print("nil isolation")
    }, isolation: nil)
}

actor MyActor {
    func callerFromActor() {
        // Case 4: From actor with default
        withDefaultIsolation {
            print("actor default")
        }

        // Case 5: From actor with explicit
        withExplicitIsolation({
            print("actor explicit")
        }, isolation: #isolation)
    }
}

// Case 6: From nonisolated context
nonisolated func callerNonisolated() {
    withDefaultIsolation {
        print("nonisolated default")
    }

    withExplicitIsolation({
        print("nonisolated explicit")
    }, isolation: #isolation)
}
