# Advanced Isolation Patterns in SIL

## 1. `@isolated(any)` - SE-0431

Allows functions to carry their isolation dynamically.

### Swift

```swift
func runIsolatedAny(_ f: @escaping @isolated(any) () async -> Void) async {
    let iso = f.isolation  // Extract isolation at runtime
    await f()
}
```

### SIL

```sil
sil @runIsolatedAny : $@convention(thin) @async (
    @guaranteed @isolated(any) @async @callee_guaranteed () -> ()
) -> () {
bb0(%0 : $@isolated(any) @async @callee_guaranteed () -> ()):
  %5 = function_extract_isolation %0   // Extract isolation
  %10 = apply %0()                     // Call
}
```

**Key instruction**: `function_extract_isolation`

---

## 2. `sending` Parameter - SE-0430

Marks values that cross isolation boundaries.

### Swift

```swift
@MainActor
func acceptSending(_ ns: sending NonSendable) { }

func produceSending() -> sending NonSendable {
    return NonSendable(value: 42)
}
```

### SIL

```sil
// Parameter
sil @acceptSending : $@convention(thin) (@sil_sending @owned NonSendable) -> ()

// Result
sil @produceSending : $@convention(thin) () -> @sil_sending @owned NonSendable
```

**Key attribute**: `@sil_sending`

---

## 3. `@concurrent` - Swift 6.2

Explicitly marks a function as non-isolated (can run on any executor).

### Swift

```swift
@concurrent
func concurrentWork() async -> Int {
    return 42
}
```

### SIL

```sil
// Isolation: nonisolated
sil @concurrentWork : $@convention(thin) @async () -> Int
```

**Note**: `@concurrent` produces the same SIL as `nonisolated` - it's just `// Isolation: nonisolated`.

---

## 4. `isolated` Parameter

Allows a function to inherit the caller's isolation.

### Swift

```swift
func withIsolation<T>(
    _ isolation: isolated (any Actor)?,
    _ body: () throws -> T
) rethrows -> T {
    try body()
}
```

### SIL

```sil
// Isolation: actor_instance. name: 'isolation'
sil @withIsolation : $@convention(thin) <T> (
    @sil_isolated @guaranteed Optional<any Actor>,
    @guaranteed @noescape @callee_guaranteed ...
) -> ...
```

**Key**: The parameter itself gets `@sil_isolated`.

---

## 5. `consuming sending` (~Copyable)

For non-copyable types, `sending` requires `consuming`.

### Swift

```swift
func consumeSending(_ x: consuming sending NonCopyable) {
    print(x.value)
}
```

### SIL

```sil
sil @consumeSending : $@convention(thin) (@sil_sending @owned NonCopyable) -> ()
```

---

## 6. `nonisolated(unsafe)`

Opt-out of isolation checking (unsafe).

### Swift

```swift
class UnsafeShared {
    nonisolated(unsafe) static var shared: NonSendable = NonSendable()
}
```

### SIL

```sil
// Shows in declaration, no special instruction
@_hasStorage @_hasInitialValue nonisolated(unsafe) static var shared: NonSendable
```

---

## Summary Table

| Swift | SIL Representation |
|-------|-------------------|
| `@isolated(any)` | `$@isolated(any) @async @callee_guaranteed () -> ()` |
| `f.isolation` | `function_extract_isolation %fn` |
| `sending` param | `@sil_sending @owned T` |
| `sending` result | `-> @sil_sending @owned T` |
| `@concurrent` | `// Isolation: nonisolated` |
| `isolated` param | `@sil_isolated @guaranteed Optional<any Actor>` |
| `nonisolated(unsafe)` | Attribute on declaration only |
