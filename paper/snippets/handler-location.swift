@MainActor
class ViewModel {
    @FooActor
    var handler: @BarActor () -> Void
}
