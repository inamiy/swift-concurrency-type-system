func useNonSendable(actor: isolated LocalActor, _ x: NonSendable) {
    actor.useNonSendable(x)
}

@MainActor
func crossIsolationCaller() async {
    let actor = LocalActor()
    let x = NonSendable()
    await useNonSendable(actor: actor, x)
}

func sameIsolationCaller(actor: isolated LocalActor) {
    let x = NonSendable()
    useNonSendable(actor: actor, x)
    _ = x.value
}
