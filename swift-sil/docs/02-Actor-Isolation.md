# Actor Isolation in SIL

## Isolation Comments

Every SIL function has an isolation comment:

```sil
// Isolation: global_actor. type: MainActor      // @MainActor functions
// Isolation: global_actor. type: CustomGlobalActor  // Custom global actor
// Isolation: actor_instance. name: 'self'       // Actor instance methods
// Isolation: nonisolated                        // nonisolated methods
// Isolation: unspecified                        // Regular functions
```

## `@sil_isolated` Parameter Attribute

Actor-isolated methods use `@sil_isolated` on the `self` parameter:

```sil
// Actor method (ISOLATED) - has @sil_isolated
sil @actorMethod : $@convention(method) (@sil_isolated @guaranteed MyActor) -> Int

// Nonisolated method - NO @sil_isolated
sil @nonisolatedMethod : $@convention(method) (@guaranteed MyActor) -> @owned String
```

## `hop_to_executor` - Where Isolation Happens

**Key insight**: Isolation enforcement happens at the **call site**, not the function body.

```sil
// Calling @MainActor function from non-isolated context
sil @callFromNonIsolated : $@convention(thin) @async () -> Int {
bb0:
  %0 = enum $Optional<Builtin.Executor>, #Optional.none!enumelt
  hop_to_executor %0                              // Start with no executor

  %3 = metatype $@thick MainActor.Type
  %4 = function_ref @MainActor.shared.getter
  %5 = apply %4(%3)                               // Get MainActor.shared
  hop_to_executor %5                              // HOP TO MAIN ACTOR ←
  %7 = apply %2()                                 // Call function
}
```

### Cross-Actor Calls

```sil
// OtherActor calling Counter.increment()
sil @OtherActor.callCounter : $@convention(method) @async (@sil_isolated @guaranteed OtherActor) -> Int {
bb0(%0 : $OtherActor):
  hop_to_executor %0                              // Ensure on OtherActor's executor
  %4 = load %3                                    // Load counter reference
  hop_to_executor %4                              // HOP TO Counter's executor ←
  %8 = apply %6(%4)                               // Call counter.increment()
}
```

## Actor Infrastructure Builtins

```sil
// In actor init
%2 = builtin "initializeDefaultActor"(%0) : $()

// In actor deinit
%2 = builtin "destroyDefaultActor"(%0) : $()

// Building executor reference
%3 = builtin "buildDefaultActorExecutorRef"<MyActor>(%0) : $Builtin.Executor
```

## vtable Shows Isolation

```sil
sil_vtable MyActor {
  #MyActor.actorMethod: (isolated MyActor) -> () -> Int : @$s...
  #MyActor.nonisolatedMethod: (MyActor) -> () -> String : @$s...
}
```

Note: `isolated MyActor` vs just `MyActor` in the type signature.

## Protocol Witness Tables

### Actor Protocol

```sil
sil_witness_table hidden MyActor: Actor module ActorIsolation {
  method #Actor.unownedExecutor!getter: ... @witness_thunk
}
```

### GlobalActor Protocol

```sil
sil_witness_table hidden CustomGlobalActor: GlobalActor module ActorIsolation {
  associated_type ActorType: CustomGlobalActor.ActorType
  method #GlobalActor.shared!getter: ...
  method #GlobalActor.sharedUnownedExecutor!getter: ...
}
```

## Global Actor Pattern

Global actors generate:
1. A nested `ActorType` actor class
2. A `static let shared` property (with one-time initialization)
3. `GlobalActor` protocol witness table

```sil
// One-time initialization for shared
sil private [global_init_once_fn] @$s...shared_WZ : $@convention(c) (Builtin.RawPointer) -> ()
```

## Key Observations

1. **No runtime hop in function body**: The `@MainActor` or actor method body looks exactly like regular code. The isolation is metadata - the actual executor hop happens at the **call site**.

2. **Nonisolated is explicit**: `nonisolated` methods explicitly lack `@sil_isolated` on `self`.

3. **Actor = class + executor**: Actors are essentially classes with built-in executor infrastructure.
