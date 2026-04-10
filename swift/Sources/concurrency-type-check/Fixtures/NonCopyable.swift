struct NonCopyable: ~Copyable {
    var value: Int

    init(value: Int = 0) {
        self.value = value
    }
}
