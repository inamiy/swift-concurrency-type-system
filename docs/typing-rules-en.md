# Swift Concurrency as Capability + Region Type System (English)

This document systematically summarizes the typing rules for Swift 6.2 Concurrency.

> Important: For the ground truth of function type conversions involving isolation (sync/async), always refer to:
> - `swift/Sources/concurrency-type-check/FuncConversionRules.swift`
> - `docs/diagrams/func-conversion-rules.mmd`

## Table of Contents

<!-- START ToC -->

- [1. Judgment Forms (Judgment)](#1-judgment-forms-judgment)
  - [1.1 Connection to Swift (function/task body)](#11-connection-to-swift-functiontask-body)
- [2. Symbols and Auxiliary Definitions (Definitions)](#2-symbols-and-auxiliary-definitions-definitions)
  - [2.1 Capability (`@κ`) and Function Type Annotation (`@φ`)](#21-capability-κ-and-function-type-annotation-φ)
    - [Capability (`@κ`)](#capability-κ)
    - [Function Type Annotation (`@φ = @σ @ι`)](#function-type-annotation-φ--σ-ι)
    - [Conversion from `@ι` to capability `@κ` (`toCapability`)](#conversion-from-ι-to-capability-κ-tocapability)
    - [Actor Isolation predicate (`isActorIsolated`)](#actor-isolation-predicate-isactorisolated)
  - [2.2 Region (`ρ`)](#22-region-ρ)
    - [Canonical Form Condition](#canonical-form-condition)
  - [2.3 Region Access (`accessible(@κ)`)](#23-region-access-accessibleκ)
  - [2.4 Region Merge (`ρ₁ ⊔ ρ₂`)](#24-region-merge-ρ--ρ)
  - [2.5 Capability → Region Conversion (`toRegion(@κ)`)](#25-capability--region-conversion-toregionκ)
  - [2.6 Closure Auxiliary Definitions (`@Sendable` / isolation inference)](#26-closure-auxiliary-definitions-sendable--isolation-inference)
    - [`@Sendable` capture constraint (`isAllSendable`)](#sendable-capture-constraint-isallsendable)
    - [Closure Isolation Inference](#closure-isolation-inference)
      - [`inheritActorContext`](#inheritactorcontext)
      - [`isPassedToSendingParameter`](#ispassedtosendingparameter)
    - [Isolation inference boundary determination (does not inherit parent isolation)](#isolation-inference-boundary-determination-does-not-inherit-parent-isolation)
      - [Actor-instance capture requirement (`capturesIsolatedParam`)](#actor-instance-capture-requirement-capturesisolatedparam)
      - [Effective capability of actor-instance isolation (`effectiveClosureCapability`)](#effective-capability-of-actor-instance-isolation-effectiveclosurecapability)
    - [Capture eligibility (`capturable(@κ)`)](#capture-eligibility-capturableκ)
    - [`@concurrent` closure literal](#concurrent-closure-literal)
  - [2.7 Send Eligibility Predicate (`canSend`)](#27-send-eligibility-predicate-cansend)
    - [Definition of `[sending]`](#definition-of-sending)
    - [`canSend`](#cansend)
  - [2.8 Sendable Inference Auxiliary Definitions (SE-0418)](#28-sendable-inference-auxiliary-definitions-se-0418)
  - [2.9 Isolation Subtyping / Coercion (`isoSubtyping`, `isoCoercion`)](#29-isolation-subtyping--coercion-isosubtyping-isocoercion)
- [3. Sync/Async Boundaries](#3-syncasync-boundaries)
  - [3.1 async Function Body (introduction boundary of `α`)](#31-async-function-body-introduction-boundary-of-α)
    - [decl-fun-isolated-param](#decl-fun-isolated-param)
    - [decl-fun-isolation-inheriting](#decl-fun-isolation-inheriting)
  - [3.2 `Task { ... }` / `Task.detached { ... }` Body](#32-task-----taskdetached----body)
- [4. Relation Rules](#4-relation-rules)
  - [4.1 Isolation Subtyping](#41-isolation-subtyping)
    - [iso-subtyping-identity](#iso-subtyping-identity)
    - [iso-subtyping-sendable-forget](#iso-subtyping-sendable-forget)
    - [iso-subtyping-nonisolated-to-isolated-any](#iso-subtyping-nonisolated-to-isolated-any)
    - [iso-subtyping-mainactor-to-isolated-any](#iso-subtyping-mainactor-to-isolated-any)
    - [iso-subtyping-mainactor-implicit-sendable](#iso-subtyping-mainactor-implicit-sendable)
    - [`@isolated(localActor)` special branch](#isolatedlocalactor-special-branch)
    - [iso-subtyping-transitive](#iso-subtyping-transitive)
    - [iso-subtyping-to-coercion](#iso-subtyping-to-coercion)
  - [4.2 Isolation Coercion](#42-isolation-coercion)
    - [iso-coercion-isolated-any-to-nonisolated-deprecated](#iso-coercion-isolated-any-to-nonisolated-deprecated)
    - [iso-coercion-sendable-nonisolated-universal](#iso-coercion-sendable-nonisolated-universal)
    - [iso-coercion-async-mainactor-universal](#iso-coercion-async-mainactor-universal)
    - [iso-coercion-async-nonsendable-equiv](#iso-coercion-async-nonsendable-equiv)
    - [Conversion Matrix](#conversion-matrix)
    - [Conversion Diagram](#conversion-diagram)
    - [Group Analysis](#group-analysis)
- [5. Typing Rules](#5-typing-rules)
  - [5.1 Variables](#51-variables)
    - [var](#var)
  - [5.2 Sequencing](#52-sequencing)
    - [seq](#seq)
  - [5.3 Function Type Conversion](#53-function-type-conversion)
    - [sync-to-async](#sync-to-async)
    - [func-conv](#func-conv)
    - [isolated-any-to-async](#isolated-any-to-async)
    - [Subtyping / Coercion Verification Table](#subtyping--coercion-verification-table)
    - [Conversion via Closure Wrapping](#conversion-via-closure-wrapping)
  - [5.4 Region Merge (Aliasing / Assignment)](#54-region-merge-aliasing--assignment)
    - [region-merge](#region-merge)
  - [5.5 Function Calls](#55-function-calls)
    - [call-nonsendable-noconsume](#call-nonsendable-noconsume)
      - [Example of noconsume: same concrete actor + sending](#example-of-noconsume-same-concrete-actor--sending)
      - [noconsume vs consume (Same vs Cross)](#noconsume-vs-consume-same-vs-cross)
      - [Difference from `call-same-nonsendable-merge` (bind vs no-bind)](#difference-from-call-same-nonsendable-merge-bind-vs-no-bind)
    - [call-nonsendable-consume](#call-nonsendable-consume)
      - [Correspondence with the Compiler](#correspondence-with-the-compiler)
      - [Example of consume: nonisolated + sending](#example-of-consume-nonisolated--sending)
      - [Example of consume: cross-isolation implicit sending](#example-of-consume-cross-isolation-implicit-sending)
      - [Example of consume: cross-isolation explicit sending](#example-of-consume-cross-isolation-explicit-sending)
    - [call-same-sync-sendable](#call-same-sync-sendable)
    - [call-same-async-sendable](#call-same-async-sendable)
    - [call-same-nonsendable-merge](#call-same-nonsendable-merge)
    - [call-cross-sendable](#call-cross-sendable)
    - [call-cross-sending-result](#call-cross-sending-result)
    - [call-cross-nonsending-result-error](#call-cross-nonsending-result-error)
    - [call-concurrent-sendable](#call-concurrent-sendable)
    - [call-concurrent-nonsendable](#call-concurrent-nonsendable)
    - [call-nonisolated-async-inherit](#call-nonisolated-async-inherit)
    - [call-nonisolated-sync](#call-nonisolated-sync)
    - [Supplementary Explanations](#supplementary-explanations)
      - [call-isolated-param-semantics](#call-isolated-param-semantics)
      - [call-isolation-macro-semantics](#call-isolation-macro-semantics)
  - [5.6 `@isolated(any)`](#56-isolatedany)
    - [isolated-any-isolation-prop (`f.isolation`)](#isolated-any-isolation-prop-fisolation)
  - [5.7 Closures](#57-closures)
    - [closure-inherit-parent](#closure-inherit-parent)
    - [closure-no-inherit-parent](#closure-no-inherit-parent)
    - [closure-sending](#closure-sending)
  - [5.8 `async let`](#58-async-let)
    - [async-let](#async-let)
    - [async-let-access](#async-let-access)
  - [5.9 Sendable Inference (SE-0418)](#59-sendable-inference-se-0418)
    - [infer-sendable-nonlocal](#infer-sendable-nonlocal)
    - [infer-sendable-method-sendable](#infer-sendable-method-sendable)
    - [infer-sendable-method-non-sendable](#infer-sendable-method-non-sendable)
    - [infer-sendable-keypath](#infer-sendable-keypath)
- [6. Examples](#6-examples)
  - [Example 1: Same isolation (nonsending binds but does not consume)](#example-1-same-isolation-nonsending-binds-but-does-not-consume)
  - [Example 2: Same isolation (`sending` does not consume — Same vs Cross)](#example-2-same-isolation-sending-does-not-consume--same-vs-cross)
  - [Example 3: Different isolation (implicit transfer is consumed)](#example-3-different-isolation-implicit-transfer-is-consumed)
  - [Example 4: Different isolation (explicit `sending` is consumed)](#example-4-different-isolation-explicit-sending-is-consumed)
  - [Example 5: `Task` capture (same-actor `Task.init` retains; otherwise consumes)](#example-5-task-capture-same-actor-taskinit-retains-otherwise-consumes)
  - [Example 6: nonisolated async arguments behave like `task` (SE-0461)](#example-6-nonisolated-async-arguments-behave-like-task-se-0461)
  - [Example 7: `@isolated(any)` calls require `await` even with a sync signature (SE-0431)](#example-7-isolatedany-calls-require-await-even-with-a-sync-signature-se-0431)
  - [Example 8: `isolated` parameter — sync access + cross-isolation await (SE-0313)](#example-8-isolated-parameter--sync-access--cross-isolation-await-se-0313)
  - [Example 9: Cross-isolation NonSendable result without `sending` → error](#example-9-cross-isolation-nonsendable-result-without-sending--error)
  - [Example 10: `#isolation` eliminates the need for `@Sendable` + enables `inout` access (SE-0420)](#example-10-isolation-eliminates-the-need-for-sendable--enables-inout-access-se-0420)
  - [Example 11: Nonisolated sync — “callable from” ≠ “convertible to” (call vs capture)](#example-11-nonisolated-sync--callable-from--convertible-to-call-vs-capture)

<!-- END ToC -->

---

## 1. Judgment Forms (Judgment)

Following the convention of linear type systems, the output context is made explicit:

```text
Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'
```

- `Γ` / `Γ'`: type environment (input / output). Elements are of the form `x : T at ρ`.
- `@κ`: capability (the isolation of the execution context).
- `α`: async mode (whether `await` can be written).
- `ρ`: value region (the alias set for NonSendable values, or `_`).

```text
α ::= sync | async
sync ⊑ async
```

### 1.1 Connection to Swift (function/task body)

Swift function bodies and `Task` operations are statement blocks, but in this document we write rules targeting **`body` lowered to expressions** (following the standard convention of type theory).

Furthermore, Swift `func` is a **declaration**, not an "expression" in the sense of this type system. Therefore, `func` is not mixed into the primary judgment `Γ; @κ; α ⊢ e : ... ⊣ Γ'` of this system.

However, as a connection to Swift, without specifying "how the attributes of a declaration determine the `@κ` / `α` of its body," it becomes ambiguous where `await` is permitted (i.e., where `α` becomes `async`).

Therefore, this document does not handle the static semantics of declarations themselves (parameter environment formation, name binding, etc.), but uses a minimal judgment `⊢_d` to express the well-typedness of a declaration — stating only "in what context Swift checks the body" (see `decl-fun` for details):

```text
Δ ⊢_d decl
```

This judgment expresses the proposition (true/false) that "`decl` is statically consistent (well-typed / well-formed)." That is, in this minimal version, the declaration judgment does not return output types or environments (it can be extended in the future as `Δ ⊢ decl ⊣ Δ'` if needed).

Here `Δ` represents the "program-level declaration environment (which names are available in the outer scope)." The expression judgment `Γ; @κ; α ⊢ e : ... ⊣ Γ'` is also technically relative to `Δ`, but hereafter `Δ` is omitted for notational brevity.

Note: `⊢_d` is not "a different symbol for `⊢`" — it is a label to make explicit that this is a **separate judgment form** where the right-hand side of `⊢` states "the consistency of a decl." In TAPL it is common to have multiple judgment forms under the same `⊢`, such as `Γ ⊢ t : T` (typing) alongside `Γ ⊢ t =_{ctx} t' : T` (contextual equivalence).

---

## 2. Symbols and Auxiliary Definitions (Definitions)

### 2.1 Capability (`@κ`) and Function Type Annotation (`@φ`)

In this document, the second element of the judgment form (the isolation of the execution context) and the attribute annotations on function types are **separated at the grammar level**.

#### Capability (`@κ`)

`@κ` represents "which isolation domain the current execution context belongs to":

```text
@κ ::= @nonisolated | @isolated(a)

a  ::= globalActor | localActor
```

Shorthand: `@MainActor ≡ @isolated(MainActor)`. Here `MainActor` is one example of a `globalActor`.

#### Function Type Annotation (`@φ = @σ @ι`)

The attribute annotations attached to function types are denoted `@φ`:

```text
@σ ::= ·          (no @Sendable)
    | @Sendable   (explicit @Sendable)

@ι ::= @κ
   | @isolated(any)
   | @concurrent         (async only)

@φ ::= @σ @ι
```

Projections used below:

```text
proj_σ(@φ) = @σ
proj_ι(@φ) = @ι
```

#### Conversion from `@ι` to capability `@κ` (`toCapability`)

Used in `decl-fun` and elsewhere to determine the capability of the body from a function's `@ι`:

```text
toCapability : @ι → @κ

toCapability(@κ)             = @κ              (since @κ ⊆ @ι, identity)
toCapability(@isolated(any)) = @nonisolated
toCapability(@concurrent)    = @nonisolated
```

Note: `@concurrent` represents "explicit nonisolated" that appears only in async function types, and is independent of `@Sendable`. From the perspective of SE-0461, the correspondence is as follows:

| Type (shorthand) | SE-0461 Formal Name | Execution semantics (summary) |
|---|---|---|
| `normal sync` | `nonisolated` | On the caller's executor (no switch) |
| `normal async` | `nonisolated(nonsending)` | On the caller's actor (no switch, similar to sync) |
| `@concurrent async` | `@concurrent` (explicit) | Hops off the actor (switch OFF actor) |

**Important**: The difference between `normal async` and `@concurrent async` lies primarily in:

- **Call-site sendability / region conditions** (`@concurrent` hops off the actor, so calling from an actor-capable context requires `Sendable` or `disconnected`)
- **Execution semantics** (`normal async` inherits the caller actor, `@concurrent async` hops off the actor)

(SE-0461: `swiftlang/swift-evolution/proposals/0461-async-function-isolation.md`)

On the other hand, **the rules for closure isolation inference themselves are unchanged by `@concurrent`** (SE-0461 "Isolation inference for closures").
Unless the contextual type is `@Sendable` / `sending`, a closure may inherit the outer isolation.
When `@concurrent` is required, consistency is achieved via **function type conversion (thunk generation)** (SE-0461 "Function conversions").

Q. Is it acceptable to include `@concurrent` in `@ι`?

A. Yes. However, it is necessary to make explicit in the rules the point that `@concurrent` **appears only in async function types**, and that it differs from `@nonisolated async` (= `nonisolated(nonsending)`) in that **"the actor is inherited (nonsending) / the actor is exited (@concurrent)"** (see `call-concurrent-*` below).

In this document, the "actor identity" aspect of `@concurrent` is treated the same as `@nonisolated` (= does not belong to a specific actor). For access/capture purposes, `toCapability(@concurrent) = @nonisolated` yields capability `@nonisolated`.
The switch-off semantics of `@concurrent` (call-site sendability / region conditions) are handled in `call-concurrent-*`.

**Compiler basis**: The Swift compiler's `getIsolationFromAttributes()` (`TypeCheckConcurrency.cpp`) converts `@concurrent` to `Nonisolated` at the earliest stage of isolation determination:

```cpp
// @concurrent → Nonisolated(no actor identity)
if (concurrentAttr)
    return ActorIsolation::forNonisolated(/*is unsafe*/ false);
```

In contrast, SE-0461's `nonisolated(nonsending)` is handled as `CallerIsolationInheriting` (inheriting the caller's isolation at runtime):

```cpp
if (nonisolatedAttr->isNonSending())
    return ActorIsolation::forCallerIsolationInheriting();
```

| Swift syntax | Compiler internal | Body `@κ` |
|---|---|---|
| `@concurrent async` | `Nonisolated` | `@nonisolated` |
| `nonisolated(nonsending) async` | `CallerIsolationInheriting` | `@nonisolated` |
| `@MainActor` | `GlobalActor(MainActor)` | `@isolated(MainActor)` |

All of these reduce to `@κ ∈ { @nonisolated, @isolated(a) }` at the level of body type checking.
The difference between `@concurrent` and `nonisolated(nonsending)` manifests only in call-site semantics (`call-concurrent-*` vs [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit)).

#### Actor Isolation predicate (`isActorIsolated`)

```text
isActorIsolated(@κ) ⟺ @κ ∉ { @nonisolated }
```

A predicate that determines whether `@κ` has a concrete actor isolation (e.g., `@MainActor`, `@isolated(a)`).
`@nonisolated` does not belong to a specific actor, so it evaluates to false.
Used in the consumption condition `isActorIsolated(@κ) ∧ @κ = @ι` of [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume).

### 2.2 Region (`ρ`)

```text
// ns = non-sendable
ρ_{ns} ::= disconnected
        | isolated(a)
        | task
        | invalid  (underivable / compile error)

ρ ::= ρ_{ns}
   | _           (for Sendable)
```

`disconnected` does not mean "accessible from anywhere" but rather "**not yet bound to any isolation domain**" (binding occurs via merge/bind).
The domain of the merge operation `⊔` in [`region-merge`](#region-merge) is restricted to `ρ_{ns}`.

`_` is the canonical tag for Sendable values and is not included in the domain of `⊔`.

#### Canonical Form Condition

The correspondence between `Sendable` values and region `_` is given not as part of individual expression rules, but as a canonical form condition on environments:

```text
∀ (x : T at ρ) ∈ Γ.  (T : Sendable ⇔ (ρ = _))
```

Hereafter, the judgment `Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'` implicitly assumes that the input environment `Γ` satisfies this canonical form condition.
Rules that update the environment are also designed to preserve the same canonical form condition after the update.

### 2.3 Region Access (`accessible(@κ)`)

`accessible(@κ)` returns "the set of regions **directly accessible** under capability `@κ`":

```text
accessible(@κ) : P(Regions)

accessible(@nonisolated) = { disconnected, task, _ }
accessible(@isolated(a)) = { disconnected, isolated(a), task, _ }
```

`ρ ∈ accessible(@κ)` means "values in region `ρ` are accessible under capability `@κ`".

`disconnected` is accessible from any isolation, so `disconnected ∈ accessible(@κ)` holds for all `@κ`.

Note: `isolated(a) ∈ accessible(@isolated(a))` holds only when it is the same actor.

### 2.4 Region Merge (`ρ₁ ⊔ ρ₂`)

`ρ₁ ⊔ ρ₂` denotes the region merge operation (SE-0414). Its domain is `ρ_{ns} × ρ_{ns}`, and is given minimally by the following table:

| ρ₁ | ρ₂ | ρ₁ ⊔ ρ₂ |
|---|---|---|
| disconnected | disconnected | disconnected |
| disconnected | isolated(a) | isolated(a) |
| disconnected | task | task |
| isolated(a) | isolated(a) | isolated(a) |
| isolated(a) | isolated(b) | invalid (a ≠ b) |
| isolated(a) | task | invalid |
| task | task | task |

`invalid` is an **extended region** representing "underivable (a compile error in Swift)", included in `ρ_{ns}` to keep the merge operation total/closed.

**Semilattice structure**: `⊔` forms a join-semilattice that gives the join (least upper bound) with respect to the following order:

```text
       invalid (⊤)
      /       \
isolated(a)   task
      \       /
    disconnected (⊥)
```

- `disconnected` is the bottom of `ρ_{ns}` (`disconnected ⊔ ρ = ρ` for all `ρ ∈ ρ_{ns}`).
- `_` is not an element of the join; it is assigned only to Sendable values by the canonical form condition `T : Sendable ⇔ ρ = _`.
- Therefore, joins in region computations such as `ρ_{closure} = ⨆{...}` target only NonSendable captures, and the empty join is `disconnected`.
- `invalid` is the top of the extended domain and is used as a compact notation indicating "this merge/refinement represents a failure state."

### 2.5 Capability → Region Conversion (`toRegion(@κ)`)

A function for writing the "binding" in [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) without conflating capabilities and regions:

```text
toRegion(@κ) : ρ_{ns}

toRegion(@isolated(a)) = isolated(a)
toRegion(@nonisolated)  = disconnected
```

Intent: Binding a NonSendable value within the same isolation is limited to cases **where the concrete actor is statically known** (`@nonisolated` does not bind).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_merge_thenCrossSend_isError()` (under `@MainActor`, a value is bound and can no longer be transferred via `sending`)

```swift
@MainActor
func bindThenCannotSendExample() async {
    let x = NonSendable() // disconnected
    mainActorUseNonSendable(x) // binds/refines `x` into @MainActor region

    let other = OtherActor()
    // await other.useNonSendableSending(x) // ❌ error: not disconnected (negative test)
}
```

### 2.6 Closure Auxiliary Definitions (`@Sendable` / isolation inference)

#### `@Sendable` capture constraint (`isAllSendable`)

`@Sendable` constrains not "what can be accessed" but "what may be captured."
For a closure's capture environment `Γ_{captured}`, the following predicate is used:

```text
isAllSendable(Γ_{captured}) : Bool

isAllSendable(Γ_{captured})
  ⇔  ∀ (x : T at ρ) ∈ Γ_{captured}.  T : Sendable
```

`isAllSendable(Γ_{captured})` is used only as a premise of [`closure-no-inherit-parent`](#closure-no-inherit-parent).
Non-`@Sendable` closures are not subject to this constraint and are handled by [`closure-inherit-parent`](#closure-inherit-parent).

#### Closure Isolation Inference

Non-`@Sendable` closures inherit the parent context's capability `@κ` directly.
`@Sendable` closures (and closures passed to `sending`) become isolation inference boundaries (they do not inherit the parent's isolation) and are type-checked under `@nonisolated`.

This principle is the core distinction between [`closure-inherit-parent`](#closure-inherit-parent) and [`closure-no-inherit-parent`](#closure-no-inherit-parent), and is stated by the following 2 meta-rules.

The isolation inference boundary referred to here is the cutoff for the process of "automatically inferring a closure's isolation by inheriting from the parent context."
When a boundary applies, the isolation of the closure body is determined not from the parent but from the closure's own context (contextual type / signature / explicit annotations).

##### `inheritActorContext`

```text
inheritActorContext(closure) : Bool
```

True when the closure's parameter is annotated with `@_inheritActorContext`.
When true, the parent's `@κ` is inherited even if the closure is `@Sendable` (it does not become a boundary).

##### `isPassedToSendingParameter`

```text
isPassedToSendingParameter(closure) : Bool
```

True when the closure is passed to a `sending` parameter.
When true, the closure becomes an isolation inference boundary and its captures are consumed ([`closure-sending`](#closure-sending)).

#### Isolation inference boundary determination (does not inherit parent isolation)

The compiler (`isIsolationInferenceBoundaryClosure()` in `TypeCheckConcurrency.cpp`) determines this in the following priority order:

```text
isIsolationInferenceBoundary(closure) : Bool

isIsolationInferenceBoundary(closure) =
  false   if inheritActorContext(closure)                    // @_inheritActorContext takes highest priority
  true    if isPassedToSendingParameter(closure)             // sending → closure-sending
  true    if closure's contextual type is @Sendable          // → closure-no-inherit-parent
  false   otherwise                                          // → closure-inherit-parent
```

Individual closure rules do not use `isIsolationInferenceBoundary` directly; instead they make conditions explicit using the individual predicates above.

##### Actor-instance capture requirement (`capturesIsolatedParam`)

```text
capturesIsolatedParam(closure) : Bool
```

Whether the closure body **actually references** the isolated parameter of the parent context (including the implicit `self` of an actor method).
Merely listing it in the capture list is insufficient; a reference in the body (such as `_ = self`, `self.state`, `_ = actor`, etc.) is required.

Compiler implementation: `computeClosureIsolationFromParent()` in `TypeCheckConcurrency.cpp` calls `closureAsFn.getCaptureInfo().getIsolatedParamCapture()` in the `ActorInstance` case to check whether the isolated parameter is captured.

This predicate is meaningful only when `@κ = @isolated(localActor)`. When `@κ = @isolated(globalActor)`, isolation is a type-level property and does not depend on whether a capture occurs.

##### Effective capability of actor-instance isolation (`effectiveClosureCapability`)

Determines the effective capability inherited from the parent context by a non-`@Sendable` closure:

```text
effectiveClosureCapability(@κ, closure) : @κ

effectiveClosureCapability(@nonisolated, _)         = @nonisolated
effectiveClosureCapability(@isolated(globalActor), _) = @isolated(globalActor)
effectiveClosureCapability(@isolated(localActor), closure) =
  @isolated(localActor)   if capturesIsolatedParam(closure)
  @nonisolated             otherwise
```

Rationale: Isolation to an actor instance is maintained through implicit `self` capture, but since implicit captures can cause reference cycles, the compiler does not perform captures invisible to the programmer (as stated explicitly in SE-0461 "Isolation inference for closures").
Global actors (such as `@MainActor`) are type-level properties and therefore do not require a capture.

Note: This rule was introduced in SE-0306 (Swift 5.5) and extended to non-optional binding captures in SE-0420. It was first formally stated in SE-0461, but the rule itself is not new.

#### Capture eligibility (`capturable(@κ)`)

The `task` region represents "NonSendable values bound to this async task."
Capturing a `task` value into a closure bound to a different actor can lead to data races, so this document defines the set of capturable regions `capturable(@κ)` separately from `accessible(@κ)`.

```text
capturable(@κ) : P(Regions)

capturable(@κ) ⊆ accessible(@κ)

capturable(@nonisolated) = { disconnected, task, _ }
capturable(@isolated(a)) = { disconnected, isolated(a), _ }
```

The only difference from `accessible` is the `task` region: `task ∈ accessible(@isolated(a))` but `task ∉ capturable(@isolated(a))`.

- Capture of `ρ = task` is permitted only for `@nonisolated` (prohibited for `@isolated(a)`)
    - NOTE: `@isolated(any)` closures have their body checked under `toCapability(@isolated(any)) = @nonisolated`, so `task ∈ capturable(@nonisolated)` applies

This is necessary to explain the actual behavior of nonisolated parameters:

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolated_paramCapture_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolated_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_SYNC_PARAM_MAINACTOR_CAPTURE`)

```swift
func nonisolated_paramCaptureExample(_ x: NonSendable) {
    let _: () -> Void = { _ = x.value }
    let _: @isolated(any) () -> Void = { _ = x.value }

    // let _: @MainActor () -> Void = { _ = x.value } // ❌ error: cannot capture task-region into @MainActor
}
```

#### `@concurrent` closure literal

`@concurrent` is an attribute that specifies the **execution semantics** of an async function (hopping off the actor); closure isolation inference (whether to inherit the outer isolation) is governed by SE-0461's rules and **is determined by `@Sendable` / `sending`**.

Therefore, even if `@concurrent () async -> Void` is required in a `@MainActor` context, the closure itself may be inferred as `@MainActor` if it is not `@Sendable` / `sending`.
Consistency is then achieved at the point of assignment via a **function type conversion (thunk)** to `@concurrent` (SE-0461 "Function conversions").

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `concurrentAsyncClosureLiteral_canAccessMainActorState_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_concurrentSyncType_isError()` (`NEGATIVE_CONCURRENT_SYNC_IS_INVALID`)

```swift
@MainActor
func concurrentClosureLiteralExample() {
    // NOTE: closure isolation inference is unchanged by `@concurrent` itself.
    let f: @concurrent () async -> Void = {
        _ = mainActorConnectedVar.value
    }
    _ = f

    // let _: @concurrent () -> Void = {} // ❌ error: `@concurrent` is async-only (negative test)
}
```

### 2.7 Send Eligibility Predicate (`canSend`)

A predicate for determining whether a `~Sendable` value is subject to a send operation. Used in [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) and [`call-nonsendable-consume`](#call-nonsendable-consume).

#### Definition of `[sending]`

`[sending]` is an optional symbol indicating whether a parameter has the `sending` keyword:

```text
[sending] ::= sending      (explicit sending parameter)
            | ·             (no sending)
```

`[sending] ∈ { sending }` is true when `[sending]` resolves to `sending`.

#### `canSend`

```text
canSend(@κ, @ι, [sending]) ⟺
    [sending] ∈ { sending }                              (explicit sending parameter)
  ∨ (@κ ≠ @ι ∧ @ι ∉ { @nonisolated })                    (implicit cross-isolation transfer)
```

Note: The reason `@ι ∉ { @nonisolated }` appears on the implicit transfer side of `canSend` is that `@nonisolated async` of `nonsending` is handled separately in [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit).
If `sending` is made explicit, a send occurs even for `@nonisolated`.

### 2.8 Sendable Inference Auxiliary Definitions (SE-0418)

```text
isNonLocal(f) : Bool

isNonLocal(f) =
  true    if f is a top-level (module-scope) function declaration
  true    if f is a static method declaration
  false   otherwise
```

Note: In the compiler implementation, top-level functions are identified by `DC->isModuleScopeContext()`. Static methods go through the member path and check the Sendability of the metatype; since metatypes are always `Sendable`, they unconditionally become `@Sendable`.

```text
instanceMethods(T) : Set<MethodDecl>

instanceMethods(T) =
  { m | m is an instance method declaration of T }
```

Note: Static methods are included in `isNonLocal` and therefore not included here. In the compiler implementation they are identified by `decl->isInstanceMember()` (TypeOfReference.cpp:1024).

```text
hasIsolatedKeyPathComponent(kp) : Bool
  — true if any component of the KeyPath is actor-isolated (ActorInstance or GlobalActor)

isAllSendable(captures(kp)) : Bool
  — true if all captures of the KeyPath conform to Sendable
```

### 2.9 Isolation Subtyping / Coercion (`isoSubtyping`, `isoCoercion`)

This section distinguishes two judgments. The `func-conv` rule directly references the latter, `isoCoercion`.

```text
isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')
isoCoercion(@σ₁, ι₁, @σ₂, ι₂, α')
```

Meanings:
- `isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')`
  - A function type with annotation `(@σ₁, ι₁)` is a **semantic subtype** of a function type with annotation `(@σ₂, ι₂)` under the same parameter types, return type, and async mode `α'`
- `isoCoercion(@σ₁, ι₁, @σ₂, ι₂, α')`
  - The compiler permits a **one-step direct coercion** from a function type with annotation `(@σ₁, ι₁)` to one with annotation `(@σ₂, ι₂)`

Important:
- `isoSubtyping` is a semantic relation and is closed under `iso-subtyping-transitive`
- `isoCoercion` is a **one-step contextual coercion judgment** and its transitive closure is not taken in this section
- Therefore, a multi-step coercion chain can be explained conceptually, but it is distinct from a single `isoCoercion` derivation

Unlike `isActorIsolated` (a function `→ Bool`) or `toCapability` (a function `→ @κ`), both are defined as sets of inference rules.
They hold when derivable under any of the corresponding rules, and do not hold (meaning the conversion is a type error) when derivable under none.

- `@σ₁, @σ₂`: Sendability annotations (`·` or `@Sendable`)
- `ι₁, ι₂`: isolation slots (source / target)
  - Normal forms: `@nonisolated`, `@isolated(globalActor)`, `@isolated(any)`, `@concurrent`
  - Special form: `@isolated(localActor)` (shorthand representing the local actor parameter branch of `(isolated LocalActor, ...) -> ...`)
- `α'`: the async mode of the function itself (`sync` or `async`)

---

## 3. Sync/Async Boundaries

This document does not introduce effect annotations `! ε` on expressions as in Algebraic Effects for asynchronous computations. Instead, `α` (ambient sync/async mode) explicitly marks **where `async` begins** as a syntactic boundary.

### 3.1 async Function Body (introduction boundary of `α`)

In Swift, `func ... async -> R { ... }` is a **declaration**, not an "expression" in the sense used in this document. Therefore this document does not type-check `func` as an expression; instead, a separate judgment `Δ ⊢_d decl` specifies only "which `@κ` / `α` a declaration uses to check its body."

For example, a `@MainActor async` function declaration (with parameters `xᵢ : Aᵢ`) requires that "the body can be type-checked under `@isolated(MainActor)` with `α=async`":

```text
Γ_{body} = x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
Γ_{body}; @isolated(MainActor); async ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────────────────── (decl-fun-mainactor-async)
Δ ⊢_d @MainActor func foo(x₁ : A₁, …, xₙ : Aₙ) async -> R { body }
```

Reading: "The body `body` of `@MainActor func foo(...) async` is checked in a context where `await` can be written (`α=async`)."

Note: `Γ_{body}` denotes the environment immediately upon entering the function body (body entry).

The initial region `ρᵢ` for each parameter is determined by declaration type-checking (elaboration), but this document explicitly adopts the following condition:

```text
(@ι = @nonisolated)  ∧  (Aᵢ : ~Sendable)  ⇒  ρᵢ = task
```

That is, in a `nonisolated` function body (sync or async), `~Sendable` parameters are treated as `task` region. The `task` region means "caller-owned and not bound to any specific actor." Even in the sync case, a function may be called from any isolation context, so statically assigning parameters to a specific actor is not safe. In an actor-isolated body (`@κ = @isolated(a)`), this condition does not apply. Note that this does not mean "mechanically rewriting `ρᵢ := isolated(a)` from `@κ` uniformly"; rather, it means that the initial region of parameters is determined when forming the entry environment `Γ_{body}`.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_paramBehavesLikeTaskRegion()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_ASYNC_PARAM_MAINACTOR_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolated_paramCapture_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolated_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_SYNC_PARAM_MAINACTOR_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `mainActor_paramCapture_isActorIsolated_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_mainActorParamSendAcrossActor_isError()` (`NEGATIVE_MAINACTOR_PARAM_SEND_ACROSS_ACTOR`)

Important: Type-checking the body under `@isolated(MainActor)` and updating `ρ` are separate layers. The initial value of `ρᵢ` is determined during `Γ_{body}` formation (elaboration), and the binding/refinement that occurs during expression evaluation (e.g., `disconnected → isolated(MainActor)`) is expressed by **bind/merge rules** such as [`region-merge`](#region-merge) and [`call-same-nonsendable-merge`](#call-same-nonsendable-merge).

Generalization: Not limited to `@MainActor`, the body capability `@κ` is determined from the function declaration's type annotation `@φ` (`= @σ @ι`) via `toCapability(proj_ι(@φ))`. The minimal template for a function declaration is:

```text
Γ_{body} = x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
@κ = toCapability(proj_ι(@φ))
Γ_{body}; @κ; α ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────────────────── (decl-fun)
Δ ⊢_d @φ func foo(x₁ : A₁, …, xₙ : Aₙ) α -> R { body }
```

Note: `α` in the conclusion corresponds in concrete syntax to the `async` keyword when `α = async`, and no keyword when `α = sync` (`func foo(...) -> R`).

(`decl-fun-mainactor-async` can be seen as an instance of `decl-fun` with `@φ = · @isolated(MainActor)` and `α = async` substituted. Since `toCapability(@isolated(MainActor)) = @isolated(MainActor)`, we get `@κ = @isolated(MainActor)`.)

#### decl-fun-isolated-param

This rule corresponds to SE-0313 (`isolated` parameters).

An `isolated` parameter is a mechanism that **grants a function the isolation of a concrete actor instance**. In an actor's instance methods, `self` is treated as an implicit `isolated` parameter (SE-0313).

**Constraint**: At most **one** `isolated` parameter is allowed per function (including the implicit `self`).

```text
a : ActorType    Γ_{body} = a : ActorType at _, x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
Γ_{body}; @isolated(a); α ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────────────────────── (decl-fun-isolated-param)
Δ ⊢_d func foo(actor: isolated ActorType, x₁ : A₁, …) α → R { body }
```

Reading: "A function with an `isolated ActorType` parameter checks its body under `@isolated(a)` (the isolation of that actor instance)."

This rule is a specialization of `decl-fun`, differing in that `@κ = @isolated(a)` is **derived from the `isolated` parameter**.

Note: An actor's instance method (`actor MyActor { func foo() { ... } }`) has an implicit `isolated self` parameter, so it can be viewed as an instance of [`decl-fun-isolated-param`](#decl-fun-isolated-param):

```text
self : MyActor    Γ_{body} = self : MyActor at _, ...
Γ_{body}; @isolated(self); sync ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────── (actor method ≡ decl-fun-isolated-param)
Δ ⊢_d func foo() -> R { body }    (within actor MyActor)
```

**Comparison between `isolated` parameter and `@isolated(any)`**:

| Aspect | `isolated ActorType` | `@isolated(any)` |
|------|---------------------|------------------|
| Actor identity | **Statically known** (type parameter `a`) | **Dynamic** (observed at runtime via `f.isolation`) |
| Sync call | ✅ No `await` needed (same isolation) | ❌ Always requires `await` (hop unknown) |
| Actor state access | ✅ Direct access possible | ❌ Not possible (identity unknown) |
| toRegion result | `toRegion(@isolated(a)) = isolated(a)` | `toRegion(@nonisolated) = disconnected` (`toCapability(@isolated(any)) = @nonisolated`) |
| Count per function | At most 1 | No restriction (type annotation) |
| Conversion lattice | `@isolated(a)` is an independent branch | `@isolated(any)` is within the lattice |

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_syncAccessInSameIsolation()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_crossIsolation_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_nonsendableArg_bindToActorRegion()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_actorSelfIsImplicitIsolated()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_isolatedParam_multipleIsolated_isError()` (`NEGATIVE_ISOLATED_PARAM_MULTIPLE`)

```swift
private actor LocalActor {
    var state: Int = 0
    func getState() -> Int { state }
    func useNonSendable(_ x: NonSendable) { x.value += state }
}

// Sync access via `isolated` parameter (no `await`)
func syncAccess(actor: isolated LocalActor) {
    _ = actor.state // ✅ direct access
}

// Cross-isolation requires `await`
@MainActor
func crossIsolation() async {
    let actor = LocalActor()
    _ = await actor.getState() // ✅ cross-isolation requires `await`
}

// NonSendable arg bound to actor's region
func bindArg(actor: isolated LocalActor) {
    let x = NonSendable()
    actor.useNonSendable(x) // ✅ same-isolation call
    _ = x.value // ✅ still accessible (bound, not consumed)
}

#if NEGATIVE_ISOLATED_PARAM_MULTIPLE
// ❌ error: cannot have more than one 'isolated' parameter
func multipleIsolated(a: isolated LocalActor, b: isolated LocalActor) {}
#endif
```

#### decl-fun-isolation-inheriting

This rule corresponds to SE-0420 (`#isolation` / caller isolation inheritance).

A function with an `isolated (any Actor)? = #isolation` parameter receives the caller's isolation **dynamically**. `#isolation` is a compile-time macro that expands to the caller's isolation context at the call site:

| Caller's `@κ` | `#isolation` expands to |
|---|---|
| `@isolated(MainActor)` | `MainActor.shared` |
| `@isolated(actor)` (instance) | `self` |
| `@nonisolated` | `nil` |
| Inheriting isolation (has `isolated` param) | That `isolated` parameter |

The callee body's capability is `@κ = @nonisolated`. For the same reason as `toCapability(@isolated(any)) = @nonisolated`, since it is statically unknown which actor will be used at runtime, the body is type-checked conservatively as nonisolated.

```text
Γ_{body} = iso : (any Actor)? at _, x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
Γ_{body}; @nonisolated; α ⊢ body : R at ρ  ⊣  Γ'_{body}
──────────────────────────────────────────────────────────────── (decl-fun-isolation-inheriting)
Δ ⊢_d func foo(isolation: isolated (any Actor)? = #isolation, x₁ : A₁, …) α → R { body }
```

**Differences from [`decl-fun-isolated-param`](#decl-fun-isolated-param)**:

| Aspect | `isolated ActorType` | `isolated (any Actor)? = #isolation` |
|------|---------------------|--------------------------------------|
| Actor identity | **Statically known** (concrete type `a`) | **Dynamic** (`nil` or any actor) |
| Body's `@κ` | `@isolated(a)` | `@nonisolated` (conservative) |
| Actor state access | ✅ Direct access possible | ❌ Not possible |
| Call-site benefit | Same-iso determined by `@κ = @ι` | **Always same-iso via `#isolation`** (see below) |

**Important**: The main benefit of `#isolation` is at the **call site**, not in the callee body. See the `#isolation` call semantics described later.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationInheriting_bodyIsNonisolated()`

```swift
// Body is type-checked as @nonisolated (cannot access specific actor state)
func isolationInheriting_bodyIsNonisolated<T>(
    _ f: () async throws -> T,
    isolation: isolated (any Actor)? = #isolation
) async rethrows -> T {
    // Cannot access any specific actor's state here
    // Body runs with @κ = @nonisolated
    return try await f()
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_isolationInheriting_bodyCannotAccessActorState()` (`NEGATIVE_ISOLATION_INHERITING_BODY_CANNOT_ACCESS_ACTOR_STATE`)

```swift
#if NEGATIVE_ISOLATION_INHERITING_BODY_CANNOT_ACCESS_ACTOR_STATE

// [decl-fun-isolation-inheriting] body is @nonisolated → cannot access @MainActor state
private func negative_isolationInheriting_bodyCannotAccessActorState(
    isolation: isolated (any Actor)? = #isolation
) async {
    // ❌ body is @nonisolated — cannot access specific actor state
    _ = mainActorConnectedVar.value
}

#endif
```

### 3.2 `Task { ... }` / `Task.detached { ... }` Body

A `Task` body is treated as `α=async` (where `await` can be written).

Additionally, in the Swift 6.2 standard library, the operation closure argument of `Task.init` / `Task.detached` is declared as **`sending`**. This captures in the type system the fact that the operation closure is transferred to a new task (a concurrent execution unit) and may run concurrently with the caller. If a `~Sendable` value could be captured while shared, the caller and the `Task` body could concurrently access the same value, making it impossible to statically eliminate data races. Since the closure value is transferred, its capture environment is transferred along with it. Therefore, capturing `~Sendable` values is only permitted when they are `disconnected`, and after the transfer they can no longer be referenced from the caller side as use-after-send (i.e., they are consumed). On the other hand, `Sendable` captures are safe to share and are not subject to consumption.

This is not a special case specific to `Task`; it is a rule that applies generally to **any closure passed to a `sending` parameter** (see [`closure-sending`](#closure-sending) below). `Task.init` / `Task.detached` are simply the most representative use cases.

```swift
// Simplified signature of Task.init:
// init(operation: sending @escaping @isolated(any) () async -> Success)
//                 ^^^^^^^
//                 The closure itself is `sending` → captures are also consumed

func taskBodiesAreAsyncExample() {
    let x = NonSendable() // disconnected

    Task {
        // body is `async` (can write `await`)
        _ = x.value  // ✅ can capture a disconnected NonSendable
    }

    // _ = x.value // ❌ error: `x` was captured as `sending` (consumed)
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_canCaptureDisconnectedNonSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskInit_useAfterSend_isError()` (`NEGATIVE_TASKINIT_USE_AFTER_SEND`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskDetached_canCaptureDisconnectedNonSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskDetached_useAfterSend_isError()` (`NEGATIVE_TASKDETACHED_USE_AFTER_SEND`)

---

## 4. Relation Rules

This section provides the relation-level rule family for the helper judgments `isoSubtyping` / `isoCoercion` defined in 2.9.
The rules given here do not involve terms; they define only the relationships between annotations.

- `isoSubtyping` is a semantic relation
- `isoCoercion` is a one-step contextual coercion judgment

This section provides the relation-level rules (`iso-subtyping-*`, `iso-subtyping-to-coercion`, `iso-coercion-*`).
Term-level typing rules (in particular `func-conv`, `isolated-any-to-async`, `sync-to-async`) are given in [Function Type Conversion](#53-function-type-conversion).

### 4.1 Isolation Subtyping

#### iso-subtyping-identity

```text
───────────────────────────────────────── (iso-subtyping-identity)
isoSubtyping(@σ, ι, @σ, ι, α')
```

Any function type can be converted to the same annotation (identity conversion).

#### iso-subtyping-sendable-forget

```text
───────────────────────────────────────── (iso-subtyping-sendable-forget)
isoSubtyping(@Sendable, ι, ·, ι, α')
```

`@Sendable` can be safely forgotten (relaxation of constraints). The reverse direction (`·` → `@Sendable`) is not permitted.

#### iso-subtyping-nonisolated-to-isolated-any

```text
───────────────────────────────────────── (iso-subtyping-nonisolated-to-isolated-any)
isoSubtyping(@σ, @nonisolated, @σ, @isolated(any), α')
```

`nonisolated` can be promoted to `@isolated(any)`. Since `@isolated(any)` is an existential that dynamically holds any isolation, `nonisolated` is subsumed as a special case thereof.

#### iso-subtyping-mainactor-to-isolated-any

```text
───────────────────────────────────────── (iso-subtyping-mainactor-to-isolated-any)
isoSubtyping(@σ, @MainActor, @σ, @isolated(any), α')
```

`@MainActor` is a concrete actor isolation, and `@isolated(any)` is its existential supertype.

#### iso-subtyping-mainactor-implicit-sendable

```text
───────────────────────────────────────── (iso-subtyping-mainactor-implicit-sendable)
isoSubtyping(·, @MainActor, @Sendable, @MainActor, α')
```

`@MainActor` is implicitly `@Sendable` (SE-0434). Because a global actor is unique and calls across isolation boundaries are always safe, this property may be placed on the subtyping side.

Note: SE-0434 guarantees this property for any global actor (not limited to `@MainActor`). This document uses `@MainActor` as a representative example.

#### `@isolated(localActor)` special branch

`isolated LocalActor` is a special function type that carries an actor parameter (`(isolated LocalActor) → Void`), and is therefore treated as a separate branch from the ordinary form.

```text
───────────────────────────────────────── (iso-subtyping-isolated-local-actor-identity)
isoSubtyping(@σ, @isolated(localActor), @σ, @isolated(localActor), α')
```

```text
───────────────────────────────────────── (iso-subtyping-isolated-local-actor-sendable-forget)
isoSubtyping(@Sendable, @isolated(localActor), ·, @isolated(localActor), α')
```

For the `@isolated(localActor)` branch, only identity and sendable-forget are adopted as subtype rules. Other conversions are structurally different (actor parameter) and are not subtyping; they are handled on the closure-wrapping side if needed.

#### iso-subtyping-transitive

```text
isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')
isoSubtyping(@σ₂, ι₂, @σ₃, ι₃, α')
───────────────────────────────────────── (iso-subtyping-transitive)
isoSubtyping(@σ₁, ι₁, @σ₃, ι₃, α')
```

`isoSubtyping` is transitive. Multiple primitive edges on the subtyping side can thereafter be composed via this rule.

#### iso-subtyping-to-coercion

```text
isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')
───────────────────────────────────────── (iso-subtyping-to-coercion)
isoCoercion(@σ₁, ι₁, @σ₂, ι₂, α')
```

Any subtype edge can also be used directly as a one-step direct coercion edge.

### 4.2 Isolation Coercion

#### iso-coercion-isolated-any-to-nonisolated-deprecated

```text
───────────────────────────────────────── (iso-coercion-isolated-any-to-nonisolated-deprecated)
isoCoercion(@σ, @isolated(any), @σ, @nonisolated, sync)
```

`@isolated(any) sync → @nonisolated sync` is a legacy coercion edge that Swift 6.2 still accepts with a warning. This is not a recommended edge in the stable lattice; it is retained solely as a compatibility layer that is expected to become an error in the future.

#### iso-coercion-sendable-nonisolated-universal

```text
ι₂ ≠ @isolated(localActor)
───────────────────────────────────────── (iso-coercion-sendable-nonisolated-universal)
isoCoercion(@Sendable, @nonisolated, @σ₂, ι₂, α')
```

`@Sendable @nonisolated` is the most constrained source and can be directly coerced to any target except the local-actor-parameter branch (`isolated LocalActor`). `@Sendable` guarantees safe transmission across any isolation boundary, and `@nonisolated` means the closure is not bound to a specific actor.

Note: The only exclusion here is the `@isolated(localActor)` branch, which fixes a local actor instance; `@MainActor`, being a global actor, is included.

#### iso-coercion-async-mainactor-universal

```text
ι₂ ≠ @isolated(localActor)
───────────────────────────────────────── (iso-coercion-async-mainactor-universal)
isoCoercion(@σ, @MainActor, @σ₂, ι₂, async)
```

In the async world, `@MainActor` can be directly coerced to any target except the local-actor-parameter branch (`isolated LocalActor`). This is because `@MainActor` is implicitly `@Sendable` (SE-0434), and in async contexts, runtime actor hopping allows reaching any isolation domain.

Note: The only exclusion here is also the `@isolated(localActor)` branch, which fixes a local actor instance; this is not a statement about other global actors.

#### iso-coercion-async-nonsendable-equiv

```text
ι₁ ∈ {@nonisolated, @concurrent, @isolated(any)}
ι₂ ∈ {@nonisolated, @concurrent, @isolated(any)}
───────────────────────────────────────── (iso-coercion-async-nonsendable-equiv)
isoCoercion(·, ι₁, ·, ι₂, async)
```

In the async world, non-`@Sendable` `nonisolated`, `@concurrent`, and `@isolated(any)` are mutually convertible (bidirectional). This is because async functions can execute in any isolation context through runtime actor hopping.

#### Conversion Matrix

The table below cross-references the **combined system** of `isoSubtyping` + `iso-subtyping-to-coercion` + `isoCoercion`-specific rules against the experimental results in `FuncConversionRules.swift`. The 🔧 mark indicates cases outside the scope of relation-level rules, where term-level closure wrapping is required.

**Sync conversion matrix** (`α' = sync`, direct coercion only):

| Source ↓ \ Target → | N | S | M | MS | IA | IAS | IL | ILS |
|---|---|---|---|---|---|---|---|---|
| N (`· @nonisolated`) | ✅ id | ❌ | ❌ | ❌ | ✅ ni→ia | ❌ | ❌ | ❌ |
| S (`@Sendable @nonisolated`) | ✅ uni | ✅ uni | ✅ uni | ✅ uni | ✅ uni | ✅ uni | 🔧 | 🔧 |
| M (`· @MainActor`) | ❌ | ❌ | ✅ id | ✅ ma-s | ✅ ma→ia | ✅ ma-s,ma→ia | ❌ | ❌ |
| MS (`@Sendable @MainActor`) | ❌ | ❌ | ✅ sf | ✅ id | ✅ sf,ma→ia | ✅ ma→ia | ❌ | ❌ |
| IA (`· @isolated(any)`) | ⚠️ dep | ❌ | ❌ | ❌ | ✅ id | ❌ | ❌ | ❌ |
| IAS (`@Sendable @isolated(any)`) | ⚠️ sf,dep | ⚠️ dep | ❌ | ❌ | ✅ sf | ✅ id | ❌ | ❌ |
| IL (`· @isolated(localActor)`) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ id | ❌ |
| ILS (`@Sendable @isolated(localActor)`) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ sf | ✅ id |

Abbreviations: id = iso-subtyping-identity, sf = iso-subtyping-sendable-forget, ni→ia = iso-subtyping-nonisolated-to-isolated-any, uni = iso-coercion-sendable-nonisolated-universal, ma-s = iso-subtyping-mainactor-implicit-sendable, ma→ia = iso-subtyping-mainactor-to-isolated-any, dep = iso-coercion-isolated-any-to-nonisolated-deprecated, 🔧 = closure wrapping required

**Async conversion matrix** (`α' = async`, direct coercion only):

| Source ↓ \ Target → | N | S | M | MS | C | CS | IA | IAS | IL | ILS |
|---|---|---|---|---|---|---|---|---|---|---|
| N (`· @nonisolated`) | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| S (`@Sendable @nonisolated`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔧 | 🔧 |
| M (`· @MainActor`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔧 | 🔧 |
| MS (`@Sendable @MainActor`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔧 | 🔧 |
| C (`· @concurrent`) | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| CS (`@Sendable @concurrent`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🔧 | 🔧 |
| IA (`· @isolated(any)`) | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| IAS (`@Sendable @isolated(any)`) | ✅ | ✅ | 🔧 | 🔧 | ✅ | ✅ | ✅ | ✅ | 🔧 | 🔧 |
| IL (`· @isolated(localActor)`) | 🔧 | ❌ | ❌ | ❌ | 🔧 | ❌ | 🔧 | ❌ | ✅ id | ❌ |
| ILS (`@Sendable @isolated(localActor)`) | 🔧 | 🔧 | 🔧 | 🔧 | 🔧 | 🔧 | 🔧 | 🔧 | ✅ sf | ✅ id |

Characteristics of the async matrix:
- Row M, MS: `iso-coercion-async-mainactor-universal` enables direct coercion to all targets except IL/ILS
- Row N, C, IA: `iso-coercion-async-nonsendable-equiv` allows bidirectional conversion within {N, C, IA}
- Row S, CS: `iso-coercion-sendable-nonisolated-universal` enables direct coercion to all targets except IL/ILS
- Row IAS: cannot reach M/MS via direct coercion (term-level closure wrapping `{ await f() }` is required)
- Row IL, ILS: only identity/sendable-forget via direct coercion; all others require closure wrapping (capture of the actor instance is required)

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest_MainActor`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest_MainActor`

#### Conversion Diagram

For a directed graph representation of the conversion matrix, see [`docs/diagrams/func-conversion-rules.mmd`](diagrams/func-conversion-rules.mmd) (Mermaid). Render with `make diagrams`.

#### Group Analysis

Conversion patterns can be broadly classified into three categories:

1. **Non-Sendable Lattice**: `nonisolated`, `@concurrent` (async only), `@isolated(any)`
   - Bidirectional conversions within the group
   - Cannot convert to Sendable types
   - Cannot reach `isolated LocalActor`

2. **Sendable Group**: `@Sendable`, `@MainActor`, `@concurrent @Sendable`, `@isolated(any) @Sendable`
   - Can convert to any Non-Sendable type (forgetting @Sendable)
   - Largely interchangeable within the group (bidirectional)
   - Can reach `isolated LocalActor` and `isolated LocalActor @Sendable` (one-way)
   - Note: `isolated LocalActor @Sendable` is a sink, not interchangeable with others

3. **`isolated LocalActor` (Isolated Sink)**:
   - **Sync**: Completely isolated — only reachable from `@Sendable`
   - **Async**: Only reachable from the Sendable Group; cannot convert to other types
   - **`isolated LocalActor @Sendable async`**: Not equivalent to other Sendable types (one-way only)

Why `isolated LocalActor` is special:
- Tied to a specific **actor instance** (not a global actor like `@MainActor`)
- Has an **actor parameter**: `(isolated LocalActor) async -> Void` vs `() async -> Void`
- In sync context: cannot be called from other isolation domains
- In async context: cannot convert to 0-ary functions because the actor parameter cannot be provided

## 5. Typing Rules

Note: The ` ```swift` fragments below are primarily excerpted from functions in `swift/Sources/concurrency-type-check/TypingRules.swift` (auxiliary types such as `NonSendable` are also defined in the same file).

### 5.1 Variables

#### var

The basic rule for variable references: if the binding in the environment is accessible from the current capability, the variable can be read at the same region.

```text
x : T at ρ ∈ Γ
ρ ∈ accessible(@κ)
────────────────────────────────── (var)
Γ; @κ; α ⊢ x : T at ρ  ⊣  Γ
```

This rule only determines accessibility. The `Sendable` / `~Sendable` branching is not handled within the rule itself but is delegated to the canonical-form condition `T : Sendable ⇔ (ρ = _)`.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `varSendable_accessibleFromAnyCapability()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `varConnected_mainActor_canAccessConnectedVar()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_varConnected_nonisolatedCannotAccessMainActorVar_isError()` (`NEGATIVE_VAR_CONNECTED_MAINACTOR_ACCESS`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `varDisconnected_nonSendableClosuresCanCaptureDisconnected()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_noInherit_sendableCannotCaptureNonSendable_isError()` (`NEGATIVE_VAR_DISCONNECTED_SENDABLE_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `mainActor_readDoesNotPreventSendingFromDisconnected()`

For `Sendable` values (`ρ = _`), since `accessible(@κ)` always contains `_`, the variable can be referenced from any capability:

```swift
let s = MySendable() // `@unchecked Sendable` class (definition: experiment file)

let f0: () -> MySendable = { s }
let f1: @MainActor () -> MySendable = { s }
let f2: @isolated(any) () -> MySendable = { s }
let f3: @Sendable () -> MySendable = { s }

_ = (f0(), f1, f2, f3)
_ = s // not consumed
```

For `~Sendable` values, `ρ ∈ ρ_{ns}` holds, and `ρ ∈ accessible(@κ)` becomes the direct accessibility condition. Since `accessible(@κ)` always includes `disconnected`, a `disconnected` value is accessible from any `@κ`. Referencing a `disconnected` variable itself does not cause binding (binding occurs in [`region-merge`](#region-merge) or [`call-same-nonsendable-merge`](#call-same-nonsendable-merge)).

```swift
@MainActor
var g = NonSendable() // g : NonSendable at isolated(MainActor)

@MainActor
func ok() { _ = g.value } // ✅ isolated(MainActor) ∈ accessible(@isolated(MainActor))

func ng() {
    // _ = g.value // ❌ error: isolated(MainActor) ∉ accessible(@nonisolated)
}
```

```swift
func disconnectedExample() async {
    let x = NonSendable() // disconnected
    _ = x.value // ✅ disconnected ∈ accessible(@κ) for all @κ

    let _: () -> Void = { _ = x.value } // ✅ capture into non-Sendable closure is OK
    let _: @MainActor () -> Void = { _ = x.value } // ✅ (still disconnected)
    let _: @isolated(any) () -> Void = { _ = x.value } // ✅ (still disconnected)

    // let _: @Sendable () -> Void = { _ = x.value } // ❌ error: @Sendable closure cannot capture NonSendable

    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ still disconnected, then consumed by `sending`
}
```

### 5.2 Sequencing

#### seq

The rule for sequential execution `e₁; e₂`: the output environment of `e₁` is passed as-is to the input environment of `e₂`.

```text
Γ;  @κ; α ⊢ e₁ : () at ρ₁  ⊣  Γ₁
Γ₁; @κ; α ⊢ e₂ : T  at ρ₂  ⊣  Γ₂
──────────────────────────────────── (seq)
Γ;  @κ; α ⊢ e₁; e₂ : T at ρ₂  ⊣  Γ₂
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `seq_asyncThenSync_compiles()`

```swift
@MainActor
func seqExample() async {
    let other = SendableActor()
    let x = MySendable()

    _ = await other.echoAsync(x) // async expression
    _ = x.value // then sync expression
}
```

### 5.3 Function Type Conversion

This section defines **term-level typing rules** using the helper relations `isoSubtyping` / `isoCoercion`:
- `sync-to-async`: sync → async promotion
- `func-conv`: a typing rule that converts function type annotations using `isoCoercion`
- `isolated-any-to-async`: async isolation erasure of `@isolated(any) sync`

These three term-level typing rules are mutually orthogonal and composable. For example, after `func-conv`, `sync-to-async` can promote the result to async.

#### sync-to-async

A rule that makes explicit Swift's basic subtyping: a sync function type can be promoted to an async function type.

```text
Γ; @κ; α ⊢ f : @φ () → B  at ρ_f  ⊣  Γ'
────────────────────────────────────────────────────── (sync-to-async)
Γ; @κ; α ⊢ f : @φ () async → B  at ρ_f  ⊣  Γ'
```

A sync function type can always be promoted to an async function type (`() → B  <:  () async → B`). This is Swift's general subtyping, which allows assigning a sync function to an async variable or passing a sync function to an async parameter.

```swift
let f: () -> Void = { }
let g: () async -> Void = f  // ✅ sync → async lift
```

This rule also serves as the foundation for cross-isolation calls and the implicit async promotion of `@isolated(any)`.

#### func-conv

The rule for converting the isolation annotation of a function type. Uses [`isoCoercion`](#29-isolation-subtyping--coercion-isosubtyping-isocoercion) as a premise.

```text
Γ; @κ; α ⊢ f : @σ₁ @ι₁ (A) α' → B  at ρ_f  ⊣  Γ'
isoCoercion(@σ₁, @ι₁, @σ₂, @ι₂, α')
ρ' = (if @σ₂ = @Sendable then _ else ρ_f)
──────────────────────────────────────────────────────── (func-conv)
Γ; @κ; α ⊢ f : @σ₂ @ι₂ (A) α' → B  at ρ'  ⊣  Γ'
```

Key points:
- This rule converts the **isolation annotation** of the function type. The ambient `@κ` is not changed.
- `isoCoercion` is a one-step contextual coercion judgment. A multi-step chain is not expressed by a single application of this rule.
- Region `ρ'`: if the target is `@Sendable`, it is normalized to `_` (the Sendable region). This is because acquiring `@Sendable` makes the function region-free.
- The argument type `A` and return type `B` are not changed.
- `α'` is the async mode of the function itself, distinct from the ambient `α`.
- Orthogonal to `sync-to-async`: `func-conv` converts isolation, while `sync-to-async` converts `α'`.

```swift
// @Sendable → @MainActor @Sendable (func-conv: iso-coercion-sendable-nonisolated-universal)
let f: @Sendable () -> Void = { }
let g: @MainActor @Sendable () -> Void = f  // ✅

// @MainActor → @isolated(any) (func-conv: iso-subtyping-mainactor-to-isolated-any + iso-subtyping-to-coercion)
let h: @MainActor () -> Void = { }
let i: @isolated(any) () -> Void = h  // ✅

// async non-Sendable equivalence (func-conv: iso-coercion-async-nonsendable-equiv)
let j: () async -> Void = { }
let k: @concurrent () async -> Void = j  // ✅
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest_MainActor`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest_MainActor`

#### isolated-any-to-async

The rule for converting an `@isolated(any) sync` function type to an async function type by erasing the isolation (SE-0431).

```text
Γ; @κ; α ⊢ f : @σ @isolated(any) () → B  at ρ_f  ⊣  Γ'
¬isActorIsolated(@ι₂)
ρ' = (if @σ = @Sendable then _ else ρ_f)
──────────────────────────────────────────────────────── (isolated-any-to-async)
Γ; @κ; α ⊢ f : @σ @ι₂ () async → B  at ρ'  ⊣  Γ'
```

Key points:
- **Source is sync, target is async**: isolation erasure and sync→async lift are performed in one step.
- **`¬isActorIsolated(@ι₂)`**: the target must not be a specific actor (such as `@MainActor`). This is because static guarantees to a specific actor cannot be derived from dynamic isolation information.
- **At the type level, isolation information is lost**: the `.isolation` property becomes inaccessible.
- **At runtime, the original dynamic isolation is preserved**: the closure executes on the original actor.

Targets satisfying `¬isActorIsolated(@ι₂)`:
- `@nonisolated` (`() async → Void`): ✅
- `@Sendable @nonisolated` (`@Sendable () async → Void`): ✅ (when `@σ` is `@Sendable`)
- `@concurrent` (`@concurrent () async → Void`): ✅
- `@isolated(any)` (`@isolated(any) () async → Void`): ✅
- `@MainActor` (`@MainActor () async → Void`): ❌ (`isActorIsolated(@MainActor) = true`)

```swift
// ✅ @isolated(any) sync → nonisolated async (isolation erasure)
func convert(_ f: @escaping @isolated(any) () -> Void) -> () async -> Void {
    f  // Direct coercion: type-level isolation erased, runtime isolation preserved
}

// ❌ @isolated(any) sync → @MainActor async (specific actor target not allowed)
// func convert(_ f: @escaping @isolated(any) () -> Void) -> @MainActor () async -> Void {
//     f  // ERROR
// }
```

Why this rule cannot be derived from the composition of `func-conv` + `sync-to-async`: the conversion `@isolated(any) sync → @nonisolated sync` is deprecated (and will become an error in the future), so the path of using `func-conv` to convert the isolation and then `sync-to-async` to promote to async is unavailable. SE-0431 provides a special conversion that performs isolation erasure and async lift simultaneously to work around this constraint.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncIsolatedAnyToAsyncConversionTest`

#### Subtyping / Coercion Verification Table

For the Sync / Async conversion matrix, refer to [Conversion Matrix](#conversion-matrix) (the combined system of `isoSubtyping` + `iso-subtyping-to-coercion` + `isoCoercion`-specific rules).

Notes:
- Cells marked 🔧 are not subject to `isoCoercion` (one-step direct coercion) and require term-level closure wrapping.
- Cells listing multiple abbreviations represent an **explanation chain** in the combined system. This does not claim that `isoCoercion` itself is transitive.

#### Conversion via Closure Wrapping

The following conversions compile in `FuncConversionRules.swift`, but involve closure wrapping (generation of a new closure) rather than a direct coercion (`f`). They are not subject to `isoCoercion` / `func-conv`, and should be understood in combination with closure rules such as [`closure-inherit-parent`](#closure-inherit-parent) or [`closure-no-inherit-parent`](#closure-no-inherit-parent).

**`isolated LocalActor`-related** (involving arity change):

```swift
// @Sendable → isolated LocalActor (sync): closure wrapping to add an actor parameter
func convert(_ f: @escaping @Sendable () -> Void) -> (isolated LocalActor) -> Void {
    { _ in f() }  // 🔧 generates a new closure
}

// isolated LocalActor @Sendable async → nonisolated async: pass captured actor
func convert(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> () async -> Void {
    let actor = LocalActor()
    return { await f(actor) }  // 🔧 generates a new closure + await
}

// @MainActor async → isolated LocalActor async: closure wrapping + await
func convert(_ f: @escaping @MainActor () async -> Void) -> (isolated LocalActor) async -> Void {
    { _ in await f() }  // 🔧 generates a new closure + await
}
```

**`@isolated(any) @Sendable async → @MainActor async`** (direct coercion not possible):

```swift
// IAS → M: direct coercion `f` is an error; explicit closure wrapping required
func convert(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @MainActor () async -> Void {
    // f  // ❌ ERROR: direct coercion
    { await f() }  // 🔧 generates a new closure + await
}
```

Why these conversions are not direct coercions:
- **Arity change**: `isolated LocalActor` takes an actor parameter, so the type structure differs from 0-ary functions.
- **`await` required**: cross-isolation calls involve suspension, so simple type coercion cannot express this.
- **Static guarantee of dynamic isolation not possible**: a direct coercion from `@isolated(any) @Sendable` to `@MainActor` is not possible because the dynamic isolation cannot be statically guaranteed to be `@MainActor`.

### 5.4 Region Merge (Aliasing / Assignment)

#### region-merge

The rule that joins two NonSendable regions via assignment or aliasing, updating the region information in the environment consistently.

```text
Γ;  @κ; α ⊢ e₁ : T₁ at ρ₁  ⊣  Γ₁
Γ₁; @κ; α ⊢ e₂ : T₂ at ρ₂  ⊣  Γ₂
T₁ : ~Sendable    T₂ : ~Sendable
ρ₁, ρ₂ ∈ ρ_{ns}
ρ = ρ₁ ⊔ ρ₂
───────────────────────────────────────────────────────────────── (region-merge)
Γ;  @κ; α ⊢ (e₁.field = e₂) : () at _  ⊣  Γ₂[ρ₁ ↦ ρ, ρ₂ ↦ ρ]
```

Key points:
- Assignment is expressed as **context refinement** (environment update) rather than **consumption**.
- [`region-merge`](#region-merge) applies only to the joining of two NonSendable values (the domain of `⊔` is `ρ_{ns}`).
- `Sendable` values are always held `at _` by the canonical-form condition and are not subject to merging.
- `()` is `Sendable` and thus normalizes to `at _` (the factual information is carried only by `Γ₂[...]`).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `regionMerge_storeIntoMainActorField_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_regionMerge_storeThenSend_isError()` (`NEGATIVE_REGION_MERGE_STORE_THEN_SEND`)

```swift
@MainActor
func regionMergeExample() async {
    let x = NonSendable()

    mainActorHolder.field = x // merges/binds into @MainActor region
    _ = mainActorHolder.field?.value

    let other = OtherActor()
    // await other.useNonSendableSending(x) // ❌ error: `x` is no longer disconnected (negative test)
}
```

### 5.5 Function Calls

All call rules in this document propagate the output context in the following order:

1. Type-check `f` to obtain `Γ₁`
2. Type-check `arg` to obtain `Γ₂`
3. Apply boundary crossing / transfer / binding to obtain `Γ₃`

The `call-*` rule name prefix should be read by the following family first:

| Family | Condition | Meaning | Rules in this section |
|---|---|---|---|
| `call-nonsendable-*` | `canSend` holds | Consumption judgment for `~Sendable` values (unified rule) | [`call-nonsendable-noconsume`](#call-nonsendable-noconsume), [`call-nonsendable-consume`](#call-nonsendable-consume) |
| `call-same-*` | `@κ = @ι` | Same-isolation call (no boundary crossing) | [`call-same-sync-sendable`](#call-same-sync-sendable), [`call-same-async-sendable`](#call-same-async-sendable), [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) |
| `call-cross-*` | `@κ ≠ @ι`, `@ι ∉ { @concurrent }` (though [`call-cross-sendable`](#call-cross-sendable) additionally requires `@ι ≠ @nonisolated`) | Cross-boundary calls | [`call-cross-sendable`](#call-cross-sendable), [`call-cross-sending-result`](#call-cross-sending-result), [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error) |
| `call-concurrent-*` | `@ι = @concurrent` | Explicit nonisolated async calls (dedicated semantics) | [`call-concurrent-sendable`](#call-concurrent-sendable), [`call-concurrent-nonsendable`](#call-concurrent-nonsendable) |
| [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) | `@ι = @nonisolated`, `async` | Caller isolation inheritance per SE-0461 | [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) |
| [`call-nonisolated-sync`](#call-nonisolated-sync) | `@ι = @nonisolated`, `sync`, `@κ ≠ @nonisolated` | nonisolated sync executes on caller's executor (no boundary) | [`call-nonisolated-sync`](#call-nonisolated-sync) |

#### call-nonsendable-noconsume

The rule where a `~Sendable` value is the target of a send (either an explicit `sending` parameter or an implicit cross-isolation transfer), but since the caller and callee **share the same concrete actor isolation**, the value is not consumed and **the original region is preserved**.

```text
Γ;  @κ; α ⊢ f   : @σ @ι ([sending] A) α' → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A at ρ_a                               ⊣  Γ₂
A : ~Sendable    B : Sendable    @ι ∉ { @concurrent }
canSend(@κ, @ι, [sending])
ρ_a ∈ accessible(@κ)
isActorIsolated(@κ)    @κ = @ι
────────────────────────────────────────────────────────────── (call-nonsendable-noconsume)
Γ;  @κ; α ⊢ [await] f(arg) : B at _  ⊣  Γ₂
```

`[sending]` indicates that `sending` may or may not be present (see [`canSend`](#cansend) for the definition). `[await]` is added when `α' = async`.

With the same concrete actor isolation (e.g., both `@MainActor`), the serial executor ensures that the caller and callee cannot execute simultaneously, so even a `sending`-annotated parameter does not consume the value — the value is kept in the caller's environment (`Γ₂`, not `Γ₂ \ {arg}`). The key point here is that **what is preserved is always the original region `ρ_a`, not necessarily `disconnected`**. Therefore, if a `disconnected` value is passed to a same-isolation `sending` call, it remains `disconnected`; if a value already bound to an actor is passed, it remains in that actor-bound region.

##### Example of noconsume: same concrete actor + sending

An application of [`call-nonsendable-noconsume`](#call-nonsendable-noconsume). When passing to a `sending` parameter between two `@MainActor` contexts, `isActorIsolated(@MainActor) ∧ @MainActor = @MainActor` holds and consumption is waived.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_actorBound_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_thenUse_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_thenCrossSend_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_twice_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoAsyncSending_compiles()`

```swift
@MainActor
func sameIsolationSendingExample() async {
    let x = NonSendable() // disconnected
    mainActorUseNonSendableSending(x) // ✅ does not consume (same isolation, sync)
    mainActorUseNonSendableSending(x) // ✅ can pass again (still disconnected)
    _ = x.value                       // ✅ still usable

    await mainActorUseNonSendableSendingAsync(x) // ✅ does not consume (same isolation, async)
    _ = x.value                                   // ✅ still usable

    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ still disconnected → now consumed (cross isolation)
    // _ = x.value                       // ❌ error: use-after-send
}

@MainActor
func sameIsolationSending_preservesActorBoundRegion() {
    let y = mainActorConnectedVar // y : NonSendable at isolated(MainActor)
    mainActorUseNonSendableSending(y)
    _ = y.value // ✅ still MainActor-isolated, not consumed
}
```

##### noconsume vs consume (Same vs Cross)

Contrast between [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) and [`call-nonsendable-consume`](#call-nonsendable-consume). Within the same isolation, the caller and callee cannot execute simultaneously, so even `sending` parameters preserve the value.

```swift
// Same isolation: noconsume
@MainActor func example_sameIsolation_sending() async {
    let x = NonSendable()              // disconnected
    mainActorUseNonSendableSending(x)  // [call-nonsendable-noconsume] ⊣ Γ₂
    mainActorUseNonSendableSending(x)  // [call-nonsendable-noconsume] ✅ can pass again
    _ = x.value                        // ✅ still usable
}

// Cross isolation: consume
@MainActor func example_crossIsolation_sending() async {
    let x = NonSendable()              // disconnected
    let other = OtherActor()
    await other.useNonSendableSending(x) // [call-nonsendable-consume] ⊣ Γ₂ \ {x}
    // _ = x.value                       // ❌ error: use-after-send
}
```

| | noconsume | consume |
|---|---|---|
| Rule | [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) | [`call-nonsendable-consume`](#call-nonsendable-consume) |
| Condition | `isActorIsolated(@κ) ∧ @κ = @ι` | otherwise |
| Output environment | `Γ₂` | `Γ₂ \ {arg}` |
| Use after passing | ✅ possible | ❌ use-after-send |

##### Difference from `call-same-nonsendable-merge` (bind vs no-bind)

A regular (non-`sending`) parameter binds/refines the region, causing the value to no longer be `disconnected`, whereas a `sending` parameter causes no binding and **preserves the original region**.

```swift
// Non-sending: binding occurs → loses disconnected
@MainActor func example_nonSending() async {
    let x = NonSendable()        // disconnected
    mainActorUseNonSendable(x)   // [call-same-nonsendable-merge] bind: x → isolated(MainActor)
    _ = x.value                  // ✅ still accessible (not consumed)

    let other = OtherActor()
    await other.useNonSendableSending(x) // ❌ [call-nonsendable-consume] x is no longer disconnected!
}

// Sending: no binding → remains disconnected
@MainActor func example_sending() async {
    let x = NonSendable()              // disconnected
    mainActorUseNonSendableSending(x)  // [call-nonsendable-noconsume] no bind: x stays disconnected
    _ = x.value                        // ✅ still accessible

    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ [call-nonsendable-consume] still disconnected → can send
}

// Sending: actor-bound input stays actor-bound
@MainActor func example_sending_actorBound() async {
    let y = mainActorConnectedVar      // isolated(MainActor)
    mainActorUseNonSendableSending(y)  // [call-nonsendable-noconsume] region preserved
    _ = y.value                        // ✅ still accessible on @MainActor
}
```

| | non-`sending` (`call-same-nonsendable-merge`) | `sending` (`call-nonsendable-noconsume`) |
|---|---|---|
| Consumption | none | none |
| Region effect | **bind** → refined to `ρ_a'` | **no bind** → original `ρ_a` preserved |
| Cross-actor send after passing | ❌ (because bound) | ✅ if `ρ_a = disconnected`, ❌ if actor-bound |

#### call-nonsendable-consume

The rule that affinely consumes a `~Sendable` value when it is the target of a send and the caller and callee do **not** share the same concrete actor isolation.

```text
Γ;  @κ; α ⊢ f   : @σ @ι ([sending] A) α' → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A at disconnected                      ⊣  Γ₂
A : ~Sendable    B : Sendable    @ι ∉ { @concurrent }
canSend(@κ, @ι, [sending])
¬(isActorIsolated(@κ) ∧ @κ = @ι)
────────────────────────────────────────────────────────────── (call-nonsendable-consume)
Γ;  @κ; α ⊢ [await] f(arg) : B at _  ⊣  (Γ₂ \ {arg})
```

`[await]` is added when `α' = async`.

##### Correspondence with the Compiler

These two rules directly correspond to a single `if` branch in the compiler implementation (`PartitionUtils.h` `PartitionOpKind::Send`):

```cpp
// PartitionUtils.h — Send evaluation (simplified)
if (calleeIsolationInfo.isActorIsolated() &&
    sentRegionIsolation.hasSameIsolation(calleeIsolationInfo))
  return;                    // call-nonsendable-noconsume → Γ₂
p.markSent(op, ptrSet);     // call-nonsendable-consume   → Γ₂ \ {arg}
```

##### Example of consume: nonisolated + sending

An application of [`call-nonsendable-consume`](#call-nonsendable-consume). Since `@nonisolated` does not satisfy `isActorIsolated`, consumption occurs regardless of the caller's isolation.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_nonisolatedSyncSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_nonisolatedSyncSending_fromMainActor_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_consume_nonisolatedSyncSending_useAfter_isError()` (`NEGATIVE_NONISOLATED_SYNC_SENDING_USE_AFTER`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_consume_nonisolatedSyncSending_twice_isError()` (`NEGATIVE_NONISOLATED_SYNC_SENDING_TWICE`)

```swift
// @nonisolated sync `sending` — always consumes
func nonisolatedSyncUseSending(_ x: sending NonSendable) {
    _ = x.value
}

// nonisolated caller → nonisolated sync `sending`
func nonisolatedSyncSendingExample() {
    let x = NonSendable() // disconnected
    nonisolatedSyncUseSending(x) // ✅ compiles — x is consumed
    // _ = x.value                // ❌ error: sending 'x' risks causing data races
    // nonisolatedSyncUseSending(x) // ❌ error: same reason
}

// @MainActor caller → nonisolated sync `sending` (no await needed for sync)
@MainActor
func mainActorToNonisolatedSyncSendingExample() {
    let x = NonSendable() // disconnected
    nonisolatedSyncUseSending(x) // ✅ compiles — x is consumed (sync cross-isolation)
}
```

The difference between noconsume and consume reduces to whether the precondition `isActorIsolated(@κ) ∧ @κ = @ι` of [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume) holds.

##### Example of consume: cross-isolation implicit sending

An application of [`call-nonsendable-consume`](#call-nonsendable-consume). When passing a `~Sendable` value to a different isolation, even without explicit `sending`, the implicit transfer condition of `canSend` (`@κ ≠ @ι`) holds and consumption occurs.

Note: The premise `B : Sendable` is a constraint on the result type. If `B : ~Sendable`, a **compile error** results via [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error). To return a `~Sendable` result cross-isolation, an explicit `sending` annotation is required ([`call-cross-sending-result`](#call-cross-sending-result)).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_crossIsoImplicit_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_consume_crossIsoImplicit_useAfter_isError()` (`NEGATIVE_USE_AFTER_IMPLICIT_TRANSFER`)

```swift
@MainActor
func crossActorImplicitTransferExample() async {
    let x = NonSendable() // disconnected
    let other = OtherActor()

    await other.useNonSendable(x) // ✅ implicit transfer consumes `x`

    // _ = x.value // ❌ error: use-after-send (negative test)
}
```

##### Example of consume: cross-isolation explicit sending

An application of [`call-nonsendable-consume`](#call-nonsendable-consume). Explicit passing to a `sending` parameter satisfies `canSend`, and since `@κ ≠ @ι`, consumption occurs. This also applies to `sending` calls where `@ι = @nonisolated` (e.g., passing from an actor-isolated caller to `@nonisolated async (sending ...)`).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_crossIsoExplicitSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_sendingParam_compilesAndConsumes()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_consume_crossIsoExplicitSending_useAfter_isError()` (`NEGATIVE_USE_AFTER_EXPLICIT_SENDING`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_useAfterSendingParam_isError()` (`NEGATIVE_NONISOLATED_ASYNC_USE_AFTER_SENDING`)

```swift
@MainActor
func crossActorExplicitSendingExample() async {
    let x = NonSendable() // disconnected
    let other = OtherActor()

    await other.useNonSendableSending(x) // ✅ explicit `sending` consumes `x`

    // _ = x.value // ❌ error: use-after-consume (negative test)
}
```

#### call-same-sync-sendable

The rule for a same-isolation `sync` call when the argument is `Sendable`.

```text
Γ;  @κ; α ⊢ f   : @σ @κ (A) → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A   at _   ⊣  Γ₂
ρ ∈ accessible(@κ)
────────────────────────────────────────────────────────────── (call-same-sync-sendable)
Γ;  @κ; α ⊢ f(arg) : B at ρ  ⊣  Γ₂
```

Key points:
- The premise `arg : A at _` implicitly requires `A : Sendable` (the `_` region is only assigned to Sendable types).
- The result region `ρ` is determined by the callee and may be any region belonging to `accessible(@κ)`: `_` if `B : Sendable`, or `disconnected` (a freshly created value) or `toRegion(@κ)` (derived from actor state) if `B : ~Sendable`, etc.

When `A : ~Sendable`, the premise `arg : A at _` cannot be satisfied, so this rule does not apply. In that case, use [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) (regular argument + bind/refinement) or [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume) (for `sending` arguments).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callSameSync_mainActorFunction_noAwaitNeeded()`

```swift
@MainActor
func sameSyncSendableExample() {
    let f: @MainActor (MySendable) -> MySendable = { $0 }
    let x = MySendable()
    _ = f(x) // no `await`
}
```

#### call-same-async-sendable

The rule formalizing that a same-isolation `async` call requires `await` **even when the argument is `Sendable`**, and that the result region may be any region accessible from the caller capability.

```text
Γ;  @κ; async ⊢ f   : @σ @κ (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A   at _             ⊣  Γ₂
A : Sendable
ρ ∈ accessible(@κ)
────────────────────────────────────────────────────────────── (call-same-async-sendable)
Γ;  @κ; async ⊢ await f(arg) : B at ρ  ⊣  Γ₂
```

This is the first rule in this document where `await` appears in the conclusion.

Calling an `async` function requires `await` even within the same isolation. This is because an `async` function may contain suspension points, and the compiler requires the caller to explicitly acknowledge that "execution may suspend here."

The premise `α = async` in the premises requires that this `await` expression is written in an async context (i.e., an `async` function body or `Task` body). In a `sync` context (`α = sync`), `await` cannot be written and this rule does not apply (see [`call-same-sync-sendable`](#call-same-sync-sendable)).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callSameAsync_mainActorFunction_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callSameAsync_nonSendableReturn_crossIso_works()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callSameAsync_nonSendableReturn_fromActorState()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_callSameAsync_missingAwait_isError()` (`NEGATIVE_CALL_SAME_ASYNC_MISSING_AWAIT`)

```swift
@MainActor
func sameAsyncSendableExample() async {
    let f: @MainActor (MySendable) async -> MySendable = { $0 }
    let x = MySendable()
    _ = await f(x)

    // _ = f(x) // ❌ error: missing `await` (negative test)
}

@MainActor
func sameAsyncNonSendableExample() async {
    let fresh: @MainActor () async -> NonSendable = { NonSendable() }
    let fromActorState: @MainActor () async -> NonSendable = { mainActorState }

    let x = await fresh()
    await OtherActor().useNonSendableSending(x) // ✅ fresh result stays disconnected

    let y = await fromActorState()
    _ = y.value // ✅ actor-state result stays MainActor-isolated
}
```

#### call-same-nonsendable-merge

The rule that expresses, as an environment update, the binding (region refinement) that occurs when a `~Sendable` value is passed as a regular argument in the same isolation.

```text
Γ;  @κ; α ⊢ f   : @σ @κ (A) → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A at ρ_a            ⊣  Γ₂
A : ~Sendable
ρ_a ∈ accessible(@κ)
ρ_a' = ρ_a ⊔ toRegion(@κ)
ρ_b ∈ accessible(@κ)    (B : Sendable ⇒ ρ_b = _)
──────────────────────────────────────────────────────────────────────── (call-same-nonsendable-merge)
Γ;  @κ; α ⊢ f(arg) : B at ρ_b  ⊣  (Γ₂[arg ↦ A at ρ_a'])
```

Key points:
- **The binding fact is left only in the environment update.** The result region `ρ_b` may be any region belonging to `accessible(@κ)`: `ρ_b = _` if `B : Sendable` by the canonical-form condition, or `disconnected` (freshly created) or `toRegion(@κ)` (derived from actor state) if `B : ~Sendable`, etc.
- This rule also applies when `ρ_a = disconnected`. The update in the conclusion becomes `ρ_a' = disconnected ⊔ toRegion(@κ) = toRegion(@κ)`, binding the value to the callee's isolation.
- This rule also applies when `ρ_a = task`. The update becomes `ρ_a' = task ⊔ toRegion(@κ)`. If `toRegion(@nonisolated) = disconnected`, then `ρ_a' = task` and the task region is preserved. On the other hand, with `toRegion(@isolated(a)) = isolated(a)`, we have `task ⊔ isolated(a) = invalid`, so the result is `invalid`, representing a compile error state. A task-region value cannot be "re-bound" to an actor.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `merge_sameIso_doesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_merge_thenCrossSend_isError()` (`NEGATIVE_SEND_AFTER_MAINACTOR_USE`)

```swift
@MainActor
func sameIsolationNonSendableBindsExample() async {
    let x = NonSendable() // disconnected
    mainActorUseNonSendable(x) // ✅ does not consume, but binds/refines `x` to @MainActor region

    let other = OtherActor()
    // await other.useNonSendableSending(x) // ❌ error: `x` is no longer disconnected (negative test)
}
```


#### call-cross-sendable

A boundary crossing requires `await` **regardless of whether the function type is sync or async** (because a hop cannot be statically ruled out). For sync functions, they are implicitly promoted to async via the [`sync-to-async`](#sync-to-async) rule.

Note: `@ι ≠ @concurrent` is for mutual exclusivity with the `call-concurrent-*` rules. Since `@concurrent` has different consumption semantics (does not consume non-Sendable arguments), it is handled by dedicated rules. Also, `@ι ≠ @nonisolated` is for separation of responsibilities with [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) and [`call-nonisolated-sync`](#call-nonisolated-sync) (`@nonisolated` is handled by dedicated rules for async/sync respectively).

Note: Since `@isolated(any)` has unknown runtime isolation, `@κ ≠ @isolated(any)` always holds for any `@κ` (the domain of `@κ` is only `@nonisolated | @isolated(a)`). Therefore, all `call-cross-*` rules below include the case `@ι = @isolated(any)`.

```text
Γ;  @κ; async ⊢ f   : @σ @ι (A) α → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A       at _     ⊣  Γ₂
A : Sendable    B : Sendable    @κ ≠ @ι    @ι ∉ { @concurrent, @nonisolated }
────────────────────────────────────────────────────────────── (call-cross-sendable)
Γ;  @κ; async ⊢ await f(arg) : B at _  ⊣  Γ₂
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callCrossSendableSync_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_callCrossSendableSync_missingAwait_isError()` (`NEGATIVE_CALL_CROSS_SENDABLE_SYNC_MISSING_AWAIT`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callCrossSendableAsync_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_callCrossSendableAsync_missingAwait_isError()` (`NEGATIVE_CALL_CROSS_SENDABLE_ASYNC_MISSING_AWAIT`)

```swift
@MainActor
func crossActorSendableCall_requiresAwaitExample() async {
    let other = SendableActor()
    let x = MySendable()

    _ = await other.echo(x) // `echo` is sync, but hop cannot be ruled out
    _ = await other.echoAsync(x)

    // _ = other.echo(x) // ❌ error: missing `await`
    // _ = other.echoAsync(x) // ❌ error: missing `await`
}
```

#### call-cross-sending-result

The rule that allows safely receiving a `sending` result from a different isolation as `disconnected`.

```text
Γ; @κ; async ⊢ f : @σ @ι () α → sending B  at ρ_f  ⊣  Γ'
B : ~Sendable    @κ ≠ @ι    @ι ∉ { @concurrent }
──────────────────────────────────────────────────────────── (call-cross-sending-result)
Γ; @κ; async ⊢ await f() : B at disconnected  ⊣  Γ'
```

While a `sending` (SE-0430) argument is a consumption on the parameter side (transfer from caller to callee), a `sending` return value is a **transfer on the result side** (from callee to caller). When the return type is declared as `sending B`, the callee guarantees that the value being returned is not bound to any isolation domain. Therefore, the caller receives the result as `disconnected` and can freely use or re-transfer it.

This is a rule that guarantees **safe value production**, not consumption (environment shrinkage).

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `crossActor_sendingResult_compiles()` (the result can be re-sent to another actor = `disconnected`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_crossActor_nonSendingResult_isError()` (`NEGATIVE_RESULT`)

```swift
@MainActor
func crossActorSendingResultExample() async {
    let actor = ResultActor()

    let x = await actor.makeSending() // `sending` result
    _ = x.value

    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ can be re-sent (still disconnected)
}
```

#### call-cross-nonsending-result-error

Returning a `~Sendable` result without `sending` from a cross-isolation call is **underivable** (compile error).

```text
Γ;  @κ; async ⊢ f   : @σ @ι () α → B  at ρ_f  ⊣  Γ₁
B : ~Sendable    @κ ≠ @ι    @ι ∉ { @concurrent }
──────────────────────────────────────────────────────────── (call-cross-nonsending-result-error)
derivation fails (compile error)
```

Note: That the function type is `→ B` (without `sending`) is directly readable from the type annotation in the premise (contrasted with `→ sending B`). `sending` is not part of the type itself, but an attribute on the function's parameter/result position.

**Note on asymmetry (params vs results)**:

For arguments (params), a `disconnected` `~Sendable` value can be implicitly transferred ([`call-nonsendable-consume`](#call-nonsendable-consume), implicit transfer condition of `canSend`). This is safe because the caller relinquishes ownership, and the type system can track it with `Γ \ {arg}`.

For results, the caller is the **receiving side**, and safely bringing a `~Sendable` value generated cross-isolation into the caller's domain requires an **explicit `sending` annotation**. Without `sending`, it is unclear which isolation domain the result value belongs to, and the type system cannot guarantee safety.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_crossActor_nonSendingResult_isError()` (`NEGATIVE_RESULT`)

```swift
private actor NonSendingResultActor {
    func make() -> NonSendable {
        NonSendable()
    }
}

@MainActor
func crossActor_nonSendingResult_errorExample() async {
    let actor = NonSendingResultActor()
    // _ = await actor.make() // ❌ error: non-Sendable result crosses isolation boundary
}
```
#### call-concurrent-sendable

`@concurrent async` may hop off an actor, so per SE-0461, sendable checking is performed on arguments/results in actor-capable contexts. If `Sendable`, the call proceeds as-is:

```text
Γ;  @κ; async ⊢ f   : @σ @concurrent (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A at _                                ⊣  Γ₂
A : Sendable    B : Sendable
────────────────────────────────────────────────────────────── (call-concurrent-sendable)
Γ;  @κ; async ⊢ await f(arg) : B at _  ⊣  Γ₂
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `concurrentAsync_callFromNonisolated_compiles()`

```swift
func concurrentCall_sendableExample() async {
    let f: @concurrent (MySendable) async -> MySendable = { $0 }
    let x = MySendable()
    _ = await f(x)
}
```

#### call-concurrent-nonsendable

Passing an `A : ~Sendable` value to `@concurrent async` requires the value to be at least `disconnected` (actor-bound values are not allowed). **The value is not consumed after the call** (it can still be treated as `disconnected`).

```text
Γ;  @κ; async ⊢ f   : @σ @concurrent (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A at disconnected                     ⊣  Γ₂
A : ~Sendable    B : Sendable
────────────────────────────────────────────────────────────── (call-concurrent-nonsendable)
Γ;  @κ; async ⊢ await f(arg) : B at _  ⊣  Γ₂
```

Rationale: This rule is treated as a "callability check" for `@concurrent` calls rather than "transfer/consumption to another actor" as in [`call-nonsendable-consume`](#call-nonsendable-consume). By requiring `disconnected` in the premise to exclude actor-bound values, and since the callee has no specific actor to bind to, **the environment is preserved as `Γ₂`**. Therefore, the value remains `disconnected` after the call and can be reused or re-sent.

Therefore, values remain `disconnected` after the call and can be reused or re-sent.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `concurrentAsync_callWithDisconnectedNonSendable_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `concurrentAsync_callThenSend_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_concurrentAsync_callWithActorBoundNonSendable_isError()` (`NEGATIVE_CONCURRENT_CALL_ACTOR_BOUND_ARG`)

```swift
@MainActor
func concurrentCall_disconnectedNonSendableExample() async {
    let x = NonSendable() // disconnected
    let f: @concurrent (NonSendable) async -> Void = { _ in }

    await f(x) // ✅ allowed

    // Still disconnected after the call (Swift 6.2.1 observed behavior).
    let other = OtherActor()
    await other.useNonSendableSending(x)

    // await f(mainActorConnectedVar) // ❌ error (negative test: actor-bound argument)
}
```

#### call-nonisolated-async-inherit

A `@nonisolated async` call (SE-0461) is not an isolation boundary crossing (does not require a hop), but because it is `async`, `await` is still required.
This rule handles calls with **`nonsending` parameters**.
Additionally, the region of a `~Sendable` argument is **preserved after the call** (at minimum, it is not bound to `disconnected`).
Even for `@nonisolated async`, when calling with a `sending` parameter where the caller and callee are not in the same region, the argument is treated as consumed under [`call-nonsendable-consume`](#call-nonsendable-consume).

```text
Γ;  @κ; async ⊢ f   : @nonisolated (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A at ρ_a                 ⊣  Γ₂
────────────────────────────────────────────────────────────── (call-nonisolated-async-inherit)
Γ;  @κ; async ⊢ await f(arg) : B at ρ_b  ⊣  Γ₂
```

Note: While other call rules (`call-same-*`, `call-cross-*`, `call-concurrent-*`) explicitly state side conditions for `A : Sendable` / `A : ~Sendable` and region constraints, this rule has none. This is because `nonisolated async` (nonsending) inherits the caller's isolation, and **no isolation boundary crossing occurs**. Without a transfer, no branching based on Sendability or regions is necessary, and arguments and results remain within the caller's context as-is.

Here, `ρ_b` depends on the result type; if `B : Sendable`, it can be normalized to `_`.
When `B : ~Sendable`, **`disconnected` is not always guaranteed** (i.e., `ρ_b` inherently depends on the region of the returned expression).
However, if the return type is `sending B`, then `ρ_b = disconnected` is guaranteed (see [`call-cross-sending-result`](#call-cross-sending-result)).
On the other hand, a NonSendable value created and returned inside a `nonisolated async` body is treated as `disconnected` and can be transferred across a boundary.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_callThenSend_argAndResult_compiles()` (argument is not bound, return value is also transferable)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_callThenSend_compiles()` (minimal example where `disconnected` of the argument is preserved)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_returnNonSendable_canBeSent()` (example where `~Sendable` return value is transferable)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_taskResultThenSend_isError()` (`NEGATIVE_NONISOLATED_ASYNC_TASK_RESULT_THEN_SEND`)

```swift
@MainActor
func nonisolatedAsyncCallThenSendExample() async {
    // nonisolated async helper (inherits caller's isolation, returns a fresh value)
    nonisolated func useAndMakeNonSendable(_ x: NonSendable) async -> NonSendable {
        _ = x.value
        return NonSendable() // creates and returns a value
    }

    let x = NonSendable() // disconnected

    let y = await useAndMakeNonSendable(x)

    let other = OtherActor()
    await other.useNonSendableSending(y) // ✅ result is disconnected (fresh)
    await other.useNonSendableSending(x) // ✅ argument remains disconnected
}

#if NEGATIVE_NONISOLATED_ASYNC_TASK_RESULT_THEN_SEND

// Counterexample: when returning the argument directly, it does not become disconnected
func negative_nonisolatedAsync_taskResultThenSend_isError(_ x: NonSendable) async {
    // nonisolated async identity function (returns the argument as-is)
    nonisolated func id(_ x: NonSendable) async -> NonSendable { x }

    // `x` is a non-Sendable parameter in a `nonisolated async` body, so:
    // x : NonSendable at task
    let y = await id(x)
    // identity returns its parameter, so:
    // y : NonSendable at task  (not disconnected)
    let other = OtherActor()
    await other.useNonSendableSending(y) // ❌ error: task-isolated 'y' passed as `sending`
}

#endif
```

#### call-nonisolated-sync

A `@nonisolated sync` function runs on the caller's executor (SE-0461: "on the caller's executor, no switch").
Therefore, even when called from an actor-isolated context (`@κ = @isolated(a)`), **no isolation boundary crossing occurs** and `await` is not required.

This rule applies only when `@κ ≠ @nonisolated`. When `@κ = @nonisolated`, since `@κ = @ι`, the `call-same-*` rules apply.

```text
Γ;  @κ; α ⊢ f   : @σ @nonisolated (A) → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A at ρ_a                          ⊣  Γ₂
@κ ≠ @nonisolated
ρ_a ∈ accessible(@κ)
ρ_b ∈ accessible(@κ)    (B : Sendable ⇒ ρ_b = _)
────────────────────────────────────────────────────────── (call-nonisolated-sync)
Γ;  @κ; α ⊢ f(arg) : B at ρ_b  ⊣  Γ₂
```

Key points:
- **No `await` required**: nonisolated sync runs on the caller's executor, so no hop occurs.
- **Environment remains `Γ₂`**: the callee is nonisolated and does not bind arguments to a specific actor domain. Therefore, no bind/refinement via `toRegion(@κ)` occurs as in [`call-same-nonsendable-merge`](#call-same-nonsendable-merge).
- **When a `sending` parameter is used**: since `canSend(@κ, @nonisolated, sending)` holds, the argument is treated as consumed under [`call-nonsendable-consume`](#call-nonsendable-consume) (not under this rule).
- The result region `ρ_b` is determined by the callee and can be any region belonging to `accessible(@κ)`.

Contrast with [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit):

| Aspect | `call-nonisolated-sync` | `call-nonisolated-async-inherit` |
|------|------------------------|----------------------------------|
| `await` | Not required | Required (because `async`) |
| Function's `α'` | `sync` | `async` |
| Boundary crossing | None | None (inherits caller isolation) |
| Arg binding | None (`Γ₂`) | None (`Γ₂`) |

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_callFromMainActor_noAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_nonSendableArg_noBinding()`

```swift
func nonisolatedSyncHelper(_ x: NonSendable) -> NonSendable {
    _ = x.value
    return NonSendable()
}

@MainActor
func nonisolatedSyncCallExample() async {
    let x = NonSendable() // disconnected

    // call-nonisolated-sync: @κ = @MainActor, @ι = @nonisolated, sync → no await
    let y = nonisolatedSyncHelper(x)
    _ = y.value // ✅ result accessible

    // x is NOT bound (Γ₂, not Γ₂[x ↦ ...]) — still disconnected
    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ still disconnected, can send
}
```

#### Supplementary Explanations

This section is not a derivation rule in the typing-rule sense, but rather supplementary explanation to aid in reading the existing rules.

##### call-isolated-param-semantics

Supplementary note on SE-0313.

Calling a function that has an `isolated` parameter **does not require a new call rule**.
From the caller's perspective, the actor instance passed as the `isolated` parameter determines the function's isolation, so the existing `call-same-*` / `call-cross-*` rules apply directly.

```text
// f's type: (isolated LocalActor, A) → B
// ≡ @isolated(actor) (A) → B (from caller's perspective)

// When caller is @MainActor:
//   @κ = @isolated(MainActor)
//   @ι = @isolated(actor)  (actor : LocalActor)
//   @κ ≠ @ι → call-cross-* applies → await required

// When caller is also the same isolated LocalActor:
//   @κ = @isolated(actor)
//   @ι = @isolated(actor)
//   @κ = @ι → call-same-* applies → no await
```

In other words, what an `isolated` parameter does is change the source of `@κ` in the callee body from a declaration attribute to an argument ([`decl-fun-isolated-param`](#decl-fun-isolated-param)), and on the caller side, derive `@ι` from the passed actor instance — the call rules themselves are reused as-is.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callerSide_isolatedParam_crossIsolation_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callerSide_isolatedParam_sameIsolation_noAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `callerSide_isolatedParam_crossIsolation_sending()`

```swift
// Helper with `isolated` parameter
func useNS(actor: isolated LocalActor, _ x: NonSendable) {
    actor.useNonSendable(x)
}

// Cross-isolation caller → await required (call-cross-*)
@MainActor
func crossIsolationCaller() async {
    let actor = LocalActor()
    let x = NonSendable()
    await useNS(actor: actor, x) // ✅ cross-iso → await
}

// Same-isolation caller → no await (call-same-*)
func sameIsolationCaller(actor: isolated LocalActor) {
    let x = NonSendable()
    useNS(actor: actor, x) // ✅ same-iso → no await
    _ = x.value            // ✅ bound, not consumed
}
```

##### call-isolation-macro-semantics

Supplementary note on SE-0420.

When `#isolation` is passed (implicitly or explicitly) for an `isolated (any Actor)? = #isolation` parameter, the compiler **propagates the caller's isolation to the callee at the call site**.
This causes the callee to be treated as having **the same isolation** as the caller, and the `call-same-*` rules apply.

```text
f : (isolated (any Actor)? = #isolation, A₁, …) α → R
argument for isolated parameter is #isolation
────────────────────────────────────────────────────
f is treated at the call site as @ι = @κ
→ call-same-* rules apply (does not cross an isolation boundary)
```

This is a meta-rule that functions as an **evidence mechanism** for the existing call rules:
`#isolation` is evidence that carries the caller's `@κ` to the callee at compile time,
and the compiler uses this as grounds for the same-isolation determination.

**Critical difference from `@isolated(any)`**:

| Aspect | `@isolated(any)` function type | `isolated (any Actor)? = #isolation` |
|------|------------------------|--------------------------------------|
| Kind | Function type annotation (`@ι`) | Parameter modifier + default argument |
| Call-site isolation | Always **cross** (`@κ ≠ @isolated(any)` is always true) | **same** when `#isolation` is used |
| `@Sendable` on closure param | Required (boundary crossing) | **Not required** (same isolation) |
| `inout` capture | Not allowed (boundary crossing) | **Allowed** (mutable access is safe at same isolation) |
| Non-Sendable arg | Consumed or requires `disconnected` | **Not consumed** (same-iso) |

Note: Passing `nil` explicitly instead of `#isolation` causes the callee to execute as `nonisolated`.
In this case, if the caller's `@κ` is actor-isolated, then `@κ ≠ @nonisolated` and cross-isolation may result.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_closureDoesNotNeedSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_inoutVarAccessible()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_nonSendableNotConsumed()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_isolationMacro_sendableClosureCannotMutateCapture_isError()` (`NEGATIVE_ISOLATION_MACRO_SENDABLE_MUTATION`)

```swift
// #isolation ensures same-isolation: closure doesn't need @Sendable
func measureTime<T>(
    _ f: () async throws -> T,
    isolation: isolated (any Actor)? = #isolation
) async rethrows -> T {
    try await f()
}

@MainActor
func isolationMacro_closureDoesNotNeedSendable() async {
    // #isolation expands to MainActor.shared → same-isolation
    // → f is non-@Sendable closure, OK because no boundary crossing
    await measureTime {
        print("same isolation as caller")
    }
}

@MainActor
func isolationMacro_inoutVarAccessible() async {
    var progress = 0
    await measureTime {
        progress += 1       // ✅ inout access (same isolation → safe)
        await Task.yield()
    }
    _ = progress
}

@MainActor
func isolationMacro_nonSendableNotConsumed() async {
    let x = NonSendable()
    await measureTime {
        _ = x.value // ✅ non-Sendable captured without @Sendable
    }
    _ = x.value // ✅ still usable (not consumed — same isolation)
}
```


### 5.6 `@isolated(any)`

An `@isolated(any)` (SE-0431) function value has its actor binding determined dynamically as a value, so a call **cannot statically eliminate the hop**. Therefore, **even in sync form, the call site implicitly becomes async and `await` is required** (observed behavior in Swift 6.2).

Note: An `@isolated(any)` function value has a property for observing its dynamic actor identity:

```text
f.isolation : (any Actor)?
```

- `nil` represents "nonisolated (no actor identity)"
    - Because a `task` region is not an actor, even if a task-region value is captured, `f.isolation` becomes `nil` (described below)
- When a function value derived from `@MainActor` is converted to `@isolated(any)`, `f.isolation` becomes `MainActor.shared` (described below)
- **Warning (erasure of dynamic actor identity by type)**: Once assigned (type-converted) to a *non-actor-isolated function type* such as `() -> Void`, even if the value internally executes on the MainActor, converting it back to `@isolated(any)` afterward may cause `f.isolation` to become `nil` (described below).

**Call semantics of `@isolated(any)`**

Because `@isolated(any)` is always treated as cross-isolation, no dedicated call rule is needed, and the existing `call-cross-*` rules apply directly (with `@ι = @isolated(any)`):

| Pattern | Rule applied |
|----------|---------------|
| Sendable result | [`call-cross-sendable`](#call-cross-sendable) |
| `sending` result | [`call-cross-sending-result`](#call-cross-sending-result) |
| ~Sendable result without `sending` | [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error) |

Even for a sync `@isolated(any)` function, it is implicitly promoted to async via [`sync-to-async`](#sync-to-async), making it consistent with the `α = async` / `await` premises of `call-cross-*`.

```swift
@MainActor
func isolatedAnyCall_examples() async {
    // Sendable result → call-cross-sendable
    let fMain: @MainActor () -> MySendable = { MySendable() }
    let fAny: @isolated(any) () -> MySendable = fMain
    let x = await fAny() // ✅ requires `await` (cross-isolation)
    _ = x.value

    // sending result → call-cross-sending-result
    let gMain: @MainActor () -> sending NonSendable = { NonSendable() }
    let gAny: @isolated(any) () -> sending NonSendable = gMain
    let y = await gAny() // ✅ result is `disconnected`
    let other = OtherActor()
    await other.useNonSendableSending(y) // ✅ can be re-sent

    // ~Sendable result without `sending` → call-cross-nonsending-result-error
    // let hMain: @MainActor () -> NonSendable = { NonSendable() }
    // let hAny: @isolated(any) () -> NonSendable = hMain
    // _ = await hAny() // ❌ error: non-Sendable result without `sending`
}
```

#### isolated-any-isolation-prop (`f.isolation`)

This rule gives the ability to observe the dynamic actor identity of an `@isolated(any)` function value as `f.isolation`.

```text
Γ; @κ; α ⊢ f : @isolated(any) () → B  at ρ_f  ⊣  Γ'
────────────────────────────────────────────────────── (isolated-any-isolation-prop)
Γ; @κ; α ⊢ f.isolation : (any Actor)? at _  ⊣  Γ'
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_isolationProperty_typechecks()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_isolationProperty_taskRegionCapture_returnsNil()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_isolationProperty_mainActorCapture_returnsMainActor()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_isolationProperty_mainActorCapture_returnsMainActor2()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_isolationProperty_mainActorCapture_returnsMainActor3()`
- `swift/Tests/concurrency-type-checkTests/IsolatedAnyIsolationTests.swift` `isolatedAnyIsolation_taskRegionCapture_isNil()`
- `swift/Tests/concurrency-type-checkTests/IsolatedAnyIsolationTests.swift` `isolatedAnyIsolation_mainActorCapture_isMainActor()`
- `swift/Tests/concurrency-type-checkTests/IsolatedAnyIsolationTests.swift` `isolatedAnyIsolation_mainActorCapture_plainClosureThenCoerce_isNil()`
- `swift/Tests/concurrency-type-checkTests/IsolatedAnyIsolationTests.swift` `isolatedAnyIsolation_mainActorCapture_isolatedAnyClosureLiteral_isMainActor()`

```swift
/// When a `~Sendable` value is captured into an `@isolated(any)` closure inside a
/// `nonisolated async` function, `.isolation` becomes `nil` because a task region is not an actor.
func isolatedAny_isolationProperty_taskRegionCapture_returnsNil() async -> (any Actor)? {
    let x = NonSendable()
    return await isolatedAny_isolationProperty_taskRegionCapture_returnsNil_impl(x)
}

private func isolatedAny_isolationProperty_taskRegionCapture_returnsNil_impl(
    _ x: NonSendable
) async -> (any Actor)? {
    let f: @isolated(any) () -> Void = { _ = x.value }
    return f.isolation // Expect: nil (dynamically nonisolated; task ≠ actor)
}

/// In a conversion from `@MainActor () -> Void` → `@isolated(any) () -> Void`,
/// actor identity is preserved, so `.isolation` returns `MainActor.shared`.
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor() -> (any Actor)? {
    let fMain: @MainActor () -> Void = { _ = mainActorConnectedVar.value }
    let fAny: @isolated(any) () -> Void = fMain
    return fAny.isolation // Expect: MainActor.shared
}

/// Going through `() -> Void` (a nonisolated function type) erases actor identity.
/// Even after converting to `@isolated(any)`, isolation is not restored, and `.isolation` becomes `nil`.
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor2() -> (any Actor)? {
    let fMain: () -> Void = { _ = mainActorConnectedVar.value }
    let fAny: @isolated(any) () -> Void = fMain
    return fAny.isolation // Expect: nil (actor identity was erased by the `() -> Void` type)
}

/// When an `@isolated(any) () -> Void` is created directly from a closure literal,
/// closure isolation inference in the `@MainActor` context preserves actor identity,
/// and `.isolation` returns `MainActor.shared`.
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor3() -> (any Actor)? {
    let fAny: @isolated(any) () -> Void = { _ = mainActorConnectedVar.value }
    return fAny.isolation // Expect: MainActor.shared
}
```

### 5.7 Closures

This section describes the typing rules for closures.
For `@Sendable` capture constraints, isolation inference, attribute predicates, and boundary determination, see "2.6 Closure Auxiliary Definitions (`@Sendable` / isolation inference)".
Capture is normally non-consuming, but when the closure itself is transferred in a context where it is passed as `sending`, `~Sendable` captures are exceptionally consumed (see [`closure-sending`](#closure-sending) below).

#### closure-inherit-parent

When not at a boundary, the body is type-checked with the effective capability `@κ_{eff}` resolved from the parent's `@κ` via `effectiveClosureCapability`:

```text
@κ_{eff} = effectiveClosureCapability(@κ, { e })
Γ_{captured} ⊆ Γ    ¬isPassedToSendingParameter({ e })
∀ (y : U at ρ) ∈ Γ_{captured}.  ρ ∈ capturable(@κ_{eff})
Γ_{captured}; @κ_{eff}; α' ⊢ e : B at ρ_{ret}  ⊣  Γ'_{cl}
ρ_{closure} = ⨆ { ρ | (y : T at ρ) ∈ Γ_{captured} ∧ T : ~Sendable }
──────────────────────────────────────────────────────────────── (closure-inherit-parent)
Γ; @κ; α ⊢ { e } : @κ_{eff} () α' → B at ρ_{closure}  ⊣  Γ
```

Reading guide (key points):

- **`effectiveClosureCapability(@κ, { e })`** determines the effective capability. Global actors (such as `@MainActor`) and `@nonisolated` return `@κ` unchanged, but **for actor instances (`@isolated(localActor)`), the result branches depending on whether the closure body captures an isolated parameter** (see `capturesIsolatedParam`). If not captured, it falls back to `@nonisolated`.
- `¬isPassedToSendingParameter` means the closure is not being passed to a `sending` parameter. Because the conclusion's type is `@κ_{eff} () α' → B` (without `@Sendable`), it is distinguished from [`closure-no-inherit-parent`](#closure-no-inherit-parent) by the conclusion type pattern. This rule also applies when `inheritActorContext` holds.
- `Γ_{captured} ⊆ Γ` expresses that the capture environment `Γ_{captured}` is a subset of the current environment `Γ`.
- `Γ_{captured}; @κ_{eff}; α' ⊢ e : ...` means "type-check the closure body under effective capability `@κ_{eff}` and sync/async mode `α'`." `Γ'_{cl}` appears to track consumption and refinement inside the closure, but since the body is not executed at closure creation time, it is not reflected in the outer environment.
- The third premise line is the capture constraint. The region `ρ` of each captured variable must belong to `capturable(@κ_{eff})`. For example, a `@isolated(a)` closure cannot capture a value from the `task` region (`task ∉ capturable(@isolated(a))`). See "Capture availability."
- `ρ_{closure}` is the region of the closure value, and is the join (least upper bound) of the regions of **only the NonSendable captures**. Sendable captures are always `at _` and do not participate in the join. If the join of NonSendable captures yields `invalid`, it indicates the entire closure is in a compile-error state.
- The conclusion remains `⊣ Γ` because ordinary closure creation does not consume captures (does not change the environment). Captures are consumed only when passed as `sending` (see [`closure-sending`](#closure-sending) below).

Verification (Swift 6.2) — global actor (no capture required):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `closureIsolationInherit_nonSendableInheritsMainActor()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `mainActorClosureCapture_doesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonSendableClosureCapture_doesNotConsume()`

```swift
@MainActor
func closureInheritParentExample() {
    let x = NonSendable() // x : NonSendable at disconnected

    // non-@Sendable sync closure → not a boundary
    // → effectiveClosureCapability(@MainActor, _) = @MainActor (global actor: no capture needed)
    let f: () -> Void = {
        _ = mainActorConnectedVar.value // ✅ body checked with @κ_{eff} = @MainActor
        _ = x.value                      // ✅ capture disconnected NonSendable
    }
    f()

    // non-@Sendable async closure → same inheritance
    let g: () async -> Void = {
        _ = mainActorConnectedVar.value // ✅ @MainActor inherited
    }
    _ = g

    // captures are not consumed (⊣ Γ, not ⊣ Γ \ {...})
    _ = x.value // ✅ still usable after capture

    // ρ_{closure} of f = ⨆{disconnected} = disconnected (from x's region)
}
```

Verification (Swift 6.2) — actor instance (isolation changes depending on whether self is captured):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `closureInActorMethod_capturesSelf_inheritsIsolation()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `closureInActorMethod_noCaptureOfSelf_becomesNonisolated()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `closureWithIsolatedParam_capturesParam_inheritsIsolation()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `closureWithIsolatedParam_noCaptureOfParam_becomesNonisolated()`
- `swift/Tests/concurrency-type-checkTests/ClosureActorInstanceIsolationTests.swift` `closureActorInstanceIsolation_captureInference()`
- `swift/Tests/concurrency-type-checkTests/ClosureActorInstanceIsolationTests.swift` `closureGlobalActor_noCaptureNeeded()`

```swift
// Case 1: actor method captures self → @κ_{eff} = @isolated(self)
actor MyActor {
    var state: Int = 0

    func withCapture() {
        let cl: @isolated(any) () -> Void = {
            _ = self.state // capturesIsolatedParam = true
            // → effectiveClosureCapability(@isolated(self), cl) = @isolated(self)
            // → cl.isolation === self ✅
        }
        _ = cl
    }

    // Case 2: actor method does NOT capture self → @κ_{eff} = @nonisolated
    func withoutCapture() {
        let cl: @isolated(any) () -> Void = {
            // capturesIsolatedParam = false (no reference to self)
            // → effectiveClosureCapability(@isolated(self), cl) = @nonisolated
            // → cl.isolation === nil ✅
        }
        _ = cl
    }
}

// Case 3: isolated parameter, with capture
func isolatedParamWithCapture(actor: isolated LocalActor) {
    let cl: @isolated(any) () -> Void = {
        _ = actor // capturesIsolatedParam = true → @κ_{eff} = @isolated(actor)
    }
    _ = cl // cl.isolation === actor ✅
}

// Case 4: isolated parameter, without capture
func isolatedParamWithoutCapture(actor: isolated LocalActor) {
    let cl: @isolated(any) () -> Void = {
        // capturesIsolatedParam = false → @κ_{eff} = @nonisolated
    }
    _ = cl // cl.isolation === nil ✅
}
```

#### closure-no-inherit-parent

A `@Sendable` closure is type-checked with `toCapability(@ι)`:

```text
Γ_{captured} ⊆ Γ
¬inheritActorContext({ e })    ¬isPassedToSendingParameter({ e })
isAllSendable(Γ_{captured})
@κ_{cl} = toCapability(@ι)
Γ_{captured}; @κ_{cl}; α' ⊢ e : B at ρ_{ret}  ⊣  Γ'_{cl}
──────────────────────────────────────────────────────────────── (closure-no-inherit-parent)
Γ; @κ; α ⊢ { e } : @Sendable @ι () α' → B at _  ⊣  Γ
```

The `@Sendable @ι` in the conclusion comes from the contextual type (expected type). The compiler propagates `@Sendable` from the contextual type to the closure's type (`CSApply.cpp`).

Meaning of premises:
- `¬inheritActorContext` — `@_inheritActorContext` is not attached (when attached, [`closure-inherit-parent`](#closure-inherit-parent) applies even for `@Sendable`)
- `¬isPassedToSendingParameter` — not being passed to a `sending` parameter (when it is, [`closure-sending`](#closure-sending) handles it)
- `isAllSendable(Γ_{captured})` — all captures in the capture environment are `Sendable`
- `toCapability(@ι)` — determines the closure's capability `@κ_{cl}` from `@ι`

Examples of closure capability:
- `@ι = @nonisolated` → `toCapability(@nonisolated) = @nonisolated`
- `@ι = @MainActor` → `toCapability(@MainActor) = @MainActor`

`α'` is the sync/async mode of the closure body.

Note (compiler correspondence):
- `inheritActorContext` ≈ `inheritsActorContext()` (`Expr.h`), sourced from the `@_inheritActorContext` attribute
- `isPassedToSendingParameter` ≈ `isPassedToSendingParameter()` (`Expr.h`), set in `CSApply.cpp`
- `@Sendable` is propagated from the contextual type (`CSApply.cpp:7637-7650`) → `isSendable() = true`

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noInherit_sendableNonisolated_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noInherit_sendableMainActor_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_noInherit_sendableLosesIsolation_isError()` (`NEGATIVE_CLOSURE_SENDABLE_LOSES_ISOLATION`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_noInherit_sendableCannotCaptureNonSendable_isError()` (`NEGATIVE_VAR_DISCONNECTED_SENDABLE_CAPTURE`)

```swift
// Case 1: @Sendable () → @ι = @nonisolated → body is nonisolated
func closureNoInheritExample_nonisolated() {
    let s = MySendable()
    let f: @Sendable () -> MySendable = { s } // ✅ Sendable capture, nonisolated body
    _ = f().value

    // Cannot access @MainActor state from nonisolated body
    // let _: @Sendable () -> Void = {
    //     _ = mainActorConnectedVar.value // ❌ error: nonisolated context
    // }
}

// Case 2: @Sendable @MainActor () → @ι = @MainActor → body is @MainActor
@MainActor
func closureNoInheritExample_mainActor() {
    let f: @Sendable @MainActor () -> Void = {
        _ = mainActorConnectedVar.value // ✅ body is @MainActor (from @ι, not inherited)
    }
    f()
}
```

#### closure-sending

A closure passed to a `sending` parameter does not always behave the same way.
In Swift 6.2, it is necessary to distinguish between the **inherited-task case where the same concrete actor isolation can be proven** and **the transfer case where it cannot**.

First, when `@_inheritActorContext` causes the closure to inherit the caller's actor isolation, and the caller itself is actor-isolated, captures are not consumed for the same reason as in same-isolation `sending`:

```text
f : (sending (@κ_{cl} () α' → T)) → R
Γ_{captured} ⊆ Γ
inheritActorContext({ e })    isActorIsolated(@κ)    @κ_{cl} = @κ
∀ (x : U at ρ) ∈ Γ_{captured}.  ρ ∈ capturable(@κ)
Γ_{captured}; @κ_{cl}; α' ⊢ e : T at ρ_{ret}  ⊣  Γ'_{cl}
────────────────────────────────────────────────────────────── (closure-sending-noconsume)
Γ; @κ; α ⊢ f({ e }) : R at _  ⊣  Γ
```

On the other hand, when the same actor cannot be proven, it is treated as a transfer: `~Sendable` captures must be `disconnected`, and they are consumed from the caller's side:

```text
f : (sending (@κ_{cl} () α' → T)) → R
Γ_{captured} ⊆ Γ
¬(inheritActorContext({ e }) ∧ isActorIsolated(@κ) ∧ @κ_{cl} = @κ)
∀ (x : U at ρ) ∈ Γ_{captured}.  (U : Sendable)  ∨  (U : ~Sendable ∧ ρ = disconnected)
Γ_{captured}; @κ_{cl}; α' ⊢ e : T at ρ_{ret}  ⊣  Γ'_{cl}
Γ' = Γ \ { x | (x : U at disconnected) ∈ Γ_{captured} ∧ U : ~Sendable }
────────────────────────────────────────────────────────────── (closure-sending-consume)
Γ; @κ; α ⊢ f({ e }) : R at _  ⊣  Γ'
```

Reading guide:
- `f({ e })` is a call that passes closure `{ e }` to function `f`, which has a `sending` parameter
- `closure-sending-noconsume` represents the inherited-task case where the same concrete actor isolation can be proven. Captures remain in the environment, just as with ordinary same-isolation closures
- `closure-sending-consume` represents the transfer case. `Γ \ Γ'` corresponds to the "consumed (= sent) NonSendable captures" (requirement: all must be disconnected)

**How `@κ_{cl}` is determined**: it is determined by the signature of the function that receives the `sending` parameter.
Here `@κ_{cl}` represents the closure's capability (`@nonisolated | @isolated(a)`):

| Syntax | `@κ_{cl}` | Reason |
|------|-------------|------|
| `Task { ... }` | Inherits caller's `@κ` | `@_inheritActorContext` inherits caller's isolation |
| `Task.detached { ... }` | `@nonisolated` | No `@_inheritActorContext` → `toCapability(@isolated(any)) = @nonisolated` |
| General `f(sending closure)` | Depends on signature | Determined by `toCapability` from `@ι` in the `sending` parameter's type |

Note: Both `Task.init` and `Task.detached` accept `sending @escaping @isolated(any) () async throws -> Success`.
The difference is that `Task.init` has `@_inheritActorContext` attached. This causes `Task.init` to have the call-site isolation inherited by the closure, while `Task.detached` does not inherit it.
Therefore, `Task.init` is **not always consuming**. A `Task { ... }` from an actor-isolated caller can fall into `closure-sending-noconsume`, but a `Task { ... }` from a nonisolated caller or `Task.detached { ... }` falls into `closure-sending-consume`.

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_canCaptureDisconnectedNonSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_sameActorDisconnectedCaptureDoesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_sameActorBoundCaptureDoesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskInit_useAfterSend_isError()` (`NEGATIVE_TASKINIT_USE_AFTER_SEND`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskDetached_canCaptureDisconnectedNonSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskDetached_useAfterSend_isError()` (`NEGATIVE_TASKDETACHED_USE_AFTER_SEND`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskDetached_captureActorBound_isError()` (`NEGATIVE_TASKDETACHED_CAPTURE_ACTOR_BOUND`)

```swift
func taskCapture_consumesDisconnectedNonSendableExample() {
    let x = NonSendable() // disconnected

    // Task.init with same concrete actor isolation (e.g. @MainActor) does not consume
    Task {
        _ = x.value // ✅ can capture disconnected NonSendable
    }

    _ = x.value // ✅ still usable in same-actor inherited task

    let y = NonSendable() // disconnected

    // Task.detached is a transfer case, so captures are cut from the caller
    Task.detached {
        _ = y.value
    }

    // _ = y.value // ❌ error: use-after-send (already consumed)
}

func taskCapture_nonisolatedTaskInitConsumesExample() {
    let x = NonSendable()

    Task {
        _ = x.value
    }

    // _ = x.value // ❌ data-race risk from nonisolated caller
}

@MainActor
var mainActorBound = NonSendable()

func detachedCannotCaptureActorBoundExample() {
    // Task.detached { _ = mainActorBound.value } // ❌ error: actor-bound is not disconnected, cannot capture
}
```


---

### 5.8 `async let`

`async let` is a fundamental building block of structured concurrency: it runs the initializer expression concurrently in a child task and retrieves the result via `await`.
From the type system perspective, `async let` has the following characteristics:

1. **Child task boundary**: The initializer is implicitly wrapped in an `AutoClosureExpr` (kind `AsyncLet`) and is always type-checked as `nonisolated async`
2. **Sendability boundary**: The autoclosure is not `@Sendable`, but SIL-level region isolation tracks the sending of captures (Sema-level `@Sendable` checks are deferred)
3. **Temporary consumption**: `~Sendable` captures are sent to the child task at the `async let` declaration point and returned to the caller after `await` (SIL-level `undoSend`)
4. **Variable access effects**: The bound variable `x` has type `T` (not `Task<T, ...>`), but accessing it requires `await` (and `try` if the initializer can throw)

Compiler implementation:
- Declaration: `CSApply.cpp` `wrapAsyncLetInitializer()` — autoclosure wrapping
- Boundary determination: `TypeCheckConcurrency.cpp` `isSendingBoundaryForConcurrency()` — `AsyncLet` is always a boundary
- Capture: `TypeCheckConcurrency.cpp` `checkSendableInstanceMethodCaptures()` area — deferred to region isolation
- Effects: `TypeCheckEffects.cpp` `classifyDeclEffect()` — classifies access as async (+ throws)
- SIL region: `RegionAnalysis.cpp` `translateSILPartialApplyAsyncLetBegin()` / `translateAsyncLetGet()` — send / undoSend

Differences from `Task { ... }`:
- `Task.init` can inherit the caller's isolation via `@_inheritActorContext`, but `async let`'s autoclosure is always treated as a nonisolated boundary
- When same-actor proof is available for `Task.init`, captures are not consumed ([`closure-sending-noconsume`](#closure-sending)), whereas `async let` always sends captures
- `Task.init` consumption is permanent, whereas `async let` consumption is undone after `await` (`undoSend`)

#### async-let

```text
Γ_{captured} ⊆ Γ
∀ (y : U at ρ) ∈ Γ_{captured}.  (U : Sendable) ∨ (U : ~Sendable ∧ ρ = disconnected)
Γ_{captured}; @nonisolated; async ⊢ expr : T at ρ_{init}  ⊣  Γ'_{child}
Γ_{sent} = Γ \ { y | (y : U at disconnected) ∈ Γ_{captured} ∧ U : ~Sendable }
ρ_x = if T : Sendable then _ else disconnected
────────────────────────────────────────────────────────── (async-let)
Γ; @κ; async ⊢ async let x = expr  ⊣  Γ_{sent}, x : T at ρ_x
```

Reading guide:
- Since the conclusion is `Γ; @κ; async ⊢ ...`, `async let` can only be used within an async context
- Line 3 is the capture constraint. `~Sendable` captures must be `disconnected`. Actor-bound (`isolated(a)`) values cannot be captured
- `Γ_{captured}; @nonisolated; async ⊢ expr : T ...` — the initializer `expr` is type-checked as **nonisolated async** within the child task. Since `@κ = @nonisolated`, accessing isolated state such as `@MainActor` within the child task requires `await` (cross-isolation)
- `Γ_{sent}` is the result of removing `~Sendable` captures from the environment. Between the declaration and `await x`, captured `~Sendable` values are in a "sent" state and cannot be used
- `Γ'_{child}` — the output environment after type-checking the initializer `expr` in the child task context. If a cross-isolation call occurs within the child task, captures are consumed and removed from `Γ'_{child}` (e.g., `mainActorAsyncInt(x)` is a cross-isolation call from nonisolated to @MainActor, consuming `x` → `x ∉ dom(Γ'_{child})`). This information is used for the `undoSend` determination in [`async-let-access`](#async-let-access)
- `ρ_x` — the region of the bound variable. `_` if `T : Sendable`, otherwise `disconnected` (the child task's result is a fresh value for the caller)

**`undoSend`**: At the point of `await x` (async let get), captures that were not consumed by cross-isolation within the child task are restored to the caller's environment:

```text
undoSend(Γ, x) = Γ ∪ { y : U at disconnected | y ∈ sent_{async-let}(x) ∧ y ∈ dom(Γ'_{child}) }
```

Here `dom(Γ)` denotes the set of variable names contained in environment `Γ` (its domain), i.e. `y ∈ dom(Γ) ⇔ ∃ T, ρ. y : T at ρ ∈ Γ`.
Also, `sent_{async-let}(x)` is the set of variables removed when transitioning from `Γ` to `Γ_{sent}` in the `async-let` rule, and `Γ'_{child}` is the child task output environment from that same rule.
The condition `y ∈ dom(Γ'_{child})` indicates that capture `y` was not consumed by cross-isolation within the child task:

| Initializer | `y ∈ dom(Γ'_{child})`? | Reason |
|-------------|------------------------|--------|
| `nonisolatedAsyncInt(x)` | ✅ | same-isolation (nonisolated → nonisolated) — does not consume |
| `mainActorAsyncInt(x)` | ❌ | cross-isolation (nonisolated → @MainActor) — `x` is consumed by [`call-nonsendable-consume`](#call-nonsendable-consume) |

This `undoSend` is implemented in the SIL pass `RegionAnalysis.cpp`'s `translateAsyncLetGet()`.

#### async-let-access

Accessing a variable bound by `async let` differs from a normal variable reference in that `await` is required (to wait for the child task to complete). At the same time, `undoSend` is applied to restore captures that were not consumed by cross-isolation within the child task:

```text
(x : T at ρ) ∈ Γ    isAsyncLet(x)
Γ' = undoSend(Γ, x)
──────────────────────────────────────── (async-let-access)
Γ; @κ; async ⊢ await x : T at ρ  ⊣  Γ'
```

- This rule requires `Γ; @κ; async ⊢ ...` in the conclusion, so `await` can only be written in an async context
- If the initializer can throw, `try await x` is required (effects managed by `TypeCheckEffects.cpp`)
- `ρ` is the region determined at declaration time (`_` or `disconnected`)
- `Γ' = undoSend(Γ, x)` — restores captures not consumed by cross-isolation within the child task as `disconnected`. Captures that were sent cross-isolation within the child task (`y ∉ dom(Γ'_{child})`) are not restored

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `asyncLet_captureDisconnectedNonSendable_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `asyncLet_sendableCapture_doesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `asyncLet_resultTypeIsT_notTask()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `asyncLet_nonSendableResult_isDisconnected()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `asyncLet_nonSendableResult_scopeSeparated_canSend()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `asyncLet_mainActorCaller_capturesConsumed()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_asyncLet_useBeforeAwait_isError()` (`NEGATIVE_ASYNCLET_USE_BEFORE_AWAIT`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_asyncLet_crossIsolation_useAfterAwait_isError()` (`NEGATIVE_ASYNCLET_CROSS_ISO_USE_AFTER_AWAIT`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_asyncLet_taskRegionCapture_isError()` (`NEGATIVE_ASYNCLET_TASK_REGION_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_asyncLet_actorBoundCapture_isError()` (`NEGATIVE_ASYNCLET_ACTOR_BOUND_CAPTURE`)

```swift
// [async-let] basic: disconnected ~Sendable capture → sent to child task
func asyncLet_captureDisconnectedNonSendable_compiles() async {
    let x = NonSendable()             // x : NonSendable at disconnected
    async let y = nonisolatedAsyncInt(x)
    let _ = await y
    // After await: undoSend restores x (nonisolated → no cross-iso send in body)
    _ = x.value  // ✅
}

// [async-let] Sendable capture is not consumed
func asyncLet_sendableCapture_doesNotConsume() async {
    let s = MySendable()
    async let y = nonisolatedAsyncInt(s)
    _ = s.value   // ✅ Sendable capture → not consumed
    let _ = await y
    _ = s.value   // ✅
}

// [async-let] result type is T (not Task<T, ...>)
func asyncLet_resultTypeIsT_notTask() async {
    async let y: Int = nonisolatedAsyncInt(42)
    let result: Int = await y  // ✅ type of y is Int, not Task<Int, Never>
    _ = result
}

// [async-let] ~Sendable result is disconnected
// result can be re-captured by another async let (async let capture requires disconnected)
func asyncLet_nonSendableResult_isDisconnected() async {
    async let y = nonisolatedAsyncIdentity(NonSendable())
    let result = await y
    async let z = nonisolatedAsyncInt(result) // ✅ re-capture requires disconnected
    let _ = await z
}

// [async-let] scope separation allows cross-isolation sending of async let result
// SIL region analysis links async let binding and result within the same scope,
// so separating with do { ... } severs the region link and enables sending
func asyncLet_nonSendableResult_scopeSeparated_canSend() async {
    let result: NonSendable
    do {
        async let y: NonSendable = NonSendable()
        result = await y
    } // async let y goes out of scope → region link severed
    await OtherActor().useNonSendableSending(result) // ✅ disconnected
}

// [async-let] @MainActor caller: async let is still a nonisolated boundary
// Consumption verified by: NEGATIVE_ASYNCLET_CROSS_ISO_USE_AFTER_AWAIT
@MainActor
func asyncLet_mainActorCaller_capturesConsumed() async {
    let x = NonSendable()
    async let y = mainActorAsyncInt(x)
    let _ = await y
    // Child task is nonisolated → mainActorAsyncInt is cross-isolation → x is consumed
    // undoSend does not restore x because x ∉ dom(Γ'_{child})
}

// ❌ use before await is an error (data race between parent and child task)
func negative_asyncLet_useBeforeAwait_isError() async {
    let x = NonSendable()
    async let y = nonisolatedAsyncInt(x)
    // _ = x.value  // ❌ sending 'x' risks causing data races
    let _ = await y
}

// ❌ cross-isolation send within body → error even after await (undoSend: x ∉ dom(Γ'_{child}))
func negative_asyncLet_crossIsolation_useAfterAwait_isError() async {
    let x = NonSendable()
    async let y = mainActorAsyncInt(x)  // child: nonisolated → @MainActor (cross-iso → x consumed)
    let _ = await y
    // _ = x.value  // ❌ x was sent to MainActor within child task
}

// ❌ task region capture: nonisolated async param (at task) cannot be captured by async let
func negative_asyncLet_taskRegionCapture_isError(_ x: NonSendable) async {
    // async let y = nonisolatedAsyncInt(x)  // ❌ task-region value cannot be sent to child task
    // let _ = await y
}

// ❌ actor-bound capture: @MainActor global (at isolated(MainActor)) cannot be captured by async let
@MainActor
func negative_asyncLet_actorBoundCapture_isError() async {
    let g = mainActorConnectedVar
    // async let y = nonisolatedAsyncInt(g)  // ❌ actor-bound value cannot exit isolation context
    // let _ = await y
}
```

---

### 5.9 Sendable Inference (SE-0418)

[SE-0418](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0418-inferring-sendable-for-methods.md) defines rules for inferring `@Sendable` / `& Sendable` for function references and KeyPath literals. `@Sendable` is inferred when captures are `Sendable` (or when there are no captures).

Compiler implementation: `lib/Sema/TypeOfReference.cpp` `getTypeOfMethodReferencePost()` and `lib/Sema/ConstraintSystem.cpp` `inferKeyPathLiteralCapability()`.

#### infer-sendable-nonlocal

Function references to non-local functions (top-level functions, static methods) have no captures, so `@Sendable` is inferred unconditionally. The result region is `_` (Sendable). Static methods are `@Sendable` regardless of the Sendability of the type they are declared on (metatypes are always `Sendable`).

```text
isNonLocal(f)
f : (A₁, …, Aₙ) α → R
────────────────────────────────────────────────────────── (infer-sendable-nonlocal)
Γ; @κ; α' ⊢ f : @Sendable (A₁, …, Aₙ) α → R  at _  ⊣  Γ
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_nonlocal_topLevel()`
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_nonlocal_static()`
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_nonlocal_static_nonSendableType()`

```swift
private func topLevelCompute() -> Int { 42 }

func inferSendable_nonlocal_topLevel() {
    let f = topLevelCompute
    let _: @Sendable () -> Int = f // ✅ top-level function is always @Sendable
}

private struct SendablePoint: Sendable {
    static func staticCompute(_ x: Int) -> Int { x * 2 }
}

func inferSendable_nonlocal_static() {
    let f = SendablePoint.staticCompute
    let _: @Sendable (Int) -> Int = f // ✅ static method is always @Sendable
}

private class NonSendableCounter { // ~Sendable
    static func staticHelper() -> Int { 0 }
}

func inferSendable_nonlocal_static_nonSendableType() {
    let f = NonSendableCounter.staticHelper
    let _: @Sendable () -> Int = f // ✅ static method is always @Sendable (metatype is Sendable)
}
```

#### infer-sendable-method-sendable

An unapplied method reference `T.m` has a two-level curried type `(T) → ((A₁,…) α → R)`. The compiler makes two determinations:

1. **The outer function type**: always `@Sendable` (self is a parameter, not a capture — "fully uncurried type doesn't capture anything")
2. **The inner function type**: `@Sendable` only when `T : Sendable` (because the inner closure captures `self`)

When `T : Sendable`, both are `@Sendable`:

```text
T : Sendable
m ∈ instanceMethods(T)
m : (A₁, …, Aₙ) α → R
──────────────────────────────────────────────────────────────────────────────── (infer-sendable-method-sendable)
Γ; @κ; α' ⊢ T.m : @Sendable (T) → @Sendable ((A₁, …, Aₙ) α → R)  at _  ⊣  Γ
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_method_sendableType()`

```swift
private struct SendablePoint: Sendable {
    func compute(_ x: Int) -> Int { value + x }
}

func inferSendable_method_sendableType() {
    let f = SendablePoint.compute
    // Both outer AND inner are @Sendable when T: Sendable
    let _: @Sendable (SendablePoint) -> @Sendable (Int) -> Int = f // ✅
}
```

#### infer-sendable-method-non-sendable

When `T : ~Sendable`, the outer is `@Sendable` (no capture) but the inner is not `@Sendable` (because it captures non-Sendable `self`):

```text
T : ~Sendable
m ∈ instanceMethods(T)
m : (A₁, …, Aₙ) α → R
────────────────────────────────────────────────────────────────── (infer-sendable-method-non-sendable)
Γ; @κ; α' ⊢ T.m : @Sendable (T) → ((A₁, …, Aₙ) α → R)  at _  ⊣  Γ
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_method_nonSendableType()`
- `swift/Sources/concurrency-type-check/InferSendable.swift` `negative_inferSendable_method_nonSendableType_inner()` (`NEGATIVE_UNAPPLIED_NON_SENDABLE_INNER`)

```swift
private class NonSendableCounter {
    func increment() { value += 1 }
}

func inferSendable_method_nonSendableType() {
    let f = NonSendableCounter.increment
    // Outer is @Sendable (no capture), inner is NOT (captures non-Sendable self)
    let _: @Sendable (NonSendableCounter) -> () -> Void = f // ✅ outer @Sendable
}

// let _: @Sendable (NonSendableCounter) -> @Sendable () -> Void = f // ❌ inner NOT @Sendable
```

#### infer-sendable-keypath

When a KeyPath literal contains no actor-isolated components and all captures are `Sendable`, `& Sendable` is inferred.

Compiler implementation: `ConstraintSystem.cpp` `inferKeyPathLiteralCapability()` manages an `isSendable` flag and walks each component. Actor isolation from `ActorInstance` and `GlobalActor` alone causes non-Sendable (`Nonisolated`, `NonisolatedUnsafe`, `CallerIsolationInheriting` have no effect).

```text
kp = \T.path
¬hasIsolatedKeyPathComponent(kp)
isAllSendable(captures(kp))
─────────────────────────────────────────────────────────── (infer-sendable-keypath)
Γ; @κ; α ⊢ kp : any KeyPath<T, V> & Sendable  at _  ⊣  Γ
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_keypath_noCapture()`
- `swift/Sources/concurrency-type-check/InferSendable.swift` `inferSendable_keypath_functionConversion()`
- `swift/Sources/concurrency-type-check/InferSendable.swift` `negative_inferSendable_keypath_actorIsolated()` (`NEGATIVE_KEYPATH_ACTOR_ISOLATED`)
- `swift/Sources/concurrency-type-check/InferSendable.swift` `negative_inferSendable_keypath_nonSendableCapture()` (`NEGATIVE_KEYPATH_NON_SENDABLE_CAPTURE`)

```swift
private struct UserProfile {
    var name: String
    @MainActor var age: Int { get { 0 } }
    subscript(info: NonSendableCounter) -> String { "entry" }
}

func inferSendable_keypath_noCapture() {
    let kp = \UserProfile.name
    let _: WritableKeyPath<UserProfile, String> & Sendable = kp // ✅ no non-Sendable captures
}

func inferSendable_keypath_functionConversion() {
    let _: @Sendable (UserProfile) -> String = \.name // ✅ KeyPath → @Sendable closure conversion
}

// When conditions are not met (& Sendable is not inferred):
// let _: any KeyPath<UserProfile, Int> & Sendable = \.age          // ❌ actor-isolated component
// let _: any KeyPath<UserProfile, String> & Sendable = \.[info]    // ❌ non-Sendable capture
```

---

---

## 6. Examples

### Example 1: Same isolation (nonsending binds but does not consume)

- Due to [`call-same-nonsendable-merge`](#call-same-nonsendable-merge), `x` is not consumed; instead the environment is updated so that `x : ... at isolated(MainActor)`
- As a result, subsequent `sending` transfers that require `disconnected` (such as [`call-nonsendable-consume`](#call-nonsendable-consume)) become invalid

```swift
@MainActor
func negative_merge_thenCrossSend_isError() async {
    let x = NonSendable()
    mainActorUseNonSendable(x) // binds x → isolated(MainActor)

    let other = OtherActor()

    // ❌ x is no longer disconnected
    await other.useNonSendableSending(x)
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_merge_thenCrossSend_isError()` (`NEGATIVE_SEND_AFTER_MAINACTOR_USE`)

### Example 2: Same isolation (`sending` does not consume — Same vs Cross)

A concrete example of [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume): passing to a `sending` parameter is not consumed when `isActorIsolated(@κ) ∧ @κ = @ι` holds. When this condition breaks, consumption occurs.

```swift
@MainActor func useSending(_ x: sending NonSendable) {}

@MainActor
func example_sameVsCross() async {
    let x = NonSendable()

    // (1) Same isolation: call-nonsendable-noconsume → Γ₂ (no consume)
    useSending(x)       // ✅ same isolation: not consumed
    useSending(x)       // ✅ still accessible

    // (2) Cross isolation: call-nonsendable-consume → Γ₂ \ {x} (consumed)
    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ consumed here
    _ = x.value                          // ❌ error: use-after-send
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_actorBound_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_thenUse_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_thenCrossSend_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_twice_compiles()`

### Example 3: Different isolation (implicit transfer is consumed)

Even without the `sending` keyword, passing a `~Sendable` value across isolation boundaries causes an implicit consumption ([`call-nonsendable-consume`](#call-nonsendable-consume), implicit transfer condition of `canSend`).

```swift
@MainActor
func consume_crossIsoImplicit() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendable(x)

    _ = x.value  // ❌ error: use-after-consume
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_crossIsoImplicit_compiles()`

### Example 4: Different isolation (explicit `sending` is consumed)

Passing to an explicit `sending` parameter across isolation boundaries is likewise affinely consumed ([`call-nonsendable-consume`](#call-nonsendable-consume)).

```swift
@MainActor
func consume_crossIsoExplicitSending() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendableSending(x)

    _ = x.value  // ❌ error: use-after-consume
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_crossIsoExplicitSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_consume_crossIsoExplicitSending_useAfter_isError()` (`NEGATIVE_USE_AFTER_EXPLICIT_SENDING`)

### Example 5: `Task` capture (same-actor `Task.init` retains; otherwise consumes)

The operation parameter of `Task.init` is `sending`, but when the same concrete actor isolation can be proven via `@_inheritActorContext`, the [`closure-sending-noconsume`](#closure-sending) branch applies and the capture is not consumed.
On the other hand, `Task.init` from a nonisolated caller or `Task.detached` falls into the [`closure-sending-consume`](#closure-sending) branch, and `~Sendable` captures are treated as transfers:

```swift
@MainActor
func taskInit_sameActorCapture() {
    let x = NonSendable()
    Task {
        _ = x.value
    }
    _ = x.value // ✅ same concrete actor isolation → not consumed
}

func negative_taskInit_useAfterSend() {
    let x = NonSendable()
    Task {
        _ = x.value
    }

    // ❌ nonisolated caller → sending data-race risk
    _ = x.value
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_sameActorDisconnectedCaptureDoesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_sameActorBoundCaptureDoesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskInit_useAfterSend_isError()` (`NEGATIVE_TASKINIT_USE_AFTER_SEND`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskDetached_useAfterSend_isError()` (`NEGATIVE_TASKDETACHED_USE_AFTER_SEND`)

### Example 6: nonisolated async arguments behave like `task` (SE-0461)

Due to the `ρᵢ = task` condition in [`decl-fun`](#31-async-function-body-introduction-boundary-of-α) (`@ι = @nonisolated ∧ α = async ∧ Aᵢ : ~Sendable ⇒ ρᵢ = task`), `~Sendable` parameters in `nonisolated async` functions are treated as `task` regions.
From the definition of [`capturable(@κ)`](#capture-eligibility-capturableκ), a `task` region is capturable in nonisolated / `@isolated(any)` closures, but cannot be captured in a `@MainActor` closure:

```swift
// ✅ Capture task-isolated parameter into a nonisolated closure inside nonisolated async
nonisolated func helper(_ x: NonSendable) async {
    let noniso: () -> Void = { _ = x.value }
    let isoAny: @isolated(any) () -> Void = { _ = x.value }
    _ = (noniso, isoAny)
}

// ❌ Capture task-isolated parameter into a @MainActor closure → error
nonisolated func negative(_ x: NonSendable) async {
    let _: @MainActor () -> Void = { _ = x.value }  // ❌
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_paramBehavesLikeTaskRegion()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_ASYNC_PARAM_MAINACTOR_CAPTURE`)

### Example 7: `@isolated(any)` calls require `await` even with a sync signature (SE-0431)

Because `@isolated(any)` is always treated as cross-isolation, the existing [`call-cross-sendable`](#call-cross-sendable) / [`call-cross-sending-result`](#call-cross-sending-result) rules apply directly (with `@ι = @isolated(any)`, `@κ ≠ @ι` always holds).
Since isolation is not statically determined until runtime, `await` is required at the call site even for a sync signature:

```swift
@MainActor
func isolatedAny_requiresAwait() async {
    let f: @isolated(any) () -> Void = { @MainActor in }

    // @isolated(any) → isolation is statically unknown → await required
    await f()  // ✅ await required even though f is sync
}

@MainActor
func isolatedAny_returnSendingNonSendable() async {
    let f: @isolated(any) () -> sending NonSendable = { @MainActor in NonSendable() }

    let x = await f()  // ✅ sending return → safe to receive cross-isolation
    _ = x.value
}
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_call_coercedFromMainActor_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_call_returnSendingNonSendable_compiles()`

### Example 8: `isolated` parameter — sync access + cross-isolation await (SE-0313)

Via [`decl-fun-isolated-param`](#decl-fun-isolated-param), `@κ = @isolated(actor)` is derived from the `isolated` parameter.
(1) Sync access to the same actor's state is permitted by the [`var`](#var) rule + [`accessible(@κ)`](#23-region-access-accessibleκ), and (2) calls to a different actor require `await` via [`call-cross-sendable`](#call-cross-sendable):

```swift
// (1) The isolated parameter enables sync access under the same isolation
func isolatedParam_syncAccess(actor: isolated LocalActor) {
    _ = actor.state // ✅ sync access (no `await`)
}

// (2) Cross-isolation requires await
@MainActor
func isolatedParam_crossIsolation() async {
    let actor = LocalActor()
    _ = await actor.getState() // ✅ cross-iso → await
}
```

```text
// Derivation outline:
//
// Γ₀ = { actor : LocalActor at _ }
// @κ = @isolated(actor)
//
// (1) actor.state — var: isolated(actor) ∈ accessible(@isolated(actor)) ✅ (sync, no await)
// (2) other.getState() — call-cross-sendable: @κ = @isolated(actor) ≠ @ι = @isolated(other) → await required
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_syncAccessInSameIsolation()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_crossIsolation_requiresAwait()`

### Example 9: Cross-isolation NonSendable result without `sending` → error

Via [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error), returning a `~Sendable` result across an isolation boundary without `sending` is not derivable:

```swift
@MainActor
func negative_crossActor_nonSendingResult() async {
    let actor = NonSendingResultActor()

    // ❌ non-Sendable result crosses isolation boundary without `sending`
    let nonSendingResult = await actor.make()
}
```

```text
// Derivation outline:
//
// @κ = @isolated(MainActor)
// @ι = @isolated(NonSendingResultActor)  (= different actor)
// f : @ι () → NonSendable
// NonSendable : ~Sendable, return position has no `sending`
//
// → [call-cross-nonsending-result-error](#call-cross-nonsending-result-error) applies → derivation fails
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_crossActor_nonSendingResult_isError()` (`NEGATIVE_RESULT`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_isolatedAny_call_returnNonSendable_isError()` (`NEGATIVE_ISOLATED_ANY_NON_SENDABLE_RESULT`)

### Example 10: `#isolation` eliminates the need for `@Sendable` + enables `inout` access (SE-0420)

`#isolation` propagates the caller's isolation to the callee, so at the call site `@ι = @κ` holds and the [`call-same-*`](#call-same-sync-sendable) rules apply (no isolation boundary).
Because the closure is non-`@Sendable`, it inherits the parent's isolation via [`closure-inherit-parent`](#closure-inherit-parent), making `@Sendable` unnecessary and allowing safe capture of `inout` variables:

```swift
// Helper function using `#isolation` (SE-0420)
func measureTime<T, E: Error>(
    _ f: () async throws(E) -> T,
    isolation: isolated (any Actor)? = #isolation
) async throws(E) -> T {
    try await f()
}

@MainActor
func isolationMacro_example() async {
    // (1) The closure does not need @Sendable
    await measureTime {
        print("same isolation as caller")
    }

    // (2) Capturing an inout variable is safe
    var progress = 0
    await measureTime {
        progress += 1       // ✅ inout access (same isolation)
        await Task.yield()
    }
    _ = progress

    // (3) Non-Sendable captures are not consumed
    let x = NonSendable()
    await measureTime {
        _ = x.value // ✅ non-Sendable captured without @Sendable
    }
    _ = x.value // ✅ still usable (same isolation)
}
```

```text
// Derivation outline:
//
// caller: @κ = @isolated(MainActor), α = async
// measureTime type: (isolation: isolated (any Actor)? = #isolation, () async throws -> T) async rethrows -> T
//
// (1) #isolation → expands to MainActor.shared
//     → callee is treated as @ι = @κ = @isolated(MainActor) at the call site
//     → call-same-* applies (no isolation boundary)
//
// (2) closure { progress += 1; await Task.yield() } is non-@Sendable
//     → inherits @κ = @isolated(MainActor) via [closure-inherit-parent](#closure-inherit-parent)
//     → mutable local `progress` capture is safe (same isolation)
//
// (3) measureTime call — call-same-async (effectively)
//     → non-Sendable capture is not consumed
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_closureDoesNotNeedSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_inoutVarAccessible()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_nonSendableNotConsumed()`

### Example 11: Nonisolated sync — "callable from" ≠ "convertible to" (call vs capture)

[`call-nonisolated-sync`](#call-nonisolated-sync) allows nonisolated sync functions to be called from any actor-isolated context without `await`. However, this call-site property does not produce a new edge in the function type conversion rules ([`func-conv`](#func-conv)).

Closure wrapping `{ g() }` involves **two independent checks**:

1. **Capture check**: whether `g`'s region can cross into the closure's isolation (region-dependent)
2. **Call check**: whether the closure body (`@κ`) can call `g()` → always ✅ via `call-nonisolated-sync`

| Region of `g` | Capture into `@MainActor` closure | Reason |
|---|---|---|
| `disconnected` (local variable) | ✅ binding | disconnected can be bound to any region |
| `disconnected` (`sending` parameter) | ✅ binding | `sending` guarantees `disconnected` |
| `task` (ordinary parameter) | ❌ | task region cannot be captured cross-isolation |
| `isolated(MainActor)` | ✅ same-isolation | same isolation |

```swift
// (1) ✅ Direct call: call-nonisolated-sync applies
@MainActor
func nonisolatedSyncCallFromMainActor() {
    let x = NonSendable()
    nonisolatedSyncHelper(x)  // ✅ no await — nonisolated sync runs on caller's executor
}

// (2) ❌ General type conversion: func-conv has no N → M rule
// func convert(_ g: @escaping () -> Void) -> @MainActor () -> Void {
//     g  // ❌ direct coercion: no isoSubtyping/isoCoercion rule
// }

// (3) ✅ Closure wrapping with disconnected local
func nonisolatedSyncDisconnectedWrapping() {
    let g: () -> Void = {}              // g at disconnected
    let f: @MainActor () -> Void = { g() } // ✅ capture: disconnected → binding
    _ = f                                   //    call: call-nonisolated-sync ✅
}

// (4) ❌ Closure wrapping with parameter (task region)
// func nonisolatedSyncParamWrapping(_ g: @escaping () -> Void) {
//     let _: @MainActor () -> Void = { g() }  // ❌ task → @MainActor capture blocked
// }

// (4') ✅ Closure wrapping with `sending` parameter (disconnected)
func nonisolatedSyncSendingParamWrapping(_ g: sending @escaping () -> Void) {
    let f: @MainActor () -> Void = { g() } // ✅ sending → disconnected → binding
    _ = f
}

// (5) ✅ Same-isolation closure wrapping
@MainActor
func nonisolatedSyncSameIsolationWrapping() {
    let g: () -> Void = {}              // g at isolated(MainActor)
    let f: @MainActor () -> Void = { g() } // ✅ same-isolation capture
    _ = f                                   //    call: call-nonisolated-sync ✅
}
```

```text
// Derivation outline:
//
// (1) call-nonisolated-sync:
//     @κ = @isolated(MainActor), @ι = @nonisolated, sync
//     @κ ≠ @nonisolated ✅ → no await, no boundary crossing
//
// (3) disconnected wrapping — 2 independent checks:
//     Capture: g at disconnected → @MainActor closure = binding (disconnected can be bound to any region)
//     Call:    @κ = @MainActor body → g() nonisolated sync = call-nonisolated-sync ✅
//
// (4) parameter wrapping — capture blocks:
//     Capture: g at task → @MainActor closure = cross-isolation ❌ (task cannot be bound to a specific actor)
//     Call:    would be ✅ (call-nonisolated-sync) but capture check fails first
//
// (4') sending parameter wrapping — capture succeeds:
//     Capture: g at disconnected (sending) → @MainActor closure = binding ✅
//     Call:    call-nonisolated-sync ✅
```

Verification (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_callFromMainActor_noAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_nonSendableArg_noBinding()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_sameIsolationClosureWrapping_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_disconnectedClosureWrapping_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedSync_paramClosureWrapping_isError()` (`NEGATIVE_NONISOLATED_SYNC_PARAM_CLOSURE_WRAPPING`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_sendingParamClosureWrapping_compiles()`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest` `normalToMainActor` (❌ commented out)
