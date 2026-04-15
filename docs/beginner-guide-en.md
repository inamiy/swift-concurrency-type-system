# Type Theory Beginner Guide (English)

This document is a minimal introduction for readers who are seeing the notation of logic and type theory for the first time.
The goal is not to study proof theory systematically, but to help you keep reading without stopping when you see symbols such as `Γ` or `⊢`.

## 1. The Basic Shape

In type theory documents, the following form appears frequently:

```text
Γ ⊢ e : T
```

This is a judgment, read as "under the context `Γ`, the expression `e` has type `T`."
The meaning of each symbol is as follows:

- `Γ` (Gamma): a context / environment listing the variables currently available and their types
- `e`: expression
- `T`: type
- `⊢`: turnstile. It means "under these assumptions, this judgment is derivable"
- `:`: "this expression has this type"

For example, if `Γ` contains `x : Int`, then `x` can be read as an `Int`,
so we can write `Γ ⊢ x : Int`.

## 2. What Is `Γ`?

You can think of `Γ` as a box that collects "what may currently be assumed."
Its contents are bindings like the following:

```text
Γ = x : Int, y : Bool
```

In this case, inside `Γ`, you may use `x` as an `Int` and `y` as a `Bool`.

For programmers, an intuitive picture is that `Γ` is the compiler's
"dictionary from names to types" at that point.
For this beginner guide, it is easiest to see it first as a `name -> type` mapping.

Consider the following Swift function:

```swift
func example() {
    let count = 42
    let title = "hello"
    let isReady = true

    _ = (count, title, isReady)
}
```

If we focus only on the essence, we can think of the compiler as conceptually holding a dictionary like this:

```text
Γ = {
  count : Int,
  title : String,
  isReady : Bool
}
```

Here, `{` and `}` are symbols for enclosing the contents of a set.

In other words, `Γ` represents "which names are available at this program point, and with which types."
In ordinary introductory type systems, `Γ` is often used as a fixed assumption,
so it does not change as you move to the next line or the next expression.
On the other hand, some systems allow `Γ` to change after each expression is processed,
and that perspective leads to the affine type system discussed later.

## 3. Premise and Conclusion

Typing rules are usually written as inference rules in the following shape:

```text
premise 1    premise 2
────────────────────── (rule-name)
conclusion
```

Above the horizontal line are the premises, and below it is the conclusion.
The reading is simple: "if all premises above hold, then the conclusion below may be derived."

The `(rule-name)` at the end is the rule name, a label used to refer to the rule later.

## 4. Simply Typed Lambda Calculus

You can think of simply typed lambda calculus as the minimal model of typed functions.
Here, it is enough to understand just three pieces.

### 4.1 Variable

```text
x : T ∈ Γ
────────── (var)
Γ ⊢ x : T
```

If the binding `x : T` is contained in `Γ`, then in the current context
the name `x` may be evaluated / referenced / used as an expression,
and its resulting type is `T`.
So the `var` rule is the most basic rule: "a declared name may be used according to its type."
Here, `∈` is the set-theoretic symbol meaning "... is an element of ...".

### 4.2 Lambda Abstraction

```text
Γ, x : A ⊢ e : B
──────────────────────── (abs)
Γ ⊢ λx : A. e : A → B
```

Suppose we check the body `e` under the assumption that `x` has type `A`,
and the result has type `B`.
Then the function `λx : A. e` has type `A → B`.

Here, `λ` is the lambda symbol.
You can think of it as meaning "construct an anonymous function."
Roughly speaking, `λx : A. e` represents "a function that takes an argument `x` and returns the body `e`."

Reading it piece by piece:

- `λ`: a marker that says "we are constructing a function now"
- `x : A`: the argument `x` has type `A`
- `.`: the separator between the argument declaration and the body
- `e`: the body of the function
- `A → B`: the type of the whole function, taking `A` and returning `B`

`A → B` is read as "the function type from `A` to `B`."
That is, it means "a function whose input is `A` and whose output is `B`."
In Swift, this corresponds to `(A) -> B`.

The closest intuition in Swift is a closure.
For example,

```text
λx : Int. x + 1
```

is conceptually close to the following closure in Swift:

```swift
let f: (Int) -> Int = { (x: Int) in
    x + 1
}
```

In other words, lambda abstraction in simply typed lambda calculus is quite close to
"an unnamed function value" or a "closure literal" in Swift.
Of course, Swift has additional elements such as capture, effect, and ownership,
but as a beginner's entry point it is reasonable to think of "`λ` as the notation for writing a closure."

### 4.3 Application

```text
Γ ⊢ f : A → B    Γ ⊢ a : A
─────────────────────────── (app)
Γ ⊢ f a : B
```

If the function `f` has type `A → B`, and the argument `a` has type `A`,
then the application `f a` has type `B`.

If you can read these three rules, you can usually follow the first few pages of many type theory texts.

## 5. Common Technical Terms

- judgment: a statement that holds under certain assumptions
- context / environment: a collection of assumptions about variables and their types
- premise: an assumption appearing above a rule
- conclusion: what appears below a rule
- derivation: obtaining a conclusion by stacking rules
- metavariable: a symbol such as `Γ`, `e`, `T`, `A`, or `B` that represents "a place where something goes," rather than a concrete piece of syntax itself

## 6. Minimum Reading Summary

If you remember only the following three points, that is enough as a beginner's starting point.

1. `Γ ⊢ e : T` means "under `Γ`, `e` has type `T`."
2. Above the horizontal line are the premises, and below it is the conclusion.
3. The horizontal line represents a rule of the form "derive the conclusion below from the premises above."

If you understand this far, then even in more complex type-system documents you can at least start reading without getting stuck on the symbols themselves.

## 7. A Sneak Peek at `docs/typing-rules-en.md`

So far, we focused on the simple picture where `Γ` is
"the compiler's `name -> type` dictionary at the current point."
However, in `docs/typing-rules-en.md`, the English translation of the main text in this repository,
we go one step further and track how that dictionary **changes after each expression is read**.

So the shape of the judgment becomes a little richer:

```text
Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'
```

Here, `Γ` is the input environment "before reading the expression," and `Γ'` is the output environment "after reading the expression."
The symbol `⊣` (Unicode name `LEFT TACK`, written as `\dashv` in LaTeX) separates those two sides,
and can be read as "processing the expression on the left yields the environment on the right."
In other words, the notation directly exposes how the compiler's dictionary is updated line by line.

To build the intuition for that, Swift Ownership is easier to understand than Swift Concurrency.
For example, when a NonCopyable value is passed to a `consuming` parameter,
the caller can no longer use that value afterward.

```swift
struct Token: ~Copyable {}

func take(_ token: consuming Token) {}

func example() {
    let token = Token()
    take(token)
    // _ = token // ❌ already consumed
}
```

Intuitively, we can think of the compiler's dictionary as changing like this:

```text
Γ₀ = { token : Token }
Γ₀ ⊢ take(token) ⊣ Γ₁
Γ₁ = Γ₀ \ { token : Token }
```

Here, `\` represents set difference.
So `Γ₀ \ { token : Token }` means "remove the binding `token : Token` from `Γ₀`."

At first, `token` is present in the dictionary, but after ownership is transferred,
`token` can no longer be reused as-is,
so `token` disappears from the output-side `Γ₁`.
This property, where "using a value may shrink the environment," is the entry point to the **Affine Type System**
that appears in `docs/typing-rules-en.md`.

In the main document, this intuition is tracked more formally,
extending it to Swift Concurrency's `sending`, region, and isolation.
That is, the shape we saw in ownership,
"once consumed, it disappears from the environment,"
reappears in the concurrency rules as well.

This beginner guide stops at that sneak peek.
In the main document, we will write down this `Γ → Γ'` change formally, rule by rule.

## 8. How to Learn More

If you can read this document and want to study type theory a little more systematically,
the following order is recommended:

1. [Swift and Logic, and Category Theory](https://speakerdeck.com/inamiy/swift-and-logic-and-category-theory)
   Slides for understanding the connection between Swift and logic (you can skip the category theory part).
2. Ask AI about keywords such as "symbolic logic" or "typed lambda calculus,"
   and read PDF materials or lecture notes written by experts while using AI as a discussion partner.
3. *Types and Programming Languages* (Benjamin C. Pierce)
   The standard introductory book on typed languages. It is an excellent first full-length book for seriously learning typing rules, operational semantics, and type safety.
4. *Advanced Topics in Types and Programming Languages* (Benjamin C. Pierce)
   The advanced follow-up to *Types and Programming Languages*. Topics such as affine types and regions, which are relevant for understanding Swift Concurrency, appear here.

If you are going to buy one first serious book on the subject, *Types and Programming Languages* is the most natural starting point.
