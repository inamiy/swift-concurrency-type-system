@MainActor
func sameActorTaskCapture() {
    let x = NonSendable()
    Task {
        _ = x.value
    }
    _ = x.value // same actor context, so access is preserved
}

func detachedTaskCapture() {
    let x = NonSendable()
    Task.detached {
        _ = x.value
    }
    _ = x.value // error: x was transferred out of the current environment
}
