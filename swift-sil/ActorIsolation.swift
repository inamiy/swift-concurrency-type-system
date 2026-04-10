// Actor Isolation SIL Exploration

@MainActor
func mainActorFunc() {
    print("Hello from MainActor")
}

@MainActor
func mainActorFuncWithArg(_ x: Int) -> Int {
    return x + 1
}

// Non-isolated function for comparison
func regularFunc() {
    print("Hello from regular func")
}

// Actor definition
actor MyActor {
    var value: Int = 0

    func actorMethod() -> Int {
        return value
    }

    nonisolated func nonisolatedMethod() -> String {
        return "nonisolated"
    }
}

// Global actor
@globalActor
struct CustomGlobalActor {
    actor ActorType { }
    static let shared = ActorType()
}

@CustomGlobalActor
func customActorFunc() {
    print("Custom global actor")
}
