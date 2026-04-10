func measureTime<T>(
    _ f: () async throws -> T,
    isolation: isolated (any Actor)? = #isolation
) async rethrows -> T {
    try await f()
}

@MainActor
func isolationMacroExample() async {
    var progress = 0
    let x = NonSendable()

    await measureTime {
        progress += 1
        _ = x.value
    }

    _ = progress
    _ = x.value
}
