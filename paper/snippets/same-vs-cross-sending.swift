@MainActor
func exampleSameVsCross() async {
    let x = NonSendable()

    useSendingOnMainActor(x)      // same isolation: not consumed
    useSendingOnMainActor(x)      // still accessible

    let other = OtherActor()
    await other.useNonSendableSending(x) // cross isolation: consumed here
    _ = x.value                          // error: use-after-send
}
