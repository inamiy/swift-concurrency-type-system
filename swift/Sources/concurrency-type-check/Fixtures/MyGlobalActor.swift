@globalActor
struct MyGlobalActor {
    actor ActorType { }

    static let shared: ActorType = ActorType()
}
