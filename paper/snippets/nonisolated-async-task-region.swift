nonisolated func helper(_ x: NonSendable) async {
    let noniso: () -> Void = { _ = x.value }
    let isoAny: @isolated(any) () -> Void = { _ = x.value }
    _ = (noniso, isoAny)
}

nonisolated func negative(_ x: NonSendable) async {
    let _: @MainActor () -> Void = { _ = x.value } // error
}
