# Ownership Modifiers with `sending` on ~Copyable Types

When using `sending` with `~Copyable` types, you must specify an ownership modifier. Not all combinations are valid.

## Valid Combinations

| Combination | SIL | Description |
|-------------|-----|-------------|
| `consuming sending` | `@sil_sending @owned` | Takes ownership and sends to another isolation |
| `inout sending` | `@sil_sending @inout` | Sends, allows mutation, value returns to caller |

## Invalid Combinations

| Combination | Error |
|-------------|-------|
| `borrowing sending` | `'sending' cannot be used together with 'borrowing'` |
| `sending` (no modifier) | `parameter of noncopyable type must specify ownership` |

---

## `consuming sending`

Takes ownership of the value and sends it to another isolation domain. The caller cannot use the value after the call.

```swift
func consumingSending(_ x: consuming sending NonCopyable) {
    print(x.value)
}

func test() {
    let nc = NonCopyable(value: 10)
    consumingSending(nc)
    // nc is consumed, can't use anymore
}
```

**SIL:**

```sil
sil @consumingSending : $@convention(thin) (@sil_sending @owned NonCopyable) -> ()
```

---

## `inout sending`

Sends the value to another isolation domain, allows mutation, then the value returns to the caller.

```swift
@MainActor
func mainActorInout(_ x: inout sending NonCopyable) {
    x.value += 100
}

func test() async {
    var nc = NonCopyable(value: 1)
    await mainActorInout(&nc)  // Send → mutate → return
    print(nc.value)            // ✅ Still usable (101)
}
```

**SIL:**

```sil
sil @mainActorInout : $@convention(thin) (@sil_sending @inout NonCopyable) -> ()
```

---

## Why `borrowing sending` is Invalid

```swift
// error: 'sending' cannot be used together with 'borrowing'
func borrowingSending(_ x: borrowing sending NonCopyable) { }
```

These modifiers are semantically contradictory:

- `borrowing` = temporary access, value **stays** with caller
- `sending` = value **transfers** to another isolation domain

You cannot simultaneously keep a value and send it away.

---

## Why `sending` Alone is Invalid for ~Copyable

```swift
// error: parameter of noncopyable type 'NonCopyable' must specify ownership
func justSending(_ x: sending NonCopyable) { }
```

For `~Copyable` types, Swift requires explicit ownership because:
- The value cannot be implicitly copied
- The compiler needs to know: consume it? borrow it? mutate it?

For `Copyable` types, `sending` alone is valid (implicitly `consuming`).

---

## Comparison: Copyable vs ~Copyable

| Type | `sending` alone | `consuming sending` | `inout sending` | `borrowing sending` |
|------|-----------------|---------------------|-----------------|---------------------|
| Copyable | ✅ | ✅ | ✅ | ❌ |
| ~Copyable | ❌ | ✅ | ✅ | ❌ |

---

## SIL Comparison

| Swift | SIL |
|-------|-----|
| `sending T` (Copyable) | `@sil_sending @owned` |
| `consuming sending T` (Copyable) | `@sil_sending @owned` |
| `inout sending T` (Copyable) | `@sil_sending @inout` |
| `consuming sending T` (~Copyable) | `@sil_sending @owned` |
| `inout sending T` (~Copyable) | `@sil_sending @inout` |

**Key insight**: For Copyable types, `sending` alone produces **identical SIL** to `consuming sending` — both become `@sil_sending @owned`. The `consuming` keyword is implicit for Copyable types with `sending`.
