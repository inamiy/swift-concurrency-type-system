@MainActor
func regionExample(viewModel: MainActorViewModel) async {
    let x = NonSendable()      // x starts disconnected
    viewModel.field = x        // x becomes isolated(MainActor)

    let other = OtherActor()
    await other.use(x)         // error: x is no longer disconnected
}
