---
marp: true
math: katex
theme: tryswift
paginate: false
---

<!--
_class: lead
_paginate: false
-->

# <!-- fit --> Swift Concurrency <br> Type System

## try! Swift Tokyo 2026

**@inamiy**

<!--
Hi everyone! My name is Inamiy.
It's a pleasure to speak at try! Swift Tokyo Conference.
Today, I'd like to talk about Swift Concurrency, which everyone loves — and also struggles with.

In this session, we’ll start with concrete examples and then deep-dive into the foundations of Swift Concurrency type system.
It's a lot to cover, so let’s get started!

00:30
-->

---

<!--
_class: keyword-wall
-->

## Swift Concurrency Keywords

`async` `await` `actor` `@globalActor` `@MainActor`
`Task` `TaskGroup` `async let`
`AsyncSequence` `Continuation` `@TaskLocal`

`isolated` `nonisolated` `nonisolated(unsafe)` `nonisolated(nonsending)` `@isolated(any)` `@concurrent` `#isolation`

`Sendable` `@Sendable` `sending`

**20+ concurrency-related types, keywords, and attributes**

<!--
Let's start with a quick recap on Swift Concurrency.
Here's a list of all the related keywords we have today.

As you can see, there are already more than 20 types, keywords, and attributes — and this list keeps growing.

If you find this list is already overwhelming, you're probably not alone.
-->

---

<!--
_class: keyword-wall
-->

# <!-- fit --> Swift Concurrency is Hard
## <span style="font-size: 120px">😇</span>

<!--
Swift Concurrency is indeed hard to learn.

1:00
-->

---

## What makes Swift Concurrency Hard?

Especially when **closures** are involved:

```swift
@MainActor
class ViewModel {
    func updateUI() { ... }

    func run(completion: @Sendable () -> Void) { ... }

    func setup() {
        run {
            updateUI() // ❌ compile error
        }
    }
}
```

Swift compiler knows. But do *you* know **why**?

<!--
So, what makes Swift Concurrency hard for us?

In my opinion, the hardest part is, when the "closures" come into play.

Consider this example:
We have `@MainActor` class calling a method with a completion closure handler.
But this doesn't compile.
Can you tell why?

Answering this kind of question is often tricky and hard to reason about.
So, we really want to have a bit more clear and formal way to explain this kind of problem.

So let's reframe our question.

1:30
-->

---

# The Question

> What are the **core rules** behind
> Swift Concurrency type system?

<!--
"What are the core rules behind this Swift Concurrency's type system?"

1:40
-->

---

<!--
_class: lead
_paginate: false
-->

# Closure Conversion Rules

<!--
To dig deeper, let's first start exploring "Closure conversion rules".
-->

---

## Closure Conversion

> Given <code>f: <span class="at">@A</span> () -> <span class="ty">Void</span></code>,
> can we assign to / use in <code>g: <span class="at">@B</span> () -> <span class="ty">Void</span></code>?

```swift
let f: @A () -> Void = { ... }
let g: @B () -> Void = f  // or `{ f() }`
```

This is **subtyping / coercion** between concurrency annotations

<div class="footnote">Note: <span class="at">@A</span> and <span class="at">@B</span> can be ANY concurrency attributes, not only about global actor isolation</div>

<!--
Imagine we have a closure `f` annotated with some concurrency attribute `@A`.
Now, our question is: "Can we convert this `f` with a new attribute `@B` instead?"

This question is really important to us, because it asks about "closure subtyping" and "coercion rules".

2:10
-->

---

## *Sync* closure conversion

<div class="columns">
<div>

```swift
var f: @MainActor () -> Void = {}
var g: @SomeActor () -> Void = {}
g = f // ❌ // g = { f() } also fails
f = g // ❌
```

```swift
var f: @MainActor () -> Void = {}
var g: () -> Void = {}
g = f // ❌
f = g // ❌
```

</div>
<div>

```swift
var f: @MainActor () -> Void = {}
var g: @Sendable () -> Void = {}
g = f // ❌
f = g // ✅
```

```swift
var f: @isolated(any) () -> Void = {}
var g: () -> Void = {}
g = f // ⚠️ (❌ in future)
f = g // ✅
```

</div>
</div>

<!--
And if we play around with Swift code,
we will get this kind of conversion results.
Note that all closures in this slide are "synchronous".

Starting with the top-left: conversion fails in both directions,
because the two closures belong to different actor isolations.
And we are not even allowed to use `await` here, so the compiler simply rejects both cases.

The bottom-left is the same story.
`@MainActor` versus `nonisolated`, which are also different isolations, so neither direction compiles.

Now, look at the top-right.
This is actually the same example case as I shared in the beginning of this talk.
Here, `@Sendable` closure can be converted to `@MainActor`-isolated, but not vice versa.
Why? Because `@Sendable` is safe to be used in any isolation domain,
while `@MainActor` closure is restricted to the main actor.

Finally, the bottom-right shows `@isolated(any)` versus `nonisolated` closure.
`@isolated(any)` is an isolation-erased type that can represent any isolation or even nonisolated.
So, a nonisolated closure can be weakened to `@isolated(any)`, but going the other way is not allowed.

3:30
-->

---

<!--
_class: tiny-code
-->

## *Sync* Conversion Matrix

| From ↓ \ To → | ~iso | @S | @MA | @MA @S | @iso? | @iso? @S | iso(a) | iso(a) @S |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **~iso** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **@S** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **@MA** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **@MA @S** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **@iso?** | ⚠️ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **@iso? @S** | ⚠️ | ⚠️ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| **iso(a)** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **iso(a) @S** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

<div class="footnote">~iso = nonisolated, @S = @Sendable, @MA = @MainActor, @iso? = @isolated(any), <br>
iso(a) = isolated LocalActor, ⚠️ = warning (future error)</div>

<!--
By exhaustively checking every possible pattern, we can summarize the results into this matrix.

Now, let's visualize this into a diagram...
-->

---

<!--
_paginate: false
-->

<img src="assets/func-conversion-sync.svg" style="max-height:95%;margin:auto;display:block;">

<!--
... and we get this simple, clean graph now.

At the very bottom sits `nonisolated @Sendable` — the most flexible type that can be used anywhere.
Each arrow points upward, showing that a closure can be converted from bottom to top.
And at the very top is `@isolated(any)`.
This is the type-erasure that accepts all the others — making it the weakest to call.

Once we have this hierarchy in mind, reasoning about closure conversions becomes much more intuitive.

5:00
-->

---

## *Async* closure conversion

<div class="columns">
<div>

```swift
var f: @MainActor () async -> Void = {}
var g: @SomeActor () async -> Void = {}
g = f // ❌
f = g // ❌
g = { await f() } // ✅ actor hop
f = { await g() } // ✅ actor hop
```

```swift
var f: @MainActor () async -> Void = {}
var g: () async -> Void = {}
g = f // ✅
f = g // ❌
g = { await f() } // ✅
f = { await g() } // ❌
```

</div>
<div>

```swift
var f: @MainActor () async -> Void = {}
var g: @Sendable () async -> Void = {}
g = f // ✅
f = g // ✅
g = { await f() } // ✅
f = { await g() } // ✅
```

```swift
var f: @isolated(any) () async -> Void = {}
var g: () async -> Void = {}
g = f // ✅
f = g // ✅
g = { await f() } // ✅
f = { await g() } // ✅
```

</div>
</div>

<!--
Next, let's move on to async closure conversion.

Unlike the synchronous case, `async` opens up many more conversions
because we can now `await` across actor isolation boundaries.
Of course there is a small runtime cost for each actor hop, but in return,
differences in actor isolation become less of a barrier.

5:30
-->

---

<!--
_class: tiny-code
-->

## *Async* Conversion Matrix

| From ↓ \ To → | ~iso | @S | @MA | @MA @S | @iso? | @iso? @S | @conc | @conc @S |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **~iso** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| **@S** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **@MA** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **@MA @S** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **@iso?** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| **@iso? @S** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **@conc** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ |
| **@conc @S** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

<div class="footnote">@conc = @concurrent. iso(a) omitted in this table (same as "sync"). </div>

<!--
And here is the async conversion matrix.
You can see many more "green checks" compared to the synchronous version.
-->

---

<!--
_paginate: false
-->

<img src="assets/func-conversion-async.svg" style="max-height:95%;margin:auto;display:block;">

<!--
And here is the diagram for async case.
Notice the red bi-directional arrows.
These represent conversions that work both ways, thanks to `await` actor hops.

6:00
-->

---

<!--
_paginate: false
-->

<img src="assets/func-conversion.svg" style="max-height:95%;margin:auto;display:block;">

<!--
Finally, here is the full picture combining both synchronous and async diagrams.
The blue arrow in the center represents "Async Lift", which means,
any synchronous closure can be implicitly promoted to its async counterpart.

06:30
-->

---

## Closure Conversion Rules

- **@Sendable** is stronger closure than **non-@Sendable**
- **nonisolated** is stronger closure than **isolated**
- **@isolated(any)** is the weakest closure (most generic)
- **isolated LocalActor** is tied to extra `isolated` param, which can be added but cannot be reduced for conversion
- **Sync closure conversion** is the most painful due to `await` being impossible
- **Async closure conversion** is easier to achieve via `await` (actor hop)
- **Sync to Async conversion** is always possible (but not vice-versa)

<!--
Let's recap what we've covered so far.

The trickiest part would be the synchronous closure conversion — since we can't use `await`,
our options for crossing isolation boundaries are very limited.

And with these diagrams in hand, writing Swift Concurrency code should feel more predictable now.

... But that said, these rules are still the tip of the iceberg.
To go even deeper, we need to explore more of the "type system" that forms the foundation of Swift Concurrency.

To demystify what drives Swift Concurrency under the hood, we need to look at two key axes...

07:15
-->

---

<!--
_class: lead
_paginate: false
-->

# Capability & Region

<!--
which are: "Capability" and "Region".

07:30
-->

---

## Question

```swift
@MainActor class ViewModel {
    @FooActor var handler: @BarActor () -> Void
}
```

Q. Which isolation does `handler` have?

<!--
Before we go deeper, here's a quick quiz.
Given this code, which isolation does `ViewModel.handler` actually have?
Take a moment to think about it...

... Did you find the answer?

08:00
-->

---

## Answer

```swift
@MainActor class ViewModel {
    @FooActor var handler: @BarActor () -> Void
}
```

- Where does the **code** run? → `@BarActor`
- Where does the **value** live? → `@FooActor`
- `@MainActor` is not used in `handler` 😛

*Isolation Domain* (capability, execution context) and
*Isolation Region* (value isolation) are different!

<!--
The answer is, there are actually two distinct isolation layers at play here.

First, `@BarActor` determines the "isolation domain" — that is, "where the code actually runs".
We can think of it as the "execution context".

Second, the handler itself "lives" in `@FooActor` as part of an "isolation region".
This is a value-level isolation — it controls "who can access the value", not where the code executes.

So, to recap, there are two separate isolation concepts in Swift: "Isolation Domain" and "Isolation Region".
For the rest of this talk, I'll simply call them "Capability" and "Region", borrowing the terminology from type theory.

09:00
-->

---

## Axis 1: Capability ($@κ$)

**Where code runs** — Actor's execution context

```swift
@MainActor func updateUI() { ... }  // runs on MainActor
nonisolated func compute() { ... }  // runs anywhere
```

- Determines what values actor can access
- Controls whether `await` is needed for cross-isolation calls

<!--
Let's start with the first axis: Capability.

Capability determines the execution context of a function or closure.
This decides whether we need `await` keyword when calling across actor isolation boundaries.

09:15
-->


---

## Function Annotation ($@φ$) & Capability ($@κ$)

$$\huge @φ ::= \underbrace{@σ}_{\tiny \text{sendability}} \; \underbrace{@ι}_{\tiny \text{isolation}}$$

| $@σ$ (Sendability) | $@ι$ (Isolation Domain) |
|----------|---------|
| $\cdot$ (none) | $\cdot$ (none) (`@nonisolated`) |
| `@Sendable` | `@isolated(a)` (e.g. `@MainActor`) |
| | `@isolated(any)` |
| | `@concurrent` (async only) |

**Capability** $@κ ::=$ `@nonisolated` | `@isolated(a)` $\quad$ ($@κ \subseteq @ι$)

<!--
In Swift, concurrency annotation can be split into two parts: Sendability and Isolation.

And within Isolation, we define Capability as a "subset" of it —
which is only either "isolated to an actor" or "nonisolated".

Note that `@isolated(any)` and `@concurrent` are classified as `nonisolated` here.
This matches how Swift compiler actually handles them internally.

09:45
-->

---

## Axis 2: Region ($ρ$)

**Where data lives** — Actor's value isolation (SE-0414)

$$\huge ρ_{ns} ::= \texttt{disconnected} \mid \texttt{isolated}(a) \mid \texttt{task} \mid \textit{invalid}$$

| $ρ_{ns}$ | Meaning |
|---------|---------|
| $\texttt{disconnected}$ | Free to travel (not yet bound) |
| $\texttt{isolated}(a)$ | Bound to actor $a$ |
| $\texttt{task}$ | Bound to current async task |

Tracks which isolation a *NonSendable* value belongs to.

<!--
The 2nd axis is Region.

As many of you may already know, Swift 6 introduced "Region-based isolation",
a major addition that is also covered extensively in Swift Evolution proposal SE-0414.

In short, regions track where NonSendable values belong.
A value can be in one of three states:
"disconnected", meaning it's free and not yet bound to any actor,
"isolated to actor `a`", meaning it's tied to a specific actor,
or "task" region, meaning it's bound to the current task inherited from the caller.

10:30
-->

---

## Region in Action

```swift
@MainActor func example() async {
    let x = NonSendable()           // x at disconnected
    mainActorViewModel.field = x    // x at isolated(MainActor) <- BOUND!

    let other = OtherActor()
    await other.use(x)  // ❌ error: x is no longer disconnected
}
```

**Region merge**: $\texttt{disconnected} ⊔ \texttt{isolated}(\text{a}) = \texttt{isolated}(\text{a})$

Once bound, a value *cannot be sent* across isolation boundaries.

<!--
Here is a concrete example of how region-check works.

First, we create a `NonSendable` value `x`.
At this point, it's in a disconnected region.
Then, we assign it to a MainActor-isolated property, which binds `x` to the MainActor-region.
Now, if we try to pass this same `x` to a different actor, the compiler rejects it.

And this makes sense.
Once a value is bound to some actor-region, it cannot jump to another.

Under the hood, Swift compiler performs this check line by line,
using a key operation called "region merge".

11:15
-->

---

## Region Merge ($ρ_1 ⊔ ρ_2$)

| $ρ_1$ | $ρ_2$ | $ρ_1 ⊔ ρ_2$ |
|---|---|---|
| $\texttt{disconnected}$ | $\texttt{disconnected}$ | $\texttt{disconnected}$ |
| $\texttt{disconnected}$ | $\texttt{isolated}(a)$ | $\texttt{isolated}(a)$ |
| $\texttt{disconnected}$ | $\texttt{task}$ | $\texttt{task}$ |
| $\texttt{isolated}(a)$ | $\texttt{isolated}(a)$ | $\texttt{isolated}(a)$ |
| $\texttt{isolated}(a)$ | $\texttt{isolated}(b)$ | *invalid* $(a \neq b)$ |
| $\texttt{isolated}(a)$ | $\texttt{task}$ | *invalid* |
| $\texttt{task}$ | $\texttt{task}$ | $\texttt{task}$ |


<div class="footnote">See also: <a href="https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md">SE-0414: Region based Isolation</a></div>

<!--
Region-Merge works like in this table.
The key insight here is that, merging two different actor regions produces an "invalid" state, meaning the compiler rejects it.

11:30
-->

---

## Region Merge as Join Semilattice

<img src="assets/region-merge-semilattice.svg" style="max-height:40%;margin:auto;display:block;">

- $\texttt{disconnected}$ = bottom of $ρ_{ns}$
- $\textit{invalid}$ = top (compile error)

<!--
And once again, using diagram is much more intuitive to understand.
This kind of structure is so-called "join semilattice".

A value starts at the leftmost node as "disconnected" region.
This can be merged to the right direction into either an "actor-isolated region" or a "task region".
But these branches never mix together.
If we do so, it will be an "invalid region" landing at the rightmost node, which is a compile error.

12:00
-->

---

## The Two Axes Together

| Aspect | Capability $@κ$ | Region $ρ$ |
|--------|-------------------|-------------|
| **What** | Execution context | Value location |
| **Question** | Where does code *run*? | Where does data *live*? |
| **Examples** | `@nonisolated`, `@MainActor` | $\texttt{disconnected}$, $\texttt{isolated}(a)$ |
| **Changes** | Fixed per scope | Flow-sensitive |
| **Controls** | `async` / `await` | `sending` |

<!--
To summarize Capability and Region:
Capability answers "where does code run?", and it is the execution context.
Region answers "where does data live?", and it is the value-level isolation scope.

12:15
-->

---

<!--
_class: lead
_paginate: false
-->

# Affine Types

<!--
Now, let's take a brief detour to talk about Affine Type System.
-->

---

# Swift Ownership

| Keyword | Description |
|---------|-------|
| `Copyable` | Can be copied and used multiple times |
| `~Copyable` | Cannot be implicitly copied (consume once)
| `consuming` param | Takes ownership
| `borrowing` param | Temporary read-only access

<!--
What are Affine Types?
In Swift, actually, we already know them as Swift Ownership.
Since Swift 5.9, `NonCopyable` type has been introduced alongside `consuming` and `borrowing` keywords,
which enables "move semantics and aliasing" that avoids unnecessary copies for better performance.

12:45
-->

---

# Affine Types

$$A ⊬ A \otimes A \quad \leftarrow \text{can NOT copy}$$

$$A ⊢ \mathbf{1} \quad \leftarrow \text{can discard}$$

- Linear Types: use exactly once (no copy, must use)
- **Affine Types**: use *at most once* (no copy, can skip use)

No copy = *Enforced consumption*

<!--
The key property of Affine Types is: you cannot duplicate a value.

The first sentence says "from one A, you cannot produce two A's."
The second says "but you can still discard one A."

A real-world analogy would be: you can't clone an apple, and you can decide not to eat it.
And this actually maps more naturally to the real-world problem than a purely copy-only model.

Now, you might be wondering: "Why is this guy talking about Ownership in a Concurrency talk?"

13:30
-->

---

## Similarity: Consumption

<div class="columns">
<div>

Ownership

```swift
func useConsuming(
  _ x: consuming NonCopyable) {}

func consumingExample() {
    let x = NonCopyable()
    useConsuming(x)
    _ = x // ❌
}
```

</div>
<div>

Concurrency

```swift
func useSending(
  _ x: sending NonSendable) {}

func sendingExample() {
    let x = NonSendable()
    useSending(x)
    _ = x // ❌
}
```

</div>
</div>

Both **consuming** and **sending** enforce
consumption of `~Copyable` / `~Sendable` value.

<!--
Well, actually, both of them share the same idea.

Look at these two code examples side by side — `consuming` from Ownership and `sending` from Concurrency.
They behave almost identically: once a value is consumed or sent to another actor isolation boundary,
it becomes inaccessible on the very next line.

14:00
-->

---

## <!-- fit --> Region-based Isolation is like Ownership

- **Sendable** is like **Copyable**
  - Value and reference can be copied and used in multiple isolation domains
- **NonSendable** is like **~Copyable**
  - Cannot be used after transferring to another isolation domain
- **sending** is like **consuming** (but *not always*)
  - **sending** param may still not get consumed in the *same region* condition

<!--
That said, we can think of it this way.

`Sendable` is like `Copyable`.
A Sendable value can freely appear in multiple isolation domains,
just as a Copyable value can be used in multiple places by copying.

Conversely, `NonSendable` is like `NonCopyable`.
Once you `send` a NonSendable value away, you can no longer access it,
just like `NonCopyable` value becomes inaccessible after `consuming`.

For `sending` keyword, it behaves almost like `consuming`,
but slight nuance here is that, it is "NOT always" consuming.

14:30
-->

---

## `sending` param (in same isolation)

<div class="columns">
<div>

**non-sending**

```swift
@MainActor func use(
  _ x: NonSendable
) {}

@MainActor func example() async {
  let x = NonSendable() // disconnected
  use(x)       // bind: x → MainActor
  _ = x.value  // ✅ still accessible

  let other = OtherActor()

  // ❌ `x` cannot cross actor region
  await other.useSending(x)
}
```

binds to actor region

</div>
<div>

**sending**

```swift
@MainActor func useSending(
  _ x: sending NonSendable
) {}

@MainActor func example() async {
  let x = NonSendable() // disconnected
  useSending(x) // stays disconnected
  _ = x.value   // ✅ still accessible

  let other = OtherActor()

  // ✅ passing from disconnected region
  await other.useSending(x)
}
```

keeps in **same region**

</div>
</div>

<!--
And here's the exception.
Only within the same actor isolation,
`sending` doesn't actually consume the value but "keeps it in the same region".
This is quite interesting Swift compiler behavior that is worth paying attention to.

15:00
-->

---

## `sending` return

```swift
@MainActor func makeNonSendable() -> NonSendable {
    self.nonSendable  // region could be isolated(MainActor)
}

@MainActor func makeSending() -> sending NonSendable {
    NonSendable()  // guarantees disconnected region
}

@MainActor func example() async {
    let x = makeNonSendable()
    await other.use(x)   // ❌ x may be isolated(MainActor)

    let y = makeSending()
    await other.use(y)   // ✅ y is guaranteed disconnected
}
```

`sending`-return guarantees the value is **disconnected**

<!--
By the way, for `sending` return values, the sent value is guaranteed to be in the disconnected region.

To recap this `sending` behavior, to be honest, it is a bit tricky.
But we can mostly say that, `sending` is similar to `consuming`,
so Swift Concurrency behavior is actually very similar to Swift Ownership and Affine Types.

15:00
-->

---

<!--
_class: lead
_paginate: false
-->

# Formalizing
# Swift Concurrency
# Type System

<div class="footnote"><span class="at">Disclaimer</span>: This section is an AI vibe-formalization.</div>

<!--
Alright, so far, we have covered Capability, Region, and Affine Types.

But we are still only halfway to answering our original question:
"What are the "core rules" behind the Swift Concurrency type system?"

To fully distill those rules, we need to "formalize" them in more type-theoretic approach.

As this is going to be a very deep academic topic, I won't challenge myself for full rigor here.
Instead, I will share my rough sketch based on "AI vibe-formalization".

15:45
-->

---

$$\huge Γ ⊢ \; e : T$$

<!--
To start, this is the standard typing judgement we normally see in many programming languages' type systems.

Here, `Γ` is the typing context — a dictionary from variable names to their types.
It reads: "under context Γ, expression `e` has type `T`."

But Swift's concurrency type system needs much more information than just Γ, so we will need to extend this form.

16:15
-->

---

$$\huge Γ; @κ; α \; ⊢ \; e : T \; \textbf{at} \; ρ \; ⊣ \; Γ'$$

<!--
And here is my proposed extended judgement for Swift Concurrency.
It looks intimidating at a glance, so let's break it down into pieces.

16:30
-->

---

## The Judgment Form

$$\huge \underbrace{Γ}_{\text{env}_{\text{in}}};\; \underbrace{@κ}_{\text{capability}};\; \underbrace{α}_{\text{mode}} \;\underbrace{⊢}_{\text{proves}}\; \underbrace{e}_{\text{expr}} : \underbrace{T}_{\text{type}} \;\textbf{at}\; \underbrace{ρ}_{\text{region}} \;\underbrace{⊣}_{\text{outputs}}\; \underbrace{Γ'}_{\text{env}_{\text{out}}}$$

- $Γ$ / $Γ'$: what variables are available (input / output)
  - e.g. $Γ = \{e_1 : T_1 \;\textbf{at}\; ρ_1,\;\; e_2 : T_2 \;\textbf{at}\; ρ_2,\;\; \ldots\}$
  - Every expression *transforms* the type environment from $Γ$ to $Γ'$ (**Affinity**)
- $@κ$: current capability (where we're running)
- $α$: $\texttt{sync} \mid \texttt{async}$ (asynchrony)
- $ρ$: which region the expression result lives in

<!--
Here is what each symbol means.
We've added κ for capability, α for sync/async mode, and ρ for region.
There is also Γ' which is the output environment on the right side.
This output environment can be also seen in Affine Type System.

17:00
-->

---

## Example 1

$$Γ;\; @\texttt{nonisolated};\; \texttt{sync} \;⊢\; x : T \;\textbf{at}\; \texttt{disconnected} \;⊣\; Γ$$

```swift
nonisolated func example() {
    let x: T = ...  // x is newly created → disconnected
    _ = x           // just reading: Γ stays the same
}
```

<!--
And let's take a look at some examples.
This slide shows that, in a synchronous, nonisolated context, a newly created value `x` starts in the disconnected region.
Since we're only reading it, the environment Γ stays unchanged.

17:15
-->

---

## Example 2

$$Γ;\; @\texttt{MainActor};\; \texttt{async} \;⊢\; \texttt{await}\; f(x) : T \;\textbf{at}\; \_ \;⊣\; \fcolorbox{red}{transparent}{$Γ \setminus \{x\}$}$$

```swift
@SomeActor func f(_ x: NonSendable) -> T { ... }

@MainActor func example() async {
    let x = NonSendable() // x : NonSendable at disconnected
    _ = await f(x)        // cross-isolation: x is sent

    // ❌ error: Γ does not contain `x` anymore
    _ = x
}
```

<!--
Now a more interesting case.
We're on `@MainActor`, and we call `await f(x)` where `f` runs on a different actor.

Since `x` is NonSendable, it gets transferred by crossing the actor isolation boundary.
The red box shows `Γ subtract x`, which means `x` is removed from the original input environment.
So, any attempt to use `x` afterward will be a compile error.

17:45
-->

---

<!--
_class: small-code
-->

## Key Rules: Variables

**Access-only variable rule**:

$$\dfrac{x : T \;\textbf{at}\; ρ \in Γ \qquad \fcolorbox{red}{transparent}{$ρ \in \text{accessible}(@κ)$}}{Γ;\; @κ;\; α \;⊢\; x : T \;\textbf{at}\; ρ \;⊣\; Γ} \quad \small{\text{(var)}}$$

$\scriptsize{\text{accessible}(@κ) : \mathcal{P}(\text{Regions})}$
$\scriptsize{\text{accessible}(@\texttt{nonisolated}) = \{ \texttt{disconnected},\; \texttt{task},\; \_ \}}$
$\scriptsize{\text{accessible}(@\texttt{isolated}(a)) = \{ \texttt{disconnected},\; \texttt{isolated}(a),\; \texttt{task},\; \_ \}}$
$\scriptsize{T:\text{Sendable} \Leftrightarrow (ρ=\_) \quad \text{(normal form in } Γ\text{)}}$

<!--
Now, let's take a look at the actual typing rules.

The first one is the "variable" access rule.
It looks normal, but notice the red box.
There's an extra check, which means, the current capability κ must be allowed to access the variable's region ρ.

For example, a nonisolated context can access disconnected values, but not those in actor-isolated regions.

18:15
-->

---

<!--
_class: small-code
-->

## Key Rules: Transfer & Merge

**call-nonsendable-consume** — cross-isolation consumption:

$$\dfrac{\begin{gathered}f : @σ\; @ι\; (A) \;\alpha \to B \qquad arg : A \;\textbf{at}\; \texttt{disconnected} \in Γ_2 \\ A : \mathord{\sim}\text{Sendable} \qquad B : \text{Sendable} \qquad @κ \neq @ι\end{gathered}}{Γ;\; @κ;\; \texttt{async} \;⊢\; \texttt{await}\; f(arg) : B \;\textbf{at}\; \_ \;⊣\; \fcolorbox{red}{transparent}{$Γ_2 \setminus \{arg\}$}} \quad \small{\text{(call-nonsendable-consume)}}$$

**region-merge** — e.g. binding via assignment:

$$\dfrac{\begin{gathered}Γ;\; @κ;\; α \;⊢\; e_1 : T_1 \;\textbf{at}\; ρ_1 \;⊣\; Γ_1 \qquad Γ_1;\; @κ;\; α \;⊢\; e_2 : T_2 \;\textbf{at}\; ρ_2 \;⊣\; Γ_2 \\ T_1,T_2 : \mathord{\sim}\text{Sendable} \qquad ρ_1,ρ_2 \in ρ_{ns} \qquad ρ = ρ_1 ⊔ ρ_2\end{gathered}}{Γ;\; @κ;\; α \;⊢\; (e_1.\text{field} = e_2) : () \;\textbf{at}\; \_ \;⊣\; \fcolorbox{red}{transparent}{$Γ_2[ρ_1 \mapsto ρ,\; ρ_2 \mapsto ρ]$}} \quad \small{\text{(region-merge)}}$$

*Cross-isolation shrinks* $Γ$. *Region-merge refines* it.

<!--
Next, here are two rules that modify the typing environment.

The first rule shows, what happens when a NonSendable value crosses isolation via `await`:
the value is consumed, and Γ shrinks.

The second rule, region-merge, shows what happens on assignment:
Two regions are joined, and Γ is refined.

18:45
-->

---

<!--
_class: small-code
-->

## Key Rules: Closures — Isolation Inference

**Non-@Sendable** — closure inherits parent's capability $@κ$:

$$\dfrac{\begin{gathered}Γ_{\text{cap}} \subseteq Γ \\ Γ_{\text{cap}};\; \mathbf{@κ};\; α' \;⊢\; e : B \;\textbf{at}\; ρ_{\text{ret}} \;⊣\; Γ'_{\text{cl}}\end{gathered}}{Γ;\; @κ;\; α \;⊢\; \{e\} : \fcolorbox{red}{transparent}{$@κ \; () \; α' \!\to B$} \;\textbf{at}\; ρ_{\text{closure}} \;⊣\; Γ} \quad \small{\text{(closure-inherit-parent)}}$$

**@Sendable** — No inheritance, uses $@ι$ instead:

$$\dfrac{\begin{gathered}Γ_{\text{cap}} \subseteq Γ \qquad \text{isAllSendable}(Γ_{\text{cap}}) \\ @κ_{\text{cl}} = \text{toCapability}(@ι) \\ Γ_{\text{cap}};\; \mathbf{@κ_{\text{cl}}};\; α' \;⊢\; e : B \;\textbf{at}\; ρ_{\text{ret}} \;⊣\; Γ'_{\text{cl}}\end{gathered}}{Γ;\; @κ;\; α \;⊢\; \{e\} : \fcolorbox{red}{transparent}{$\text{@Sendable}\; @ι \; () \; α' \!\to B$} \;\textbf{at}\; \_ \;⊣\; Γ} \quad \small{\text{(closure-no-inherit-parent)}}$$

<!--
This slide is about "closure isolation inferences".

For a non-`@Sendable` closure, it "inherits" its parent's capability κ.
And this is why closures usually "just work" inside the same actor.

But `@Sendable` closure does "NOT" inherit — its body capability is derived from its own annotation.
So, a plain `@Sendable` closure normally becomes "nonisolated", which is exactly why the first example of this talk fails.

19:15
-->

---

<!--
_class: small-code
-->

## Key Rules: Closures — `sending` Capture

**transfer case** — consumes NonSendable captures:

$$\dfrac{\begin{gathered}f : (\texttt{sending}\; (@κ_{\text{cl}} () \; α' \!\to T)) \to () \qquad Γ_{\text{cap}} \subseteq Γ \\\neg(\cdots \land \texttt{isActorIsolated}(@κ) \land @κ_{\text{cl}} = @κ) \qquad \cdots \\ Γ_{\text{cap}};\; @κ_{\text{cl}};\; α' \;⊢\; e : T \;\textbf{at}\; ρ_{\text{ret}} \;⊣\; Γ'_{\text{cl}} \\ Γ' = Γ \setminus \{x \mid (x : U\;\textbf{at}\; \texttt{disconnected}) \in Γ_{\text{cap}},\; U : \mathord{\sim}\text{Sendable}\}\end{gathered}}{Γ;\; @κ;\; α \;⊢\; f(\{e\}) : () \;\textbf{at}\; \_ \;⊣\; Γ'} \quad \small{\text{(closure-sending-consume)}}$$

```swift
func transferCase() {
  let y = NonSendable()
  Task.detached { _ = y.value }
  // _ = y.value  // ❌ transferred / race risk
}

@MainActor func sameActor() {
  let x = NonSendable()
  Task { _ = x.value }
  _ = x.value   // ✅ same-actor Task.init keeps access
}
```

<!--
And lastly, here is the "closure sending" rule.
When a closure is passed as a `sending` parameter and the compiler cannot prove the same actor context,
`NonSendable` captures in the disconnected region will be consumed.

`Task.detached` is the best example.
On the other hand, `Task.init` runs within a same-actor isolation, so it will actually follow with a different typing rule.

19:30
-->

---

<img src="assets/paper-intro.png" style="width:calc(100% - 80px);height:calc(100% - 160px);object-fit:cover;object-position:top;display:block;margin:0 auto;border:1px solid #555;box-shadow:2px 2px 10px rgba(0,0,0,0.3);">

<br>

https://github.com/inamiy/swift-concurrency-type-system

<!--
As I don't have much time left to explain all rules, I will skip the rest of this topic for now.

For more information, please refer to this GitHub URL which I open-sourced today.
Please also check my "AI vibe-paper" in this repository if you are interested.

19:45
-->

---

## Recap (Formalization)

$$\huge Γ;\; @κ;\; α \;⊢\; e : T \;\textbf{at}\; ρ \;⊣\; Γ'$$

| Component | Role | Details |
|-----------|------|---------|
| $@κ$ | WHERE code **runs** | `@nonisolated`, `@MainActor`, ... |
| $ρ$ | WHERE data **lives** | $\texttt{disconnected} \to \texttt{isolated}(a)$ |
| $Γ \to Γ'$ | **Affine** discipline | Merge refines, transfer shrinks |

<!--
To recap about this type-system topic... Capability, Region, and Affine Type System.
These are the 3 keys to deep-dive into Swift Concurrency Type System.

20:00
-->

---

# Wrap Up

1. Swift Concurrency = **Capability × Region**
   - `@κ`: where code runs / `ρ`: where data lives
   - Covers the mystery of closure conversion rules

2. `sending` = **Affine transfer** (in many cases)
   - Precondition: `x : T at disconnected`
   - Effect: $Γ' = Γ \setminus \{x\}$ (use-after-send is rejected)

3. Region Merge = **Context $Γ$ refinement**
   - e.g. `disconnected ⊔ isolated(a) = isolated(a)`

<!--
And, to wrap up:
We started with a simple question — "Why doesn't this Swift Concurrency code compile?" —
and we ended up exploring its "core rules" in depth.

Yes, Swift Concurrency is indeed a very deep topic.
But that depth is what makes Swift "powerful".
Unlike many other programming languages that rely on runtime locks or just wishes for the best,
Swift can guarantee lock-free, data-race safety at compile time.

This is really awesome and rare feature to see in mainstream programming languages,
and I believe it's worth the learning curve.

I hope this talk gave you some new insights to reason about Swift Concurrency.

21:00
-->

---

<!--
_class: small-text
-->

## References

- Swift Evolution
  - [SE-0414: Region-based Isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md)
  - [SE-0430: `sending` parameter and result values](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md)
  - [SE-0431: `@isolated(any)` function types](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md)
  - [SE-0461: Run nonisolated async functions on the caller's actor](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md)
- Papers
  - [Tofte & Talpin (1994), Region-Based Memory Management](https://web.cs.ucla.edu/~palsberg/tba/papers/tofte-talpin-iandc97.pdf)
  - [Walker, Crary & Morrisett (2000), Typed Memory Management via Static Capabilities](https://dl.acm.org/doi/10.1145/363911.363923)
  - [Walker & Watkins (2001), On Regions and Linear Types](https://dl.acm.org/doi/10.1145/507669.507658)
  - [Grossman et al. (2002), Region-Based Memory Management in Cyclone](https://dl.acm.org/doi/10.1145/512529.512563)
  - [Charguéraud & Pottier (2008), Functional Translation of a Calculus of Capabilities](https://dl.acm.org/doi/10.1145/1411203.1411235)
  - [Milano, Turcotti & Myers (2022), A Flexible Type System for Fearless Concurrency](https://dl.acm.org/doi/10.1145/3519939.3523443)

<!--
And that's all for my talk.
Thank you very much for listening, and please enjoy the rest of try! Swift Tokyo.
-->
