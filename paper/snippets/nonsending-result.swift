private actor NonSendingResultActor {
    func make() -> NonSendable {
        NonSendable()
    }
}

@MainActor
func crossActorNonSendingResultError() async {
    let actor = NonSendingResultActor()
    let y = await actor.make() // error: non-Sendable result crosses isolation boundary
    _ = y
}
