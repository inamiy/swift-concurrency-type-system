@MainActor
func isolatedAnyRequiresAwait() async {
    let f: @isolated(any) () -> Void = { @MainActor in }
    await f() // actor identity is dynamic, so the call is treated as cross-isolation
}
