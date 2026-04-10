# `#isolation` Macro Implementation

`#isolation` is a **compile-time macro** (SE-0420) that captures the isolation of the current context. It is **NOT a runtime operation** - it's fully resolved at compile time.

## Compiler Pipeline

```
Source Code
    ↓
[1. Parsing] → CurrentContextIsolationExpr
    ↓
[2. Type Checking] → Synthesize actorExpr
    ↓
[3. SILGen] → Emit appropriate value
```

---

## 1. Parsing (ParseExpr.cpp)

`#isolation` is recognized and becomes `CurrentContextIsolationExpr`:

```cpp
// #isolation is recognized and becomes CurrentContextIsolationExpr
new (Context) CurrentContextIsolationExpr(macroNameLoc.getStartLoc(), Type())
```

---

## 2. Type Checking (TypeCheckConcurrency.cpp)

The `actorExpr` is synthesized based on the caller's isolation:

```cpp
switch (isolation) {
case ActorIsolation::ActorInstance: {
    // actor method → DeclRefExpr to 'self'
    actorExpr = new DeclRefExpr(var, ...);  // var = self
    break;
}
case ActorIsolation::GlobalActor: {
    // @MainActor → MainActor.shared
    actorExpr = UnresolvedDotExpr(TypeExpr(globalActorType), "shared");
    break;
}
case ActorIsolation::Nonisolated:
case ActorIsolation::Unspecified:
    // nonisolated → nil
    actorExpr = NilLiteralExpr();
    break;
case ActorIsolation::CallerIsolationInheriting:
    // Placeholder - resolved in SILGen
    actorExpr = NilLiteralExpr();
    break;
}
isolationExpr->setActor(actorExpr);
```

---

## 3. SILGen (SILGenExpr.cpp)

```cpp
RValue visitCurrentContextIsolationExpr(CurrentContextIsolationExpr *E, ...) {
    auto isolation = getRealActorIsolationOfContext(...);

    if (isolation == ActorIsolation::CallerIsolationInheriting) {
        // Use the isolated argument parameter
        auto *isolatedArg = SGF.F.maybeGetIsolatedArgument();
        return ... isolatedArg ...;
    }

    // Otherwise, emit the synthesized actorExpr
    return visit(E->getActor(), C);
}
```

---

## Expansion by Context

| Caller Context | `#isolation` Expands To |
|----------------|------------------------|
| `@MainActor` | `MainActor.shared` |
| `@CustomGlobalActor` | `CustomGlobalActor.shared` |
| `actor` method | `self` (the actor instance) |
| `distributed actor` | `self.asLocalActor` |
| `nonisolated` | `nil` |
| `isolated` param inheriting | Resolved at SILGen to the param |

---

## SIL Output Examples

### From `@MainActor` context

```sil
%3 = metatype $@thick MainActor.Type
%4 = function_ref @MainActor.shared.getter
%5 = apply %4(%3)                               // MainActor.shared
%6 = init_existential_ref %5 : $MainActor, $any Actor
%7 = enum $Optional<any Actor>, #Optional.some!enumelt, %6
```

### From `actor` method

```sil
%6 = init_existential_ref %0 : $MyActor, $any Actor  // self
%7 = enum $Optional<any Actor>, #Optional.some!enumelt, %6
```

### From `nonisolated` context

```sil
%3 = enum $Optional<any Actor>, #Optional.none!enumelt  // nil
```

---

## Default `= #isolation` vs Explicit `#isolation`

**They produce IDENTICAL SIL.**

```swift
// These are equivalent:
func withDefault(_ body: () -> T, isolation: isolated (any Actor)? = #isolation)
withDefault { ... }

func withExplicit(_ body: () -> T, isolation: isolated (any Actor)?)
withExplicit({ ... }, isolation: #isolation)
```

Both expand to the same SIL at the call site.

---

## Key Quote from SE-0420

> "Note that the special `#isolation` default argument form should always be replaced by something matching the rule above, so calls using this default argument for an isolated parameter will always be to a context that shares isolation."
