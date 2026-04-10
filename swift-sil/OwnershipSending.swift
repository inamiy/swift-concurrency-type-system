// Testing ownership modifiers with `sending` on ~Copyable and Copyable types

// MARK: - Types

struct NonCopyable: ~Copyable {
    var value: Int
}

class NonSendable {  // Copyable but not Sendable
    var value: Int
    init(value: Int) { self.value = value }
}

// MARK: - ~Copyable + sending

// 1. consuming sending - OK
func consumingSendingNC(_ x: consuming sending NonCopyable) {
    print(x.value)
}

// 2. inout sending - OK
func inoutSendingNC(_ x: inout sending NonCopyable) {
    x.value += 1
}

// 3. borrowing sending - NOT ALLOWED
// func borrowingSendingNC(_ x: borrowing sending NonCopyable) {
//                                        ~~~~~~~ error: 'sending' cannot be used together with 'borrowing'
//     print(x.value)
// }

// 4. Just sending (no ownership) - NOT ALLOWED for ~Copyable
// func justSendingNC(_ x: sending NonCopyable) {
//                        ~~~~~~~ error: parameter of noncopyable type 'NonCopyable' must specify ownership
//     print(x.value)
// }

// MARK: - Copyable (NonSendable) + sending

// 5. sending (no ownership) - OK for Copyable
func justSending(_ x: sending NonSendable) {
    print(x.value)
}

// 6. consuming sending - OK
func consumingSending(_ x: consuming sending NonSendable) {
    print(x.value)
}

// 7. inout sending - OK
func inoutSending(_ x: inout sending NonSendable) {
    x.value += 1
}

// 8. borrowing sending - NOT ALLOWED (even for Copyable)
// func borrowingSending(_ x: borrowing sending NonSendable) {
//                                      ~~~~~~~ error: 'sending' cannot be used together with 'borrowing'
//     print(x.value)
// }

// MARK: - Cross-isolation tests

@MainActor
func mainActorInoutNC(_ x: inout sending NonCopyable) {
    x.value += 100
}

@MainActor
func mainActorInout(_ x: inout sending NonSendable) {
    x.value += 100
}

func testCrossIsolation() async {
    // ~Copyable
    var nc = NonCopyable(value: 1)
    await mainActorInoutNC(&nc)
    print(nc.value)  // ✅ 101

    // Copyable (NonSendable)
    var ns = NonSendable(value: 1)
    await mainActorInout(&ns)
    print(ns.value)  // ✅ 101
}
