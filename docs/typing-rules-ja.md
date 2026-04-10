# Swift Concurrency as Capability + Region Type System (Japanese)

本ドキュメントは Swift 6.2 Concurrency の型付け規則を体系的にまとめたものである。

> 重要: isolation を含む関数型変換 (sync/async) の ground truth は必ず次を参照すること:
> - `swift/Sources/concurrency-type-check/FuncConversionRules.swift`
> - `docs/diagrams/func-conversion-rules.mmd`

## Table of Contents

<!-- START ToC -->

- [1. 判定形式 (Judgment)](#1-判定形式-judgment)
  - [1.1 Swift への接続 (function/task body)](#11-swift-への接続-functiontask-body)
- [2. 記号と補助定義 (Definitions)](#2-記号と補助定義-definitions)
  - [2.1 Capability (`@κ`) と関数型 Annotation (`@φ`)](#21-capability-κ-と関数型-annotation-φ)
    - [Capability (`@κ`)](#capability-κ)
    - [関数型 Annotation (`@φ = @σ @ι`)](#関数型-annotation-φ--σ-ι)
    - [`@ι` から capability `@κ` への変換 (`toCapability`)](#ι-から-capability-κ-への変換-tocapability)
    - [Actor Isolation 判定 (`isActorIsolated`)](#actor-isolation-判定-isactorisolated)
  - [2.2 Region (`ρ`)](#22-region-ρ)
    - [正規形条件](#正規形条件)
  - [2.3 Region Access (`accessible(@κ)`)](#23-region-access-accessibleκ)
  - [2.4 Region Merge (`ρ₁ ⊔ ρ₂`)](#24-region-merge-ρ--ρ)
  - [2.5 Capability → Region 変換 (`toRegion(@κ)`)](#25-capability--region-変換-toregionκ)
  - [2.6 クロージャ補助定義 (`@Sendable` / isolation inference)](#26-クロージャ補助定義-sendable--isolation-inference)
    - [`@Sendable` capture 制約 (`isAllSendable`)](#sendable-capture-制約-isallsendable)
    - [Closure Isolation Inference](#closure-isolation-inference)
      - [`inheritActorContext`](#inheritactorcontext)
      - [`isPassedToSendingParameter`](#ispassedtosendingparameter)
    - [Isolation inference boundary 判定 (親の isolation を継承しない)](#isolation-inference-boundary-判定-親の-isolation-を継承しない)
      - [Actor-instance capture requirement (`capturesIsolatedParam`)](#actor-instance-capture-requirement-capturesisolatedparam)
      - [Actor-instance isolation の実効 capability (`effectiveClosureCapability`)](#actor-instance-isolation-の実効-capability-effectiveclosurecapability)
    - [Capture 可否 (`capturable(@κ)`)](#capture-可否-capturableκ)
    - [`@concurrent` closure literal](#concurrent-closure-literal)
  - [2.7 Send 可否判定 (`canSend`)](#27-send-可否判定-cansend)
    - [`[sending]` の定義](#sending-の定義)
    - [`canSend`](#cansend)
  - [2.8 Sendable Inference 補助定義 (SE-0418)](#28-sendable-inference-補助定義-se-0418)
  - [2.9 Isolation Subtyping / Coercion (`isoSubtyping`, `isoCoercion`)](#29-isolation-subtyping--coercion-isosubtyping-isocoercion)
- [3. 同期・非同期境界 (Sync/Async Boundaries)](#3-同期非同期境界-syncasync-boundaries)
  - [3.1 async 関数本体 (`α` の導入境界)](#31-async-関数本体-α-の導入境界)
    - [decl-fun-isolated-param](#decl-fun-isolated-param)
    - [decl-fun-isolation-inheriting](#decl-fun-isolation-inheriting)
  - [3.2 `Task { ... }` / `Task.detached { ... }` 本体](#32-task-----taskdetached----本体)
- [4. 関係規則 (Relation Rules)](#4-関係規則-relation-rules)
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
- [5. 型付け規則 (Typing Rules)](#5-型付け規則-typing-rules)
  - [5.1 変数 (Variables)](#51-変数-variables)
    - [var](#var)
  - [5.2 シーケンス (Sequencing)](#52-シーケンス-sequencing)
    - [seq](#seq)
  - [5.3 関数型変換 (Function Type Conversion)](#53-関数型変換-function-type-conversion)
    - [sync-to-async](#sync-to-async)
    - [func-conv](#func-conv)
    - [isolated-any-to-async](#isolated-any-to-async)
    - [Subtyping / Coercion 検証テーブル](#subtyping--coercion-検証テーブル)
    - [Closure wrapping による変換](#closure-wrapping-による変換)
  - [5.4 Region マージ (Aliasing / Assignment)](#54-region-マージ-aliasing--assignment)
    - [region-merge](#region-merge)
  - [5.5 関数呼び出し (Calls)](#55-関数呼び出し-calls)
    - [call-nonsendable-noconsume](#call-nonsendable-noconsume)
      - [noconsume の例: 同一具体 actor + sending](#noconsume-の例-同一具体-actor--sending)
      - [noconsume vs consume (Same vs Cross)](#noconsume-vs-consume-same-vs-cross)
      - [`call-same-nonsendable-merge` との違い (bind vs no-bind)](#call-same-nonsendable-merge-との違い-bind-vs-no-bind)
    - [call-nonsendable-consume](#call-nonsendable-consume)
      - [コンパイラとの対応](#コンパイラとの対応)
      - [consume の例: nonisolated + sending](#consume-の例-nonisolated--sending)
      - [consume の例: cross-isolation 暗黙 sending](#consume-の例-cross-isolation-暗黙-sending)
      - [consume の例: cross-isolation 明示 sending](#consume-の例-cross-isolation-明示-sending)
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
    - [補足説明](#補足説明)
      - [call-isolated-param-semantics](#call-isolated-param-semantics)
      - [call-isolation-macro-semantics](#call-isolation-macro-semantics)
  - [5.6 `@isolated(any)`](#56-isolatedany)
    - [isolated-any-isolation-prop (`f.isolation`)](#isolated-any-isolation-prop-fisolation)
  - [5.7 クロージャ (Closures)](#57-クロージャ-closures)
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
- [6. 例 (Examples)](#6-例-examples)
  - [例 1: 同一 isolation (nonsending は束縛、消費しない)](#例-1-同一-isolation-nonsending-は束縛消費しない)
  - [例 2: 同一 isolation (`sending` は消費しない — Same vs Cross)](#例-2-同一-isolation-sending-は消費しない--same-vs-cross)
  - [例 3: 異なる isolation (implicit transfer は消費)](#例-3-異なる-isolation-implicit-transfer-は消費)
  - [例 4: 異なる isolation (explicit `sending` は消費)](#例-4-異なる-isolation-explicit-sending-は消費)
  - [例 5: `Task` capture (same-actor `Task.init` は保持、それ以外は consume)](#例-5-task-capture-same-actor-taskinit-は保持それ以外は-consume)
  - [例 6: nonisolated async 引数は `task` 的に振る舞う (SE-0461)](#例-6-nonisolated-async-引数は-task-的に振る舞う-se-0461)
  - [例 7: `@isolated(any)` 呼び出しは sync 形でも `await` が必要 (SE-0431)](#例-7-isolatedany-呼び出しは-sync-形でも-await-が必要-se-0431)
  - [例 8: `isolated` パラメータ — sync access + cross-isolation await (SE-0313)](#例-8-isolated-パラメータ--sync-access--cross-isolation-await-se-0313)
  - [例 9: Cross-isolation NonSendable result without `sending` → error](#例-9-cross-isolation-nonsendable-result-without-sending--error)
  - [例 10: `#isolation` で `@Sendable` 不要 + `inout` アクセス (SE-0420)](#例-10-isolation-で-sendable-不要--inout-アクセス-se-0420)
  - [例 11: Nonisolated sync — “callable from” ≠ “convertible to” (call vs capture)](#例-11-nonisolated-sync--callable-from--convertible-to-call-vs-capture)

<!-- END ToC -->

---

## 1. 判定形式 (Judgment)

線形型システムの慣習に倣い、出力文脈を明示する:

```text
Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'
```

- `Γ` / `Γ'`: 型環境 (入力 / 出力)。要素は `x : T at ρ`。
- `@κ`: capability (実行コンテキストの isolation)。
- `α`: async mode (`await` が書けるか)。
- `ρ`: value region (NonSendable のエイリアス集合 / あるいは `_`)。

```text
α ::= sync | async
sync ⊑ async
```

### 1.1 Swift への接続 (function/task body)

Swift の関数本体や `Task` operation は statement block だが、本書では (一般的な型理論の慣習として)
それらを **式へ lowering した `body`** を対象として規則を書く。

また、Swift の `func` は本体系の「式」ではなく **宣言**である。
したがって本体系の主要判定 `Γ; @κ; α ⊢ e : ... ⊣ Γ'` に `func` を混ぜない。

ただし Swift への接続としては「宣言の属性が本体の `@κ` / `α` をどう決めるか」を書かないと、
`await` がどこで許されるか (`α` をどこで `async` にするか) が曖昧になる。

そこで本書は、宣言そのものの静的意味 (パラメータ環境形成や name binding 等) は扱わないが、
Swift の宣言が "本体をどのコンテキストでチェックするか" だけを述べる最小限の判定として、
宣言の well-typedness を表す判定 `⊢_d` を用いる (詳細は `decl-fun` 参照):

```text
Δ ⊢_d decl
```

この判定は「`decl` が静的に整合 (well-typed / well-formed) である」という命題 (true/false) を表す。
すなわちこの最小版では、宣言の判定は型や環境の出力を返さない (必要なら将来 `Δ ⊢ decl ⊣ Δ'` のように拡張できる)。

ここで `Δ` は「プログラム側の宣言環境 (どの名前が外側で使えるか)」を表す。
本書の式の判定 `Γ; @κ; α ⊢ e : ... ⊣ Γ'` も本来は `Δ` に相対的だが、以降は記法を簡潔にするため `Δ` を省略する。

Note: `⊢_d` は「`⊢` の別記号」ではなく、`⊢` の右側が "decl の整合性" を述べる **別の判定形式 (judgment form)**であることを明示するためのラベルである。
TAPL でも `Γ ⊢ t : T` (型付け) だけでなく `Γ ⊢ t =_{ctx} t' : T` (文脈同値) など、同じ `⊢` の下に複数の判定形式を並立させるのが一般的である。

---

## 2. 記号と補助定義 (Definitions)

### 2.1 Capability (`@κ`) と関数型 Annotation (`@φ`)

本書では、判定形式の第 2 要素 (実行コンテキストの isolation) と関数型の属性注釈を**文法レベルで分離**する。

#### Capability (`@κ`)

`@κ` は「現在の実行コンテキストがどの isolation domain にいるか」を表す:

```text
@κ ::= @nonisolated | @isolated(a)

a  ::= globalActor | localActor
```

略記: `@MainActor ≡ @isolated(MainActor)`。ここで `MainActor` は `globalActor` の一例である。

#### 関数型 Annotation (`@φ = @σ @ι`)

関数型に付く属性注釈を `@φ` で表す:

```text
@σ ::= ·          (@Sendable なし)
    | @Sendable   (明示 @Sendable)

@ι ::= @κ
   | @isolated(any)
   | @concurrent         (async のみ)

@φ ::= @σ @ι
```

以降で用いる射影:

```text
proj_σ(@φ) = @σ
proj_ι(@φ) = @ι
```

#### `@ι` から capability `@κ` への変換 (`toCapability`)

`decl-fun` 等で関数の `@ι` から body の capability を決定する:

```text
toCapability : @ι → @κ

toCapability(@κ)             = @κ              (@κ ⊆ @ι なのでそのまま)
toCapability(@isolated(any)) = @nonisolated
toCapability(@concurrent)    = @nonisolated
```

Note: `@concurrent` は async 関数型にのみ現れる "明示的 nonisolated" を表し、`@Sendable` とは独立である。
SE-0461 の観点では次の対応になる:

| 型 (略記) | SE-0461 Formal Name | 実行セマンティクス (要約) |
|---|---|---|
| `normal sync` | `nonisolated` | caller executor 上 (no switch) |
| `normal async` | `nonisolated(nonsending)` | caller actor 上 (no switch, sync に近い) |
| `@concurrent async` | `@concurrent` (explicit) | actor から降りる (switch OFF actor) |

**重要**: `normal async` と `@concurrent async` の差は、主に

- **call-site の sendability / region 条件** (`@concurrent` は actor から降りるため、actor-capable な文脈から呼ぶと `Sendable` もしくは `disconnected` を要求する)
- **実行セマンティクス** (`normal async` は caller actor を継承、`@concurrent async` は actor から降りる)

にある (SE-0461: `swiftlang/swift-evolution/proposals/0461-async-function-isolation.md`)。

一方で **closure isolation inference の規則自体は `@concurrent` で変わらない** (SE-0461 "Isolation inference for closures")。
文脈型が `@Sendable` / `sending` でない限り、閉包は外側の隔離を継承し得る。
そのうえで `@concurrent` が要求される場合は、**関数型変換 (thunk 生成)**で整合させる (SE-0461 "Function conversions")。

Q. `@concurrent` は `@ι` に含めてよいか？

A. 含めてよい。ただし `@concurrent` は **async 関数型にのみ現れる**点と、`@nonisolated async` (= `nonisolated(nonsending)`) とは
**「actor を継承する (nonsending) / actor から降りる (@concurrent)」**が異なる点を、規則で明示する必要がある (後述 `call-concurrent-*`)。

本書では `@concurrent` の "actor identity の有無" は `@nonisolated` と同じ (= 特定 actor を持たない) として扱う。
Access / capture 可否では `toCapability(@concurrent) = @nonisolated` により capability は `@nonisolated` となる。
`@concurrent` の switch-off セマンティクス (call-site の sendability / region 条件) は `call-concurrent-*` で扱う。

**コンパイラ根拠**: Swift コンパイラの `getIsolationFromAttributes()` (`TypeCheckConcurrency.cpp`) は、
`@concurrent` を isolation 決定の最初期段階で `Nonisolated` に変換する:

```cpp
// @concurrent → Nonisolated(actor identity なし)
if (concurrentAttr)
    return ActorIsolation::forNonisolated(/*is unsafe*/ false);
```

対比として、SE-0461 の `nonisolated(nonsending)` は `CallerIsolationInheriting` (caller の isolation を実行時に継承) として扱われる:

```cpp
if (nonisolatedAttr->isNonSending())
    return ActorIsolation::forCallerIsolationInheriting();
```

| Swift 構文 | コンパイラ内部 | body の `@κ` |
|---|---|---|
| `@concurrent async` | `Nonisolated` | `@nonisolated` |
| `nonisolated(nonsending) async` | `CallerIsolationInheriting` | `@nonisolated` |
| `@MainActor` | `GlobalActor(MainActor)` | `@isolated(MainActor)` |

いずれも body の型チェック上は `@κ ∈ { @nonisolated, @isolated(a) }` に帰着する。
`@concurrent` と `nonisolated(nonsending)` の差は call-site セマンティクス (`call-concurrent-*` vs [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit)) にのみ現れる。

#### Actor Isolation 判定 (`isActorIsolated`)

```text
isActorIsolated(@κ) ⟺ @κ ∉ { @nonisolated }
```

`@κ` が具体的な actor isolation (例: `@MainActor`, `@isolated(a)`) を持つかを判定する述語。
`@nonisolated` は特定の actor に属さないため偽となる。
[`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume) の消費判定条件 `isActorIsolated(@κ) ∧ @κ = @ι` で使用する。

### 2.2 Region (`ρ`)

```text
// ns = non-sendable
ρ_{ns} ::= disconnected
        | isolated(a)
        | task
        | invalid  (導出不能 / コンパイルエラー)

ρ ::= ρ_{ns}
   | _           (Sendable 用)
```

`disconnected` は「どこからでもアクセス可能」ではなく「**まだどの isolation domain にも束縛されていない**」を表す (束縛は merge/bind で起きる)。
[`region-merge`](#region-merge) の merge 演算 `⊔` の定義域は `ρ_{ns}` に限定する。

`_` は Sendable 値の正規タグであり、`⊔` の定義域には含めない。

#### 正規形条件

`Sendable` 値と region `_` の対応は、個別の式規則とは切り離して環境の正規形条件として与える:

```text
∀ (x : T at ρ) ∈ Γ.  (T : Sendable ⇔ (ρ = _))
```

以降、式の判定 `Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'` は、入力環境 `Γ` がこの正規形条件を満たすことを暗黙に仮定する。
また、環境を更新する規則は更新後の環境も同じ正規形条件を保つように設計する。

### 2.3 Region Access (`accessible(@κ)`)

`accessible(@κ)` は「capability `@κ` のもとで **直接アクセス可能な region の集合**」を返す:

```text
accessible(@κ) : P(Regions)

accessible(@nonisolated) = { disconnected, task, _ }
accessible(@isolated(a)) = { disconnected, isolated(a), task, _ }
```

`ρ ∈ accessible(@κ)` が「capability `@κ` で region `ρ` の値にアクセスできる」ことを表す。

`disconnected` はどの isolation からもアクセス可能であり、すべての `@κ` に対して `disconnected ∈ accessible(@κ)` が成り立つ。

Note: `isolated(a) ∈ accessible(@isolated(a))` は同じ actor の場合のみ成り立つ。

### 2.4 Region Merge (`ρ₁ ⊔ ρ₂`)

`ρ₁ ⊔ ρ₂` は region マージ (SE-0414) を表す。定義域は `ρ_{ns} × ρ_{ns}` で、最小限、次の表で与える:

| ρ₁ | ρ₂ | ρ₁ ⊔ ρ₂ |
|---|---|---|
| disconnected | disconnected | disconnected |
| disconnected | isolated(a) | isolated(a) |
| disconnected | task | task |
| isolated(a) | isolated(a) | isolated(a) |
| isolated(a) | isolated(b) | invalid (a ≠ b) |
| isolated(a) | task | invalid |
| task | task | task |

`invalid` は「導出不能 (Swift ではコンパイルエラー)」を表す **拡張 region** であり、merge 演算を total / closed に保つために `ρ_{ns}` に含めて扱う。

**Semilattice 構造**: `⊔` は以下の順序に対する join (上限) を与える join-semilattice を形成する:

```text
       invalid (⊤)
      /       \
isolated(a)   task
      \       /
    disconnected (⊥)
```

- `disconnected` は `ρ_{ns}` の bottom (`disconnected ⊔ ρ = ρ` for all `ρ ∈ ρ_{ns}`)。
- `_` は join の要素ではなく、正規形条件 `T : Sendable ⇔ ρ = _` により Sendable 値にのみ割り当てる。
- したがって、クロージャの region 計算 (`ρ_{closure} = ⨆{...}`) などでの join は NonSendable capture のみを対象とし、空 join は `disconnected` となる。
- `invalid` は extended domain 上の top であり、「この merge / refinement は失敗状態を表している」という compact な記法として使う。

### 2.5 Capability → Region 変換 (`toRegion(@κ)`)

[`call-same-nonsendable-merge`](#call-same-nonsendable-merge) の「束縛」を、capability と region の混線なしに書くための関数:

```text
toRegion(@κ) : ρ_{ns}

toRegion(@isolated(a)) = isolated(a)
toRegion(@nonisolated)  = disconnected
```

意図: 同一 isolation で NonSendable を引き回したときに「束縛され得る」のは、**具体 actor が静的に分かる場合**だけに限定する (`@nonisolated` では束縛しない)。

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_merge_thenCrossSend_isError()` (`@MainActor` では束縛され、以後 `sending` 転送できなくなる)

```swift
@MainActor
func bindThenCannotSendExample() async {
    let x = NonSendable() // disconnected
    mainActorUseNonSendable(x) // binds/refines `x` into @MainActor region

    let other = OtherActor()
    // await other.useNonSendableSending(x) // ❌ error: not disconnected (negative test)
}
```

### 2.6 クロージャ補助定義 (`@Sendable` / isolation inference)

#### `@Sendable` capture 制約 (`isAllSendable`)

`@Sendable` は「どこにアクセスできるか」ではなく「何を capture してよいか」を制約する。
closure の capture 環境 `Γ_{captured}` に対して、次の述語を使う:

```text
isAllSendable(Γ_{captured}) : Bool

isAllSendable(Γ_{captured})
  ⇔  ∀ (x : T at ρ) ∈ Γ_{captured}.  T : Sendable
```

`isAllSendable(Γ_{captured})` は [`closure-no-inherit-parent`](#closure-no-inherit-parent) の前提としてのみ使う。
non-`@Sendable` closure はこの制約を受けず、[`closure-inherit-parent`](#closure-inherit-parent) 側で扱う。

#### Closure Isolation Inference

non-`@Sendable` クロージャは親コンテキストの capability `@κ` をそのまま継承する。
`@Sendable` クロージャ (および `sending` に渡されるクロージャ) は isolation inference boundary (親の isolation を継承しない) となり、`@nonisolated` で型チェックされる。

この原則が [`closure-inherit-parent`](#closure-inherit-parent) と [`closure-no-inherit-parent`](#closure-no-inherit-parent) の核心的差異であり、以下の 2 つの meta-rule で述べる。

ここで言う isolation inference boundary は「closure の isolation を親コンテキストから自動で継承して推論する」処理のカットオフを指す。
boundary の場合、closure body の isolation は親ではなく closure 自身の文脈 (contextual type / signature / 明示注釈) から決まる。

##### `inheritActorContext`

```text
inheritActorContext(closure) : Bool
```

closure のパラメータに `@_inheritActorContext` が付いている場合 true。
true の場合、`@Sendable` であっても親の `@κ` を継承する (boundary にならない)。

##### `isPassedToSendingParameter`

```text
isPassedToSendingParameter(closure) : Bool
```

closure が `sending` パラメータに渡されている場合 true。
true の場合、closure は isolation inference boundary となり、capture が消費される ([`closure-sending`](#closure-sending))。

#### Isolation inference boundary 判定 (親の isolation を継承しない)

コンパイラ (`isIsolationInferenceBoundaryClosure()` in `TypeCheckConcurrency.cpp`) は以下の優先順で判定する:

```text
isIsolationInferenceBoundary(closure) : Bool

isIsolationInferenceBoundary(closure) =
  false   if inheritActorContext(closure)                    // @_inheritActorContext が最優先
  true    if isPassedToSendingParameter(closure)             // sending → closure-sending
  true    if closure の contextual type が @Sendable          // → closure-no-inherit-parent
  false   otherwise                                          // → closure-inherit-parent
```

各 closure 規則では `isIsolationInferenceBoundary` を直接使わず、上記の個別述語で条件を明示する。

##### Actor-instance capture requirement (`capturesIsolatedParam`)

```text
capturesIsolatedParam(closure) : Bool
```

closure body が親コンテキストの isolated パラメータ (actor method の暗黙 `self` を含む) を**実際に参照**しているかどうか。
capture list に列挙するだけでは不十分で、body 内に参照 (`_ = self`、`self.state`、`_ = actor` 等) が必要である。

コンパイラ実装: `computeClosureIsolationFromParent()` in `TypeCheckConcurrency.cpp` が `ActorInstance` case で `closureAsFn.getCaptureInfo().getIsolatedParamCapture()` を呼び、isolated パラメータが capture されているかを検査する。

この述語は `@κ = @isolated(localActor)` の場合にのみ意味を持つ。`@κ = @isolated(globalActor)` の場合、isolation は型レベルの性質であり capture の有無に依存しない。

##### Actor-instance isolation の実効 capability (`effectiveClosureCapability`)

non-`@Sendable` closure が親コンテキストから継承する実効 capability を決定する:

```text
effectiveClosureCapability(@κ, closure) : @κ

effectiveClosureCapability(@nonisolated, _)         = @nonisolated
effectiveClosureCapability(@isolated(globalActor), _) = @isolated(globalActor)
effectiveClosureCapability(@isolated(localActor), closure) =
  @isolated(localActor)   if capturesIsolatedParam(closure)
  @nonisolated             otherwise
```

根拠: actor instance への isolation は暗黙の `self` capture を通じて維持されるが、暗黙 capture は参照サイクルを招くため、コンパイラはプログラマに見えない capture を行わない (SE-0461 "Isolation inference for closures" の明文化)。
global actor (`@MainActor` 等) は型レベルの性質であるため capture は不要。

Note: この規則は SE-0306 で導入され (Swift 5.5)、SE-0420 で non-optional binding capture にも拡張された。SE-0461 で初めて形式的に明文化されたが、規則自体は新規ではない。

#### Capture 可否 (`capturable(@κ)`)

`task` region は "この async task に結びついた NonSendable" を表す。
`task` の値を別 actor に結びつくクロージャへ capture すると競合し得るため、本ドキュメントでは capture 可能な region の集合 `capturable(@κ)` を `accessible(@κ)` とは別に定義する。

```text
capturable(@κ) : P(Regions)

capturable(@κ) ⊆ accessible(@κ)

capturable(@nonisolated) = { disconnected, task, _ }
capturable(@isolated(a)) = { disconnected, isolated(a), _ }
```

`accessible` との差は `task` region のみ: `task ∈ accessible(@isolated(a))` だが `task ∉ capturable(@isolated(a))` である。

- `ρ = task` の capture は `@nonisolated` のみ許す (`@isolated(a)` は禁止)
    - NOTE: `@isolated(any)` closure は `toCapability(@isolated(any)) = @nonisolated` で body がチェックされるため、`task ∈ capturable(@nonisolated)` が適用される

これは nonisolated パラメータの実挙動を説明するために必要:

検証 (Swift 6.2):
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

`@concurrent` は async 関数の **実行セマンティクス** (actor から降りる) を指定する属性であり、
closure isolation inference (外側の隔離を継承するか) は SE-0461 の規則どおり **`@Sendable` / `sending` によって決まる**。

したがって、`@MainActor` 文脈で `@concurrent () async -> Void` を要求しても、
閉包が `@Sendable` / `sending` でなければ、閉包自体は `@MainActor` に推論され得る。
その後、代入時に `@concurrent` への **関数型変換 (thunk)**で整合させる (SE-0461 "Function conversions")。

検証 (Swift 6.2):
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

### 2.7 Send 可否判定 (`canSend`)

`~Sendable` 値が send 対象となるかの判定述語。[`call-nonsendable-noconsume`](#call-nonsendable-noconsume) および [`call-nonsendable-consume`](#call-nonsendable-consume) で使用する。

#### `[sending]` の定義

`[sending]` はパラメータに `sending` キーワードが付いているかどうかを表すオプショナルなシンボルである:

```text
[sending] ::= sending      (明示 sending パラメータ)
            | ·             (sending なし)
```

`[sending] ∈ { sending }` は `[sending]` が `sending` に解決された場合に真となる。

#### `canSend`

```text
canSend(@κ, @ι, [sending]) ⟺
    [sending] ∈ { sending }                              (明示 sending パラメータ)
  ∨ (@κ ≠ @ι ∧ @ι ∉ { @nonisolated })                    (暗黙 cross-isolation transfer)
```

Note: `canSend` の暗黙 transfer 側で `@ι ∉ { @nonisolated }` なのは、`nonsending` の `@nonisolated async` は
[`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) で別途扱うためである。
`sending` が明示されていれば `@nonisolated` でも send が発生する。

### 2.8 Sendable Inference 補助定義 (SE-0418)

```text
isNonLocal(f) : Bool

isNonLocal(f) =
  true    if f is a top-level (module-scope) function declaration
  true    if f is a static method declaration
  false   otherwise
```

Note: コンパイラ実装では、トップレベル関数は `DC->isModuleScopeContext()` で判定される。static メソッドはメンバーパスを経由し、metatype の Sendability をチェックするが、metatype は常に `Sendable` であるため結果的に無条件に `@Sendable` となる。

```text
instanceMethods(T) : Set<MethodDecl>

instanceMethods(T) =
  { m | m is an instance method declaration of T }
```

Note: static メソッドは `isNonLocal` に含まれるためここには含めない。コンパイラ実装では `decl->isInstanceMember()` で判別される (TypeOfReference.cpp:1024)。

```text
hasIsolatedKeyPathComponent(kp) : Bool
  — KeyPath のいずれかの component が actor-isolated (ActorInstance or GlobalActor) である場合 true

isAllSendable(captures(kp)) : Bool
  — KeyPath のすべてのキャプチャが Sendable に準拠する場合 true
```

### 2.9 Isolation Subtyping / Coercion (`isoSubtyping`, `isoCoercion`)

本節では 2 つの judgment を区別する。`func-conv` 規則が直接参照するのは後者 `isoCoercion` である。

```text
isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')
isoCoercion(@σ₁, ι₁, @σ₂, ι₂, α')
```

意味:
- `isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')`
  - annotation `(@σ₁, ι₁)` を持つ関数型が、同じ引数型・戻り値型・ async mode `α'` のもとで annotation `(@σ₂, ι₂)` を持つ関数型の **semantic subtype** である
- `isoCoercion(@σ₁, ι₁, @σ₂, ι₂, α')`
  - annotation `(@σ₁, ι₁)` を持つ関数型から annotation `(@σ₂, ι₂)` を持つ関数型への **1 ステップの direct coercion** を compiler が許可する

重要:
- `isoSubtyping` は semantic relation であり、`iso-subtyping-transitive` により閉じる
- `isoCoercion` は **one-step contextual coercion judgment** であり、本節では transitive closure を取らない
- したがって multi-step な coercion chain は conceptually には説明できても、1 回の `isoCoercion` 導出とは区別する

`isActorIsolated` (`→ Bool` の関数) や `toCapability` (`→ @κ` の関数) とは異なり、どちらも inference rule の集合として定義される。
いずれかの対応 rule で導出可能なとき成立し、いずれの rule でも導出できない場合は不成立 (= その変換は型エラー)。

- `@σ₁, @σ₂`: Sendability 注釈 (`·` or `@Sendable`)
- `ι₁, ι₂`: isolation slot (source / target)
  - 通常形: `@nonisolated`, `@isolated(globalActor)`, `@isolated(any)`, `@concurrent`
  - 特別形: `@isolated(localActor)` (`(isolated LocalActor, ...) -> ...` 形の local actor parameter branch を表す shorthand)
- `α'`: 関数自体の async mode (`sync` or `async`)

---

## 3. 同期・非同期境界 (Sync/Async Boundaries)

本ドキュメントでは、非同期計算について、Algebraic Effects のような式の効果注釈 `! ε` を導入しない。
代わりに、 `α` (ambient sync/async mode) を **どこで `async` にするか**を、構文境界として明示する。

### 3.1 async 関数本体 (`α` の導入境界)

Swift の `func ... async -> R { ... }` は **宣言**であり、本ドキュメントの「式」ではない。
したがって本書は `func` を式として型付けせず、別判定 `Δ ⊢_d decl` で
「宣言が本体をどの `@κ` / `α` でチェックするか」だけを与える。

例えば `@MainActor async` 関数宣言 (引数 `xᵢ : Aᵢ` を含む) は「本体を `@isolated(MainActor)` かつ `α=async` で型付けできる」ことを要求する:

```text
Γ_{body} = x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
Γ_{body}; @isolated(MainActor); async ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────────────────── (decl-fun-mainactor-async)
Δ ⊢_d @MainActor func foo(x₁ : A₁, …, xₙ : Aₙ) async -> R { body }
```

読み: 「`@MainActor func foo(...) async` の本体 `body` は、`await` が書ける文脈 (`α=async`) でチェックされる」。

Note: `Γ_{body}` は「関数本体に入った直後 (body entry) の環境」を表す。

引数の初期 region `ρᵢ` は基本的に宣言型付け (elaboration) で決まるが、本書では次の条件を明示的に採用する:

```text
(@ι = @nonisolated)  ∧  (Aᵢ : ~Sendable)  ⇒  ρᵢ = task
```

すなわち `nonisolated` 関数本体 (sync/async 問わず) では、`~Sendable` 引数は `task` region として扱う。
`task` region は「caller-owned であり、特定の actor に束縛されていない」ことを表す。
sync の場合も関数は任意の isolation context から呼ばれ得るため、引数を特定 actor に帰属させることは静的に安全でない。
一方、actor-isolated 本体 (`@κ = @isolated(a)`) では、この条件は適用されない。
ただしこれは「`@κ` から機械的に `ρᵢ := isolated(a)` へ一律書き換えする」という意味ではなく、entry 環境 `Γ_{body}` の形成時に引数の初期 region が決まる、という意味である。

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_paramBehavesLikeTaskRegion()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_ASYNC_PARAM_MAINACTOR_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolated_paramCapture_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolated_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_SYNC_PARAM_MAINACTOR_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `mainActor_paramCapture_isActorIsolated_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_mainActorParamSendAcrossActor_isError()` (`NEGATIVE_MAINACTOR_PARAM_SEND_ACROSS_ACTOR`)

重要: `@isolated(MainActor)` で本体を型チェックすることと、`ρ` の更新は別レイヤである。
`ρᵢ` の初期値は `Γ_{body}` 形成 (elaboration) で決まり、式の評価中に起きる束縛・精密化 (`disconnected → isolated(MainActor)` など) は [`region-merge`](#region-merge) や [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) のような **bind/merge 規則**で表す。

一般化: ここでは `@MainActor` に限らず、宣言の関数型 annotation `@φ` (`= @σ @ι`) から body の capability `@κ` を `toCapability(proj_ι(@φ))` で決定する。
関数宣言の最小形は次の雛形になる:

```text
Γ_{body} = x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
@κ = toCapability(proj_ι(@φ))
Γ_{body}; @κ; α ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────────────────── (decl-fun)
Δ ⊢_d @φ func foo(x₁ : A₁, …, xₙ : Aₙ) α -> R { body }
```

Note: 結論部の `α` は具象構文では `α = async` なら `async` キーワード、`α = sync` ならキーワードなし (`func foo(...) -> R`) に対応する。

(`decl-fun-mainactor-async` は `decl-fun` に `@φ = · @isolated(MainActor)`, `α = async` を代入したインスタンスとみなせる。
`toCapability(@isolated(MainActor)) = @isolated(MainActor)` なので `@κ = @isolated(MainActor)` となる。)

#### decl-fun-isolated-param

SE-0313 (`isolated` パラメータ) に対応する規則である。

`isolated` パラメータは、関数に **具体 actor インスタンスの isolation を付与する**メカニズムである。
Actor のインスタンスメソッドでは `self` が暗黙の `isolated` パラメータとして扱われる (SE-0313)。

**制約**: 関数ごとに **最大 1 つ** の `isolated` パラメータのみ許される (暗黙の `self` を含む)。

```text
a : ActorType    Γ_{body} = a : ActorType at _, x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
Γ_{body}; @isolated(a); α ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────────────────────── (decl-fun-isolated-param)
Δ ⊢_d func foo(actor: isolated ActorType, x₁ : A₁, …) α → R { body }
```

読み: 「`isolated ActorType` パラメータを持つ関数は、本体を `@isolated(a)` (その actor インスタンスの isolation) でチェックする」。

この規則は `decl-fun` の特殊化であり、`@κ = @isolated(a)` を **`isolated` パラメータから導出**する点が異なる。

Note: Actor のインスタンスメソッド (`actor MyActor { func foo() { ... } }`) は、暗黙の `isolated self` パラメータを持つため、[`decl-fun-isolated-param`](#decl-fun-isolated-param) のインスタンスとみなせる:

```text
self : MyActor    Γ_{body} = self : MyActor at _, ...
Γ_{body}; @isolated(self); sync ⊢ body : R at ρ  ⊣  Γ'_{body}
────────────────────────────────────────────────── (actor method ≡ decl-fun-isolated-param)
Δ ⊢_d func foo() -> R { body }    (within actor MyActor)
```

**`isolated` パラメータ vs `@isolated(any)` の比較**:

| 観点 | `isolated ActorType` | `@isolated(any)` |
|------|---------------------|------------------|
| Actor identity | **静的に既知** (型パラメータ `a`) | **動的** (`f.isolation` で実行時に観測) |
| Sync call | ✅ `await` 不要 (同一 isolation) | ❌ 常に `await` 必須 (hop 不明) |
| Actor state access | ✅ 直接アクセス可能 | ❌ 不可 (identity 不明) |
| toRegion result | `toRegion(@isolated(a)) = isolated(a)` | `toRegion(@nonisolated) = disconnected` (`toCapability(@isolated(any)) = @nonisolated`) |
| 関数あたりの数 | 最大 1 つ | 制限なし (型注釈) |
| Conversion lattice | `@isolated(a)` は独立枝 | `@isolated(any)` は lattice 内 |

検証 (Swift 6.2):
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

SE-0420 (`#isolation` / caller isolation 継承) に対応する規則である。

`isolated (any Actor)? = #isolation` パラメータを持つ関数は、caller の isolation を**動的に**受け取る。
`#isolation` は compile-time macro であり、call site で caller の isolation context に展開される:

| Caller の `@κ` | `#isolation` の展開先 |
|---|---|
| `@isolated(MainActor)` | `MainActor.shared` |
| `@isolated(actor)` (instance) | `self` |
| `@nonisolated` | `nil` |
| isolation 継承中 (`isolated` param あり) | その `isolated` パラメータ |

callee body の capability は `@κ = @nonisolated` である。これは `toCapability(@isolated(any)) = @nonisolated` と同じ理由で、
実行時にどの actor になるか静的に不明なため、body 内では保守的に nonisolated として型検査する。

```text
Γ_{body} = iso : (any Actor)? at _, x₁ : A₁ at ρ₁, …, xₙ : Aₙ at ρₙ
Γ_{body}; @nonisolated; α ⊢ body : R at ρ  ⊣  Γ'_{body}
──────────────────────────────────────────────────────────────── (decl-fun-isolation-inheriting)
Δ ⊢_d func foo(isolation: isolated (any Actor)? = #isolation, x₁ : A₁, …) α → R { body }
```

**[`decl-fun-isolated-param`](#decl-fun-isolated-param) との違い**:

| 観点 | `isolated ActorType` | `isolated (any Actor)? = #isolation` |
|------|---------------------|--------------------------------------|
| Actor identity | **静的に既知** (具体型 `a`) | **動的** (`nil` or any actor) |
| Body の `@κ` | `@isolated(a)` | `@nonisolated` (保守的) |
| Actor state access | ✅ 直接アクセス可能 | ❌ 不可 |
| Call-site benefit | same-iso は `@κ = @ι` で判定 | **`#isolation` により常に same-iso** (後述) |

**重要**: `#isolation` の主な benefit は callee body ではなく **call site** にある。後述の `#isolation` call semantics を参照。

検証 (Swift 6.2):
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

検証 (Swift 6.2):
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

### 3.2 `Task { ... }` / `Task.detached { ... }` 本体

`Task` 本体は `α=async` (`await` が書ける) として扱う。

加えて、Swift 6.2 の標準ライブラリでは `Task.init` / `Task.detached` の operation クロージャ引数が **`sending`** として宣言されている。
これは operation クロージャが新しい task (並行実行単位) に transfer され、caller 側と同時に実行され得ることを型で表したものとなる。
もし `~Sendable` な値を共有したまま capture できると、caller と `Task` 本体が同じ値へ並行アクセスし得て、データ競合 (data race) を静的に排除できない。
クロージャ値が transfer される以上、その capture 環境も一緒に transfer される。
したがって `~Sendable` な値を capture する場合は `disconnected` のものに限って許可し、
transfer 後は caller 側では use-after-send として参照できなくなる (= capture-as-sending / 消費)。
一方で `Sendable` な capture は共有しても安全なので、消費の対象にならない。

これは `Task` 固有の特殊ケースではなく、**`sending` パラメータに渡されるクロージャ一般**に適用される規則である (後述 [`closure-sending`](#closure-sending))。
`Task.init` / `Task.detached` はその代表的な利用例にすぎない。

```swift
// Task.init の簡略化されたシグネチャ:
// init(operation: sending @escaping @isolated(any) () async -> Success)
//                 ^^^^^^^
//                 クロージャ自体が `sending` → capture も消費される

func taskBodiesAreAsyncExample() {
    let x = NonSendable() // disconnected

    Task {
        // body is `async` (can write `await`)
        _ = x.value  // ✅ disconnected な NonSendable を capture できる
    }

    // _ = x.value // ❌ error: `x` was captured as `sending` (消費済み)
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_canCaptureDisconnectedNonSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskInit_useAfterSend_isError()` (`NEGATIVE_TASKINIT_USE_AFTER_SEND`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskDetached_canCaptureDisconnectedNonSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskDetached_useAfterSend_isError()` (`NEGATIVE_TASKDETACHED_USE_AFTER_SEND`)

---

## 4. 関係規則 (Relation Rules)

本節では 2.9 で定義した helper judgment `isoSubtyping` / `isoCoercion` に対する relation-level rule family を与える。
ここで与える規則は term を含まず、annotation 間の関係だけを定義する。

- `isoSubtyping` は semantic relation
- `isoCoercion` は one-step contextual coercion judgment

本節で relation-level rules (`iso-subtyping-*`, `iso-subtyping-to-coercion`, `iso-coercion-*`) を与える。
term-level typing rules (とくに `func-conv`, `isolated-any-to-async`, `sync-to-async`) は [関数型変換 (Function Type Conversion)](#53-関数型変換-function-type-conversion) で与える。

### 4.1 Isolation Subtyping

#### iso-subtyping-identity

```text
───────────────────────────────────────── (iso-subtyping-identity)
isoSubtyping(@σ, ι, @σ, ι, α')
```

任意の関数型は同じ annotation への変換 (恒等変換) が可能である。

#### iso-subtyping-sendable-forget

```text
───────────────────────────────────────── (iso-subtyping-sendable-forget)
isoSubtyping(@Sendable, ι, ·, ι, α')
```

`@Sendable` は安全に忘却できる (制約の緩和)。逆方向 (`·` → `@Sendable`) は不可。

#### iso-subtyping-nonisolated-to-isolated-any

```text
───────────────────────────────────────── (iso-subtyping-nonisolated-to-isolated-any)
isoSubtyping(@σ, @nonisolated, @σ, @isolated(any), α')
```

`nonisolated` は `@isolated(any)` へ昇格できる。`@isolated(any)` は任意の isolation を動的に保持する existential であるため、nonisolated はその特殊ケースとして包含される。

#### iso-subtyping-mainactor-to-isolated-any

```text
───────────────────────────────────────── (iso-subtyping-mainactor-to-isolated-any)
isoSubtyping(@σ, @MainActor, @σ, @isolated(any), α')
```

`@MainActor` は具体的な actor isolation であり、`@isolated(any)` はその existential 上位型である。

#### iso-subtyping-mainactor-implicit-sendable

```text
───────────────────────────────────────── (iso-subtyping-mainactor-implicit-sendable)
isoSubtyping(·, @MainActor, @Sendable, @MainActor, α')
```

`@MainActor` は暗黙的に `@Sendable` である (SE-0434)。Global actor は unique であり、cross-isolation での呼び出しが常に安全であるため、この性質は subtyping 側に置いてよい。

Note: SE-0434 は任意の global actor (`@MainActor` に限らず) に対してこの性質を保証する。本書では `@MainActor` を代表例として用いる。

#### `@isolated(localActor)` special branch

`isolated LocalActor` は特殊な関数型であり、actor パラメータ (`(isolated LocalActor) → Void`) を持つため、通常形とは別 branch として扱う。

```text
───────────────────────────────────────── (iso-subtyping-isolated-local-actor-identity)
isoSubtyping(@σ, @isolated(localActor), @σ, @isolated(localActor), α')
```

```text
───────────────────────────────────────── (iso-subtyping-isolated-local-actor-sendable-forget)
isoSubtyping(@Sendable, @isolated(localActor), ·, @isolated(localActor), α')
```

`@isolated(localActor)` branch では identity と sendable-forget のみを subtype rule として採用する。その他の変換は structural な差 (actor parameter) により subtyping ではなく、必要なら closure wrapping 側で扱う。

#### iso-subtyping-transitive

```text
isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')
isoSubtyping(@σ₂, ι₂, @σ₃, ι₃, α')
───────────────────────────────────────── (iso-subtyping-transitive)
isoSubtyping(@σ₁, ι₁, @σ₃, ι₃, α')
```

`isoSubtyping` は transitive である。以降、subtyping 側の複数の primitive edge はこの規則で合成できる。

#### iso-subtyping-to-coercion

```text
isoSubtyping(@σ₁, ι₁, @σ₂, ι₂, α')
───────────────────────────────────────── (iso-subtyping-to-coercion)
isoCoercion(@σ₁, ι₁, @σ₂, ι₂, α')
```

任意の subtype edge は、そのまま one-step direct coercion edge としても使用できる。

### 4.2 Isolation Coercion

#### iso-coercion-isolated-any-to-nonisolated-deprecated

```text
───────────────────────────────────────── (iso-coercion-isolated-any-to-nonisolated-deprecated)
isoCoercion(@σ, @isolated(any), @σ, @nonisolated, sync)
```

`@isolated(any) sync → @nonisolated sync` は、Swift 6.2 が warning 付きでまだ受理する legacy coercion edge である。これは stable な lattice の推奨辺ではなく、将来 error になる予定の互換レイヤとしてのみ保持する。

#### iso-coercion-sendable-nonisolated-universal

```text
ι₂ ≠ @isolated(localActor)
───────────────────────────────────────── (iso-coercion-sendable-nonisolated-universal)
isoCoercion(@Sendable, @nonisolated, @σ₂, ι₂, α')
```

`@Sendable @nonisolated` は最も制約の強い source であり、local actor parameter branch (`isolated LocalActor`) を除く任意のターゲットに direct coercion で変換可能である。`@Sendable` は任意の isolation 境界を越えて安全に送信できることを保証し、`@nonisolated` は特定の actor に束縛されていないことを意味する。

Note: ここで除外しているのは local actor instance を固定する `@isolated(localActor)` branch のみであり、global actor である `@MainActor` は含まれる。

#### iso-coercion-async-mainactor-universal

```text
ι₂ ≠ @isolated(localActor)
───────────────────────────────────────── (iso-coercion-async-mainactor-universal)
isoCoercion(@σ, @MainActor, @σ₂, ι₂, async)
```

async の世界では、`@MainActor` は local actor parameter branch (`isolated LocalActor`) を除く任意のターゲットに direct coercion で変換可能である。`@MainActor` は暗黙的に `@Sendable` (SE-0434) であり、かつ async では runtime actor hopping により任意の isolation domain に到達できるためである。

Note: ここで除外しているのも local actor instance を固定する `@isolated(localActor)` branch のみであり、他の global actor への議論ではない。

#### iso-coercion-async-nonsendable-equiv

```text
ι₁ ∈ {@nonisolated, @concurrent, @isolated(any)}
ι₂ ∈ {@nonisolated, @concurrent, @isolated(any)}
───────────────────────────────────────── (iso-coercion-async-nonsendable-equiv)
isoCoercion(·, ι₁, ·, ι₂, async)
```

async の世界では、non-`@Sendable` な `nonisolated`、`@concurrent`、`@isolated(any)` は相互変換可能 (双方向) である。これは async 関数がランタイムの actor hopping を通じて任意の isolation context で実行できるためである。

#### Conversion Matrix

以下のテーブルは `isoSubtyping` + `iso-subtyping-to-coercion` + `isoCoercion` 固有 rule を合わせた **combined system** を `FuncConversionRules.swift` の実験結果と照合したものである。🔧 マークは relation-level rules の対象外であり、term-level の closure wrapping が必要であることを示す。

**Sync 変換マトリクス** (`α' = sync`、direct coercion のみ):

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

略語: id = iso-subtyping-identity, sf = iso-subtyping-sendable-forget, ni→ia = iso-subtyping-nonisolated-to-isolated-any, uni = iso-coercion-sendable-nonisolated-universal, ma-s = iso-subtyping-mainactor-implicit-sendable, ma→ia = iso-subtyping-mainactor-to-isolated-any, dep = iso-coercion-isolated-any-to-nonisolated-deprecated, 🔧 = closure wrapping 必要

**Async 変換マトリクス** (`α' = async`、direct coercion のみ):

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

Async マトリクスの特徴:
- Row M, MS: `iso-coercion-async-mainactor-universal` により IL/ILS 以外の全ターゲットに direct coercion 可能
- Row N, C, IA: `iso-coercion-async-nonsendable-equiv` により {N, C, IA} 内で双方向
- Row S, CS: `iso-coercion-sendable-nonisolated-universal` により IL/ILS 以外の全ターゲットに direct coercion 可能
- Row IAS: direct coercion で M/MS に到達不可 (term-level では closure wrapping `{ await f() }` が必要)
- Row IL, ILS: direct coercion では identity/sendable-forget のみ。他は全て closure wrapping (actor インスタンスのキャプチャが必要)

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest_MainActor`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest_MainActor`

#### Conversion Diagram

変換マトリクスの directed graph 表現は [`docs/diagrams/func-conversion-rules.mmd`](diagrams/func-conversion-rules.mmd) (Mermaid) を参照。`make diagrams` でレンダリングできる。

#### Group Analysis

変換パターンは以下の 3 カテゴリに大別できる:

1. **Non-Sendable Lattice**: `nonisolated`, `@concurrent` (async のみ), `@isolated(any)`
   - グループ内で双方向変換が可能
   - Sendable 型への変換は不可
   - `isolated LocalActor` への到達も不可

2. **Sendable Group**: `@Sendable`, `@MainActor`, `@concurrent @Sendable`, `@isolated(any) @Sendable`
   - Non-Sendable 型への変換が可能 (@Sendable を忘れる)
   - グループ内でほぼ相互変換可能 (双方向)
   - `isolated LocalActor` / `isolated LocalActor @Sendable` への到達可能 (片方向)
   - Note: `isolated LocalActor @Sendable` はシンクであり、他との相互変換は不可

3. **`isolated LocalActor` (Isolated Sink)**:
   - **Sync**: 完全に隔離 — `@Sendable` からのみ到達可能
   - **Async**: Sendable Group からのみ到達可能、他の型への変換は不可
   - **`isolated LocalActor @Sendable async`**: Sendable Group とは非等価 (片方向のみ)

`isolated LocalActor` が特殊な理由:
- 特定の **actor インスタンス**に結びついている (`@MainActor` のような global actor ではない)
- **actor パラメータ**を持つ: `(isolated LocalActor) async -> Void` vs `() async -> Void`
- Sync では他の isolation domain から呼べない
- Async では actor パラメータを提供できないため、0-ary 関数への変換が不可

## 5. 型付け規則 (Typing Rules)

注: 以下の ` ```swift` 断片は主に `swift/Sources/concurrency-type-check/TypingRules.swift` の関数から抜粋している (補助型 `NonSendable` 等も同ファイルに定義)。

### 5.1 変数 (Variables)

#### var

変数参照の基本規則で、環境中の束縛が現在 capability からアクセス可能なら同じ region で読めることを表す。

```text
x : T at ρ ∈ Γ
ρ ∈ accessible(@κ)
────────────────────────────────── (var)
Γ; @κ; α ⊢ x : T at ρ  ⊣  Γ
```

この規則は「アクセス可否」のみを判定する。
`Sendable` / `~Sendable` の分岐は規則内に持たず、正規形条件 `T : Sendable ⇔ (ρ = _)` に委ねる。

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `varSendable_accessibleFromAnyCapability()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `varConnected_mainActor_canAccessConnectedVar()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_varConnected_nonisolatedCannotAccessMainActorVar_isError()` (`NEGATIVE_VAR_CONNECTED_MAINACTOR_ACCESS`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `varDisconnected_nonSendableClosuresCanCaptureDisconnected()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_noInherit_sendableCannotCaptureNonSendable_isError()` (`NEGATIVE_VAR_DISCONNECTED_SENDABLE_CAPTURE`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `mainActor_readDoesNotPreventSendingFromDisconnected()`

`Sendable` の場合 (`ρ = _`) は `accessible(@κ)` が常に `_` を含むため、任意の capability から参照できる:

```swift
let s = MySendable() // `@unchecked Sendable` class (definition: experiment file)

let f0: () -> MySendable = { s }
let f1: @MainActor () -> MySendable = { s }
let f2: @isolated(any) () -> MySendable = { s }
let f3: @Sendable () -> MySendable = { s }

_ = (f0(), f1, f2, f3)
_ = s // not consumed
```

`~Sendable` の場合は `ρ ∈ ρ_{ns}` であり、`ρ ∈ accessible(@κ)` が直接のアクセス条件になる。
`accessible(@κ)` は `disconnected` を常に含むため、`disconnected` な値はどの `@κ` でもアクセス可能である。
`disconnected` の参照そのものは束縛を起こさない (束縛は [`region-merge`](#region-merge) や [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) で起きる)。

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

### 5.2 シーケンス (Sequencing)

#### seq

逐次実行 `e₁; e₂` に対し、`e₁` の出力環境を `e₂` の入力環境へそのまま受け渡す規則である。

```text
Γ;  @κ; α ⊢ e₁ : () at ρ₁  ⊣  Γ₁
Γ₁; @κ; α ⊢ e₂ : T  at ρ₂  ⊣  Γ₂
──────────────────────────────────── (seq)
Γ;  @κ; α ⊢ e₁; e₂ : T at ρ₂  ⊣  Γ₂
```

検証 (Swift 6.2):
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

### 5.3 関数型変換 (Function Type Conversion)

本節では helper relation `isoSubtyping` / `isoCoercion` を用いる **term-level typing rules** を定義する:
- `sync-to-async`: sync → async 昇格
- `func-conv`: `isoCoercion` を使って関数型 annotation を変換する typing rule
- `isolated-any-to-async`: `@isolated(any) sync` の async isolation erasure

これら 3 つの term-level typing rule は互いに直交しており、合成可能である。例えば `func-conv` の後に `sync-to-async` で async に昇格できる。

#### sync-to-async

sync 関数型を async 関数型へ昇格できるという、Swift の基本 subtyping を明示する規則である。

```text
Γ; @κ; α ⊢ f : @φ () → B  at ρ_f  ⊣  Γ'
────────────────────────────────────────────────────── (sync-to-async)
Γ; @κ; α ⊢ f : @φ () async → B  at ρ_f  ⊣  Γ'
```

sync 関数型は常に async 関数型に昇格できる (`() → B  <:  () async → B`)。
これは Swift の一般的な subtyping であり、sync 関数を async 変数に代入したり、
async パラメータに sync 関数を渡すことが可能である。

```swift
let f: () -> Void = { }
let g: () async -> Void = f  // ✅ sync → async lift
```

この規則は cross-isolation 呼び出しや `@isolated(any)` の暗黙 async 化の基盤でもある。

#### func-conv

関数型の isolation annotation を変換する規則である。[`isoCoercion`](#29-isolation-subtyping--coercion-isosubtyping-isocoercion) を前提として使用する。

```text
Γ; @κ; α ⊢ f : @σ₁ @ι₁ (A) α' → B  at ρ_f  ⊣  Γ'
isoCoercion(@σ₁, @ι₁, @σ₂, @ι₂, α')
ρ' = (if @σ₂ = @Sendable then _ else ρ_f)
──────────────────────────────────────────────────────── (func-conv)
Γ; @κ; α ⊢ f : @σ₂ @ι₂ (A) α' → B  at ρ'  ⊣  Γ'
```

ポイント:
- この規則は関数型の **isolation annotation** を変換する。ambient `@κ` は変更しない
- `isoCoercion` は one-step contextual coercion judgment である。multi-step な chain は本規則 1 回では表さない
- Region `ρ'`: ターゲットが `@Sendable` の場合 `_` (Sendable region) に正規化する。これは `@Sendable` を獲得することで関数が region-free になるためである
- 引数型 `A` と戻り値型 `B` は変更しない
- `α'` は関数自体の async mode であり、ambient `α` とは異なる
- `sync-to-async` とは直交: `func-conv` は isolation を変換し、`sync-to-async` は `α'` を変換する

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

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest_MainActor`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileAsyncConversionTest_MainActor`

#### isolated-any-to-async

`@isolated(any) sync` 関数型を、isolation を erasure して async 関数型に変換する規則である (SE-0431)。

```text
Γ; @κ; α ⊢ f : @σ @isolated(any) () → B  at ρ_f  ⊣  Γ'
¬isActorIsolated(@ι₂)
ρ' = (if @σ = @Sendable then _ else ρ_f)
──────────────────────────────────────────────────────── (isolated-any-to-async)
Γ; @κ; α ⊢ f : @σ @ι₂ () async → B  at ρ'  ⊣  Γ'
```

ポイント:
- **ソースは sync、ターゲットは async**: isolation erasure と sync→async lift を 1 ステップで行う
- **`¬isActorIsolated(@ι₂)`**: ターゲットが特定の actor (`@MainActor` 等) であってはならない。動的な isolation 情報から特定の actor への静的保証ができないため
- **型レベルでは isolation 情報が消失**: `.isolation` プロパティはアクセス不可になる
- **ランタイムでは元の dynamic isolation が保持される**: 実行時には元の actor 上で実行される

`¬isActorIsolated(@ι₂)` を満たすターゲット:
- `@nonisolated` (`() async → Void`): ✅
- `@Sendable @nonisolated` (`@Sendable () async → Void`): ✅ (`@σ` が `@Sendable` の場合)
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

この規則が `func-conv` + `sync-to-async` の合成では導出できない理由:
`@isolated(any) sync → @nonisolated sync` は deprecated (将来 error) であるため、`func-conv` で isolation を変換してから `sync-to-async` で async に昇格するパスが使えない。SE-0431 はこの制約を回避するために、isolation erasure と async lift を同時に行う特別な変換を提供する。

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncIsolatedAnyToAsyncConversionTest`

#### Subtyping / Coercion 検証テーブル

Sync / Async 変換マトリクスは [Conversion Matrix](#conversion-matrix) を参照 (`isoSubtyping` + `iso-subtyping-to-coercion` + `isoCoercion` 固有 rule の combined system)。

補足:
- 🔧 マークは `isoCoercion` (one-step direct coercion) の対象外であり、term-level の closure wrapping が必要であることを示す
- 複数略語を併記した cell は combined system における **explanation chain** を表す。これは `isoCoercion` 自体が transitive であることを主張するものではない

#### Closure wrapping による変換

以下の変換は `FuncConversionRules.swift` でコンパイル可能だが、direct coercion (`f`) ではなく closure wrapping (新しい closure の生成) を伴う。これらは `isoCoercion` / `func-conv` の対象外であり、[`closure-inherit-parent`](#closure-inherit-parent) や [`closure-no-inherit-parent`](#closure-no-inherit-parent) 等の closure 規則と組み合わせて理解する。

**`isolated LocalActor` 関連** (arity 変更を伴う):

```swift
// @Sendable → isolated LocalActor (sync): closure wrapping で actor パラメータを追加
func convert(_ f: @escaping @Sendable () -> Void) -> (isolated LocalActor) -> Void {
    { _ in f() }  // 🔧 新しい closure を生成
}

// isolated LocalActor @Sendable async → nonisolated async: キャプチャした actor を渡す
func convert(_ f: @escaping @Sendable (isolated LocalActor) async -> Void) -> () async -> Void {
    let actor = LocalActor()
    return { await f(actor) }  // 🔧 新しい closure を生成 + await
}

// @MainActor async → isolated LocalActor async: closure wrapping + await
func convert(_ f: @escaping @MainActor () async -> Void) -> (isolated LocalActor) async -> Void {
    { _ in await f() }  // 🔧 新しい closure を生成 + await
}
```

**`@isolated(any) @Sendable async → @MainActor async`** (direct coercion 不可):

```swift
// IAS → M: direct coercion `f` はエラー、explicit closure wrapping が必要
func convert(_ f: @escaping @isolated(any) @Sendable () async -> Void) -> @MainActor () async -> Void {
    // f  // ❌ ERROR: direct coercion
    { await f() }  // 🔧 新しい closure を生成 + await
}
```

これらの変換が direct coercion でない理由:
- **arity 変更**: `isolated LocalActor` は actor パラメータを持つため、0-ary 関数との間で型の構造が異なる
- **`await` が必要**: cross-isolation 呼び出しは suspension を伴うため、単純な型強制では表現できない
- **dynamic isolation の静的保証不可**: `@isolated(any) @Sendable` から `@MainActor` への direct coercion は、動的な isolation が `@MainActor` であることを静的に保証できないため不可

### 5.4 Region マージ (Aliasing / Assignment)

#### region-merge

代入や aliasing により 2 つの NonSendable region を join し、環境内の region 情報を一貫して更新する規則である。

```text
Γ;  @κ; α ⊢ e₁ : T₁ at ρ₁  ⊣  Γ₁
Γ₁; @κ; α ⊢ e₂ : T₂ at ρ₂  ⊣  Γ₂
T₁ : ~Sendable    T₂ : ~Sendable
ρ₁, ρ₂ ∈ ρ_{ns}
ρ = ρ₁ ⊔ ρ₂
───────────────────────────────────────────────────────────────── (region-merge)
Γ;  @κ; α ⊢ (e₁.field = e₂) : () at _  ⊣  Γ₂[ρ₁ ↦ ρ, ρ₂ ↦ ρ]
```

ポイント:
- 代入は **消費**ではなく **文脈 refinement** (環境更新) として表す
- [`region-merge`](#region-merge) は NonSendable 同士の結合にのみ適用する (`⊔` の定義域は `ρ_{ns}`)
- `Sendable` 値は正規形条件により常に `at _` で保持され、merge の対象にしない
- `()` は `Sendable` なので `at _` に正規化する (region の事実は `Γ₂[...]` のみが持つ)

検証 (Swift 6.2):
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

### 5.5 関数呼び出し (Calls)

本ドキュメントの call 規則はすべて、必ず

1. `f` を型付けして `Γ₁`
2. `arg` を型付けして `Γ₂`
3. 境界 crossing / transfer / bind を適用して `Γ₃`

の順で出力文脈を伝播する。

規則名の接頭辞 `call-*` は、まず次のファミリーで読む:

| Family | 条件 | 意味 | この節の規則 |
|---|---|---|---|
| `call-nonsendable-*` | `canSend` 成立 | `~Sendable` 値の消費判定 (統一規則) | [`call-nonsendable-noconsume`](#call-nonsendable-noconsume), [`call-nonsendable-consume`](#call-nonsendable-consume) |
| `call-same-*` | `@κ = @ι` | 同一 isolation 呼び出し (boundary crossing なし) | [`call-same-sync-sendable`](#call-same-sync-sendable), [`call-same-async-sendable`](#call-same-async-sendable), [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) |
| `call-cross-*` | `@κ ≠ @ι`, `@ι ∉ { @concurrent }` (ただし [`call-cross-sendable`](#call-cross-sendable) は `@ι ≠ @nonisolated`) | 境界越え呼び出し | [`call-cross-sendable`](#call-cross-sendable), [`call-cross-sending-result`](#call-cross-sending-result), [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error) |
| `call-concurrent-*` | `@ι = @concurrent` | 明示 nonisolated async 呼び出し (専用セマンティクス) | [`call-concurrent-sendable`](#call-concurrent-sendable), [`call-concurrent-nonsendable`](#call-concurrent-nonsendable) |
| [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) | `@ι = @nonisolated`, `async` | SE-0461 の caller isolation 継承 | [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) |
| [`call-nonisolated-sync`](#call-nonisolated-sync) | `@ι = @nonisolated`, `sync`, `@κ ≠ @nonisolated` | nonisolated sync は caller executor 上で実行 (no boundary) | [`call-nonisolated-sync`](#call-nonisolated-sync) |

#### call-nonsendable-noconsume

`~Sendable` 値が send 対象 (明示 `sending` パラメータまたは暗黙の cross-isolation transfer) となったが、caller と callee が **同一の具体的 actor isolation** を共有するため、値を消費せず **元の region をそのまま保持する** 規則。

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

`[sending]` は `sending` が付いていても付いていなくてもよいことを示す (定義は [`canSend`](#cansend) 参照)。
`[await]` は `α' = async` の場合に付与される。

同一の具体的 actor isolation (例: `@MainActor` 同士) では、serial executor により caller と callee が同時に実行されないため、
`sending` 付きパラメータでも値を消費せず caller の環境に保持できる (`Γ₂ \ {arg}` ではなく `Γ₂`)。
ここで重要なのは、**保持されるのは常に `disconnected` ではなく元の region `ρ_a` そのもの**だという点である。
したがって `disconnected` を same-iso `sending` に渡せば `disconnected` のまま残り、同じ actor にすでに束縛された値を渡せばその actor-bound region のまま残る。

##### noconsume の例: 同一具体 actor + sending

[`call-nonsendable-noconsume`](#call-nonsendable-noconsume) の適用例。`@MainActor` 同士で `sending` パラメータに渡す場合、`isActorIsolated(@MainActor) ∧ @MainActor = @MainActor` が成立し、消費が免除される。

検証 (Swift 6.2):
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

[`call-nonsendable-noconsume`](#call-nonsendable-noconsume) と [`call-nonsendable-consume`](#call-nonsendable-consume) の対比。
同一 isolation 内であれば caller と callee が同時に実行されないため、`sending` パラメータでも値を保持できる。

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
| 規則 | [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) | [`call-nonsendable-consume`](#call-nonsendable-consume) |
| 条件 | `isActorIsolated(@κ) ∧ @κ = @ι` | それ以外 |
| 出力環境 | `Γ₂` | `Γ₂ \ {arg}` |
| 渡した後の使用 | ✅ 可能 | ❌ use-after-send |

##### `call-same-nonsendable-merge` との違い (bind vs no-bind)

通常の (non-`sending`) パラメータは region を bind/refine するため以後 `disconnected` でなくなるが、
`sending` パラメータは bind を起こさず **元の region を保存する**。

```swift
// Non-sending: bind が発生 → disconnected を失う
@MainActor func example_nonSending() async {
    let x = NonSendable()        // disconnected
    mainActorUseNonSendable(x)   // [call-same-nonsendable-merge] bind: x → isolated(MainActor)
    _ = x.value                  // ✅ still accessible (not consumed)

    let other = OtherActor()
    await other.useNonSendableSending(x) // ❌ [call-nonsendable-consume] x is no longer disconnected!
}

// Sending: bind なし → disconnected を維持
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
| 消費 | なし | なし |
| region effect | **bind** → `ρ_a'` に精密化 | **bind なし** → 元の `ρ_a` を保存 |
| 渡した後に cross-actor send | ❌ (bound されたため) | `ρ_a = disconnected` なら ✅、actor-bound なら ❌ |

#### call-nonsendable-consume

`~Sendable` 値が send 対象となり、かつ caller と callee が同一の具体的 actor isolation を共有 **しない** ため、値をアフィン消費する規則。

```text
Γ;  @κ; α ⊢ f   : @σ @ι ([sending] A) α' → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A at disconnected                      ⊣  Γ₂
A : ~Sendable    B : Sendable    @ι ∉ { @concurrent }
canSend(@κ, @ι, [sending])
¬(isActorIsolated(@κ) ∧ @κ = @ι)
────────────────────────────────────────────────────────────── (call-nonsendable-consume)
Γ;  @κ; α ⊢ [await] f(arg) : B at _  ⊣  (Γ₂ \ {arg})
```

`[await]` は `α' = async` の場合に付与される。

##### コンパイラとの対応

この 2 規則はコンパイラ実装 (`PartitionUtils.h` `PartitionOpKind::Send`) の 1 つの if 分岐に直接対応する:

```cpp
// PartitionUtils.h — Send evaluation (simplified)
if (calleeIsolationInfo.isActorIsolated() &&
    sentRegionIsolation.hasSameIsolation(calleeIsolationInfo))
  return;                    // call-nonsendable-noconsume → Γ₂
p.markSent(op, ptrSet);     // call-nonsendable-consume   → Γ₂ \ {arg}
```

##### consume の例: nonisolated + sending

[`call-nonsendable-consume`](#call-nonsendable-consume) の適用例。`@nonisolated` は `isActorIsolated` を満たさないため、caller の isolation に関わらず消費が発生する。

検証 (Swift 6.2):
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

noconsume と consume の違いは [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume) の前提条件 `isActorIsolated(@κ) ∧ @κ = @ι` の成否に帰着する。

##### consume の例: cross-isolation 暗黙 sending

[`call-nonsendable-consume`](#call-nonsendable-consume) の適用例。異なる isolation へ `~Sendable` 値を渡す場合、明示 `sending` がなくても `canSend` の暗黙 transfer 条件 (`@κ ≠ @ι`) が成立し、消費が発生する。

Note: 前提 `B : Sendable` は結果型に対する制約である。`B : ~Sendable` の場合は [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error) により**コンパイルエラー**となる。cross-isolation で `~Sendable` な結果を返すには明示的な `sending` 注釈が必要である ([`call-cross-sending-result`](#call-cross-sending-result))。

検証 (Swift 6.2):
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

##### consume の例: cross-isolation 明示 sending

[`call-nonsendable-consume`](#call-nonsendable-consume) の適用例。`sending` パラメータへの明示的な渡しで `canSend` が成立し、`@κ ≠ @ι` のため消費が発生する。
`@ι = @nonisolated` の `sending` 呼び出し (例: actor-isolated caller から `@nonisolated async (sending ...)` へ渡す場合) にも適用される。

検証 (Swift 6.2):
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

同一 isolation の `sync` 呼び出しで、引数が `Sendable` な場合の規則を与える。

```text
Γ;  @κ; α ⊢ f   : @σ @κ (A) → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A   at _   ⊣  Γ₂
ρ ∈ accessible(@κ)
────────────────────────────────────────────────────────────── (call-same-sync-sendable)
Γ;  @κ; α ⊢ f(arg) : B at ρ  ⊣  Γ₂
```

ポイント:
- 前提 `arg : A at _` は `A : Sendable` を暗黙に要求する (`_` region は Sendable 型にのみ付与される)
- 返り値の region `ρ` は callee が決定し、`accessible(@κ)` に属する任意の region を取りうる: `B : Sendable` なら `_`、`B : ~Sendable` なら `disconnected` (新規生成値) や `toRegion(@κ)` (actor state 由来) など

`A : ~Sendable` の場合は前提 `arg : A at _` が満たせないため、この規則は適用できない。
その場合は [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) (通常引数 + bind/refinement) または [`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume) (`sending` 引数) を使う。

検証 (Swift 6.2):
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

同一 isolation の `async` 呼び出しで、**引数が `Sendable` であっても** `await` が必要であり、返り値の region は caller capability からアクセス可能な任意の region を取りうることを定式化する。

```text
Γ;  @κ; async ⊢ f   : @σ @κ (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A   at _             ⊣  Γ₂
A : Sendable
ρ ∈ accessible(@κ)
────────────────────────────────────────────────────────────── (call-same-async-sendable)
Γ;  @κ; async ⊢ await f(arg) : B at ρ  ⊣  Γ₂
```

この規則は本書で初めて `await` が結論部に現れる規則である。

`async` 関数の呼び出しには、同一 isolation 内であっても `await` が必要である。
これは `async` 関数が suspension point (中断点) を含み得るためで、
コンパイラは caller に対して「ここで実行が中断する可能性がある」ことを明示させる。

前提部の `α = async` は、この `await` 式が書ける文脈 (= `async` な関数本体や `Task` 本体) にいることを要求している。
`α = sync` の文脈では `await` が書けないため、この規則は適用できない ([`call-same-sync-sendable`](#call-same-sync-sendable) 参照)。

検証 (Swift 6.2):
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

同一 isolation で `~Sendable` 値を通常引数として渡したときの束縛 (region refinement) を、環境更新として表す規則である。

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

ポイント:
- **束縛の事実は環境更新にのみ残す**。戻り値の region `ρ_b` は `accessible(@κ)` に属する任意の region を取りうる: `B : Sendable` なら正規形条件により `ρ_b = _`、`B : ~Sendable` なら `disconnected` (新規生成値) や `toRegion(@κ)` (actor state 由来) など
- `ρ_a = disconnected` の場合もこの規則は適用できる。結論の更新は `ρ_a' = disconnected ⊔ toRegion(@κ) = toRegion(@κ)` となり、呼び出し先の isolation に束縛される。
- `ρ_a = task` の場合もこの規則は適用できる。結論の更新は `ρ_a' = task ⊔ toRegion(@κ)` で決まり、
  `toRegion(@nonisolated) = disconnected` なら `ρ_a' = task` となり task のまま保存される。
  一方で concrete actor へ束縛する `toRegion(@isolated(a)) = isolated(a)` とは `task ⊔ isolated(a) = invalid` なので、結果は `invalid` になり、これは compile error 状態を表す。task を actor に「束縛し直す」ことはできない。

検証 (Swift 6.2):
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

境界 crossing は **sync/async 関数型に関わらず** `await` を要求する (静的に hop を排除できないため)。
sync 関数の場合は [`sync-to-async`](#sync-to-async) 規則により暗黙に async に昇格される。

Note: `@ι ≠ @concurrent` は `call-concurrent-*` 規則との排他性のためである。`@concurrent` は消費セマンティクスが異なる (non-Sendable 引数を消費しない) ため、専用の規則で扱う。
また `@ι ≠ @nonisolated` は [`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) および [`call-nonisolated-sync`](#call-nonisolated-sync) との責務分離のためである (`@nonisolated` は async/sync それぞれ専用規則で扱う)。

Note: `@isolated(any)` は実行時 isolation が不明なため、任意の `@κ` に対して常に `@κ ≠ @isolated(any)` が成り立つ (`@κ` の定義域は `@nonisolated | @isolated(a)` のみ)。
したがって以下の `call-cross-*` 規則はすべて `@ι = @isolated(any)` のケースを含む。

```text
Γ;  @κ; async ⊢ f   : @σ @ι (A) α → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A       at _     ⊣  Γ₂
A : Sendable    B : Sendable    @κ ≠ @ι    @ι ∉ { @concurrent, @nonisolated }
────────────────────────────────────────────────────────────── (call-cross-sendable)
Γ;  @κ; async ⊢ await f(arg) : B at _  ⊣  Γ₂
```

検証 (Swift 6.2):
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

異なる isolation から `sending` 結果を受け取る場合、返り値を `disconnected` として安全に受理できることを与える規則である。

```text
Γ; @κ; async ⊢ f : @σ @ι () α → sending B  at ρ_f  ⊣  Γ'
B : ~Sendable    @κ ≠ @ι    @ι ∉ { @concurrent }
──────────────────────────────────────────────────────────── (call-cross-sending-result)
Γ; @κ; async ⊢ await f() : B at disconnected  ⊣  Γ'
```

`sending` (SE-0430) 引数がパラメータ側の消費 (caller → callee への転送) であるのに対し、
`sending` 返り値は**結果側の転送** (callee → caller) である。
返り値の型が `sending B` と宣言されている場合、callee は返す値がどの isolation domain にも束縛されていないことを保証する。
したがって caller は返り値を `disconnected` として受け取り、自由に使用・再転送できる。

これは消費 (環境の縮小) ではなく、**安全な値の生成**を保証する規則である。

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `crossActor_sendingResult_compiles()` (返り値を別 actor へ再送できる＝`disconnected`)
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

Cross-isolation 呼び出しで `~Sendable` な結果を `sending` なしに返すことは **導出不能** (コンパイルエラー) である。

```text
Γ;  @κ; async ⊢ f   : @σ @ι () α → B  at ρ_f  ⊣  Γ₁
B : ~Sendable    @κ ≠ @ι    @ι ∉ { @concurrent }
──────────────────────────────────────────────────────────── (call-cross-nonsending-result-error)
derivation fails (compile error)
```

Note: 関数型が `→ B` (`sending` なし) であることは前提の型注釈から直接読み取れる (`→ sending B` と対比)。
`sending` は型の一部ではなく、関数の parameter/result position に付く属性である。

**非対称性 (params vs results) に関するメモ**:

引数 (params) では、`disconnected` な `~Sendable` 値は暗黙的に転送できる ([`call-nonsendable-consume`](#call-nonsendable-consume)、`canSend` の暗黙 transfer)。
これは caller が所有権を放棄する形であり、型システムが `Γ \ {arg}` で追跡できるため安全である。

一方、結果 (results) では caller が**受け取る側**であり、cross-isolation で生成された `~Sendable` 値を
caller の domain に安全に持ち込むには **明示的な `sending` 注釈**が必要である。
`sending` がなければ、結果値がどの isolation domain に属するか不明となり、型システムが安全性を保証できない。

検証 (Swift 6.2):
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

`@concurrent async` は actor から降り得るため、SE-0461 に従い actor-capable な文脈では
引数/結果に sendable checking が走る。`Sendable` ならそのまま呼べる:

```text
Γ;  @κ; async ⊢ f   : @σ @concurrent (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A at _                                ⊣  Γ₂
A : Sendable    B : Sendable
────────────────────────────────────────────────────────────── (call-concurrent-sendable)
Γ;  @κ; async ⊢ await f(arg) : B at _  ⊣  Γ₂
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `concurrentAsync_callFromNonisolated_compiles()`

```swift
func concurrentCall_sendableExample() async {
    let f: @concurrent (MySendable) async -> MySendable = { $0 }
    let x = MySendable()
    _ = await f(x)
}
```

#### call-concurrent-nonsendable

`A : ~Sendable` の値を `@concurrent async` に渡すには、少なくとも `disconnected` である必要がある (actor-bound の値は不可)。
**呼び出し後に消費はされない** (`disconnected` のまま扱える)。

```text
Γ;  @κ; async ⊢ f   : @σ @concurrent (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A at disconnected                     ⊣  Γ₂
A : ~Sendable    B : Sendable
────────────────────────────────────────────────────────────── (call-concurrent-nonsendable)
Γ;  @κ; async ⊢ await f(arg) : B at _  ⊣  Γ₂
```

理由: この規則は [`call-nonsendable-consume`](#call-nonsendable-consume) のような「別 actor への transfer/consumption」ではなく、
`@concurrent` 呼び出しに対する「呼び出し可能性チェック」として扱う。
前提で `disconnected` を要求して actor-bound 値を排除しつつ、呼び出し先に特定 actor への bind 先がないため、 **環境は `Γ₂` のまま保存される** 。
そのため呼び出し後も値は `disconnected` として再利用・再送できる。

検証 (Swift 6.2):
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

`@nonisolated async` 呼び出し (SE-0461) は isolation boundary crossing ではない (hop を要求しない) が、`async` であるため `await` は必要である。
この規則は **`nonsending` パラメータ**呼び出しを扱う。
また `~Sendable` 引数の region は **呼び出し後も保存される** (少なくとも `disconnected` は束縛されない)。
`@nonisolated async` でも `sending` パラメータ呼び出しで caller/callee が same でない場合は、
[`call-nonsendable-consume`](#call-nonsendable-consume) 側で消費として扱う。

```text
Γ;  @κ; async ⊢ f   : @nonisolated (A) async → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; async ⊢ arg : A at ρ_a                 ⊣  Γ₂
────────────────────────────────────────────────────────────── (call-nonisolated-async-inherit)
Γ;  @κ; async ⊢ await f(arg) : B at ρ_b  ⊣  Γ₂
```

Note: 他の call 規則 (`call-same-*`, `call-cross-*`, `call-concurrent-*`) が `A : Sendable` / `A : ~Sendable` や region 制約を明示するのに対し、本規則にはそれらの side condition がない。これは `nonisolated async` (nonsending) が caller の isolation を継承し、**isolation boundary crossing が発生しない**ためである。transfer がなければ Sendability / region による分岐は不要であり、引数と結果は caller の文脈にそのまま留まる。

ここで `ρ_b` は結果型に依存し、`B : Sendable` なら `_` に正規化できる。
`B : ~Sendable` の場合、**常に `disconnected` が保証されるわけではない** (= `ρ_b` は本来、返す式の region に依存する)。
ただし返り値の型が `sending B` であれば `ρ_b = disconnected` が保証される ([`call-cross-sending-result`](#call-cross-sending-result) 参照)。
一方、 `nonisolated async` 内で生成して返した NonSendable 値は `disconnected` として扱われ、境界越しに transfer できる。

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_callThenSend_argAndResult_compiles()` (引数が束縛されず、返り値も transfer 可能)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_callThenSend_compiles()` (引数の `disconnected` が保存される最小例)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_returnNonSendable_canBeSent()` (`~Sendable` 返り値が transfer 可能な例)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_taskResultThenSend_isError()` (`NEGATIVE_NONISOLATED_ASYNC_TASK_RESULT_THEN_SEND`)

```swift
@MainActor
func nonisolatedAsyncCallThenSendExample() async {
    // nonisolated async なヘルパー (caller の isolation を継承、fresh な値を返す)
    nonisolated func useAndMakeNonSendable(_ x: NonSendable) async -> NonSendable {
        _ = x.value
        return NonSendable() // 値を生成して返す
    }

    let x = NonSendable() // disconnected

    let y = await useAndMakeNonSendable(x)

    let other = OtherActor()
    await other.useNonSendableSending(y) // ✅ result is disconnected (fresh)
    await other.useNonSendableSending(x) // ✅ argument remains disconnected
}

#if NEGATIVE_NONISOLATED_ASYNC_TASK_RESULT_THEN_SEND

// Counterexample: 引数をそのまま返す場合は disconnected にならない
func negative_nonisolatedAsync_taskResultThenSend_isError(_ x: NonSendable) async {
    // nonisolated async な identity 関数 (引数をそのまま返す)
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

`@nonisolated sync` 関数は caller の executor 上で実行される (SE-0461: "caller executor 上、no switch")。
したがって actor-isolated な文脈 (`@κ = @isolated(a)`) から呼び出しても **isolation boundary crossing は発生せず**、`await` は不要である。

この規則は `@κ ≠ @nonisolated` の場合のみ適用する。`@κ = @nonisolated` の場合は `@κ = @ι` なので `call-same-*` 規則が適用される。

```text
Γ;  @κ; α ⊢ f   : @σ @nonisolated (A) → B  at ρ_f  ⊣  Γ₁
Γ₁; @κ; α ⊢ arg : A at ρ_a                          ⊣  Γ₂
@κ ≠ @nonisolated
ρ_a ∈ accessible(@κ)
ρ_b ∈ accessible(@κ)    (B : Sendable ⇒ ρ_b = _)
────────────────────────────────────────────────────────── (call-nonisolated-sync)
Γ;  @κ; α ⊢ f(arg) : B at ρ_b  ⊣  Γ₂
```

ポイント:
- **`await` 不要**: nonisolated sync は caller executor 上で実行されるため、hop が発生しない
- **環境は `Γ₂` のまま**: callee は nonisolated であり、引数を特定の actor domain に束縛しない。したがって [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) のような `toRegion(@κ)` による bind/refinement は起きない
- **`sending` パラメータの場合**: `canSend(@κ, @nonisolated, sending)` が成立するため、[`call-nonsendable-consume`](#call-nonsendable-consume) 側で消費として扱われる (本規則ではなく)
- 結果 region `ρ_b` は callee が決定し、`accessible(@κ)` に属する任意の region を取りうる

[`call-nonisolated-async-inherit`](#call-nonisolated-async-inherit) との対比:

| 観点 | `call-nonisolated-sync` | `call-nonisolated-async-inherit` |
|------|------------------------|----------------------------------|
| `await` | 不要 | 必要 (`async` のため) |
| 関数の `α'` | `sync` | `async` |
| Boundary crossing | なし | なし (caller isolation 継承) |
| Arg binding | なし (`Γ₂`) | なし (`Γ₂`) |

検証 (Swift 6.2):
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

#### 補足説明

この節は typing-rule の導出規則ではなく、既存規則の読み方を補うための補足説明である。

##### call-isolated-param-semantics

SE-0313 に関する補足。

`isolated` パラメータを持つ関数の呼び出しは、**新しい call 規則を必要としない**。
caller 側から見ると、`isolated` パラメータの actor インスタンスが関数の isolation を決定するため、
既存の `call-same-*` / `call-cross-*` 規則がそのまま適用される。

```text
// f の型: (isolated LocalActor, A) → B
// ≡ @isolated(actor) (A) → B (caller 視点)

// caller が @MainActor の場合:
//   @κ = @isolated(MainActor)
//   @ι = @isolated(actor)  (actor : LocalActor)
//   @κ ≠ @ι → call-cross-* が適用 → await 必要

// caller も同じ isolated LocalActor の場合:
//   @κ = @isolated(actor)
//   @ι = @isolated(actor)
//   @κ = @ι → call-same-* が適用 → await 不要
```

つまり `isolated` パラメータが行うことは、callee 本体では `@κ` の源泉を宣言属性から引数に変えること ([`decl-fun-isolated-param`](#decl-fun-isolated-param))、
caller 側では `@ι` を渡された actor インスタンスから導出することだけであり、
call 規則自体は既存のものがそのまま再利用される。

検証 (Swift 6.2):
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

SE-0420 に関する補足。

`isolated (any Actor)? = #isolation` パラメータに `#isolation` が (暗黙または明示的に) 渡された場合、
compiler は **call site で caller の isolation を callee に伝播**する。
これにより、callee は caller と **同一 isolation** として扱われ、`call-same-*` 規則が適用される。

```text
f : (isolated (any Actor)? = #isolation, A₁, …) α → R
argument for isolated parameter is #isolation
────────────────────────────────────────────────────
f は call site で @ι = @κ として扱われる
→ call-same-* 規則が適用 (isolation boundary を越えない)
```

これは meta-rule であり、既存の call 規則に対する **evidence mechanism** として機能する:
`#isolation` は compile-time に caller の `@κ` を callee に伝える証拠であり、
compiler はこれを根拠に same-isolation 判定を行う。

**`@isolated(any)` との決定的な違い**:

| 観点 | `@isolated(any)` 関数型 | `isolated (any Actor)? = #isolation` |
|------|------------------------|--------------------------------------|
| 種類 | 関数型 annotation (`@ι`) | パラメータ修飾子 + default argument |
| Call-site isolation | 常に **cross** (`@κ ≠ @isolated(any)` は恒真) | `#isolation` 使用時は **same** |
| `@Sendable` on closure param | 必要 (boundary crossing) | **不要** (same isolation) |
| `inout` capture | ❌ (boundary crossing) | **✅** (same isolation で mutable access 安全) |
| Non-Sendable arg | 消費 or `disconnected` 要求 | **消費されない** (same-iso) |

Note: `#isolation` の代わりに `nil` を明示的に渡すと、callee は `nonisolated` として実行される。
この場合、caller の `@κ` が actor-isolated であれば `@κ ≠ @nonisolated` → cross-isolation になり得る。

検証 (Swift 6.2):
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

`@isolated(any)` (SE-0431) の関数値は「どの actor に紐づくかが値として動的に決まる」ため、
呼び出しは **静的に hop を排除できない**。よって **sync 形でも call-site は暗黙に async になり `await` が必要** (Swift 6.2 実挙動)。

補足: `@isolated(any)` の関数値は動的 actor identity を観測するプロパティを持つ:

```text
f.isolation : (any Actor)?
```

- `nil` は「nonisolated (actor identity を持たない)」を表す
    - `task` region は actor ではないため、task-region 値を capture しても `f.isolation` は `nil` になる (後述)
- `@MainActor` 由来の関数値を `@isolated(any)` に変換すると `f.isolation` は `MainActor.shared` になる (後述)
- **注意 (型による動的 actor identity の消去)**: 一度 `() -> Void` のような *非 actor-isolated な関数型* に代入 (型変換) すると、
  その値が内部的には MainActor 上で実行される場合でも、後から `@isolated(any)` に変換しても `f.isolation` は `nil` になり得る (後述)。

**`@isolated(any)` の call semantics**

`@isolated(any)` は常に cross-isolation 的に扱われるため、専用の call 規則は不要であり、
既存の `call-cross-*` 規則がそのまま適用される (`@ι = @isolated(any)` として):

| パターン | 適用される規則 |
|----------|---------------|
| Sendable result | [`call-cross-sendable`](#call-cross-sendable) |
| `sending` result | [`call-cross-sending-result`](#call-cross-sending-result) |
| ~Sendable result without `sending` | [`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error) |

sync 形の `@isolated(any)` 関数であっても [`sync-to-async`](#sync-to-async) により暗黙に async に昇格されるため、
`call-cross-*` の `α = async` / `await` premise と整合する。

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

`@isolated(any)` 関数値の動的 actor identity を `f.isolation` として観測できることを与える規則である。

```text
Γ; @κ; α ⊢ f : @isolated(any) () → B  at ρ_f  ⊣  Γ'
────────────────────────────────────────────────────── (isolated-any-isolation-prop)
Γ; @κ; α ⊢ f.isolation : (any Actor)? at _  ⊣  Γ'
```

検証 (Swift 6.2):
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
/// `nonisolated async` 関数内で `~Sendable` 値を `@isolated(any)` クロージャにキャプチャすると、
/// task region は actor ではないため `.isolation` は `nil` になる。
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

/// `@MainActor () -> Void` → `@isolated(any) () -> Void` への変換では
/// actor identity が保持されるため、`.isolation` は `MainActor.shared` を返す。
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor() -> (any Actor)? {
    let fMain: @MainActor () -> Void = { _ = mainActorConnectedVar.value }
    let fAny: @isolated(any) () -> Void = fMain
    return fAny.isolation // Expect: MainActor.shared
}

/// `() -> Void`(nonisolated な関数型) を経由すると actor identity が消去される。
/// その後 `@isolated(any)` に変換しても isolation は復元されず、`.isolation` は `nil` になる。
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor2() -> (any Actor)? {
    let fMain: () -> Void = { _ = mainActorConnectedVar.value }
    let fAny: @isolated(any) () -> Void = fMain
    return fAny.isolation // Expect: nil (actor identity was erased by the `() -> Void` type)
}

/// `@isolated(any) () -> Void` をクロージャリテラルから直接生成した場合、
/// `@MainActor` 文脈での closure isolation inference により actor identity が保持され、
/// `.isolation` は `MainActor.shared` を返す。
@MainActor
func isolatedAny_isolationProperty_mainActorCapture_returnsMainActor3() -> (any Actor)? {
    let fAny: @isolated(any) () -> Void = { _ = mainActorConnectedVar.value }
    return fAny.isolation // Expect: MainActor.shared
}
```

### 5.7 クロージャ (Closures)

この節では closure の typing rules を述べる。
`@Sendable` capture 制約、isolation inference、属性述語、boundary 判定は「2.6 クロージャ補助定義 (`@Sendable` / isolation inference)」を参照。
capture は通常 non-consuming (消費しない) だが、クロージャ自体が `sending` として transfer される文脈では例外的に `~Sendable` の capture が消費される (後述 [`closure-sending`](#closure-sending))。

#### closure-inherit-parent

boundary でない場合、親の `@κ` を `effectiveClosureCapability` で解決した実効 capability `@κ_{eff}` で body を型チェックする:

```text
@κ_{eff} = effectiveClosureCapability(@κ, { e })
Γ_{captured} ⊆ Γ    ¬isPassedToSendingParameter({ e })
∀ (y : U at ρ) ∈ Γ_{captured}.  ρ ∈ capturable(@κ_{eff})
Γ_{captured}; @κ_{eff}; α' ⊢ e : B at ρ_{ret}  ⊣  Γ'_{cl}
ρ_{closure} = ⨆ { ρ | (y : T at ρ) ∈ Γ_{captured} ∧ T : ~Sendable }
──────────────────────────────────────────────────────────────── (closure-inherit-parent)
Γ; @κ; α ⊢ { e } : @κ_{eff} () α' → B at ρ_{closure}  ⊣  Γ
```

読み方 (要点):

- **`effectiveClosureCapability(@κ, { e })`** が実効 capability を決定する。global actor (`@MainActor` 等) と `@nonisolated` はそのまま `@κ` を返すが、**actor instance (`@isolated(localActor)`) の場合は closure body が isolated パラメータを capture しているかによって分岐する** (`capturesIsolatedParam` 参照)。capture していなければ `@nonisolated` にフォールバックする。
- `¬isPassedToSendingParameter` により、closure は `sending` パラメータに渡されていない。結論の型が `@κ_{eff} () α' → B` (`@Sendable` なし) であるため、[`closure-no-inherit-parent`](#closure-no-inherit-parent) とは結論の型パターンで区別される。`inheritActorContext` の場合も同様にこの規則が適用される。
- `Γ_{captured} ⊆ Γ` は、capture 環境 `Γ_{captured}` が現在の環境 `Γ` の部分集合であることを表す。
- `Γ_{captured}; @κ_{eff}; α' ⊢ e : ...` は「closure body を実効 capability `@κ_{eff}` と sync/async mode `α'` のもとで型チェックする」ことを表す。`Γ'_{cl}` は closure 内での消費や refinement を追跡するために現れるが、closure 生成時点では body を実行しないため、外側の環境には反映されない。
- 3 行目の条件は capture 制約である。capture した各変数の region `ρ` が `capturable(@κ_{eff})` に含まれる必要がある。たとえば `@isolated(a)` の closure は `task` region の値を capture できない (`task ∉ capturable(@isolated(a))`)。「Capture 可否」参照。
- `ρ_{closure}` は closure 値の region で、**NonSendable capture だけ**の region の join (上限) である。Sendable capture は常に `at _` なので join に参加しない。もし NonSendable capture 同士の join が `invalid` になるなら、closure 全体が compile error 状態に落ちることを表す。
- 結論が `⊣ Γ` のままなのは、通常の closure 生成が capture を消費しない (環境を変化させない) ためである。capture を消費するのは `sending` に渡す場合だけである (後述 [`closure-sending`](#closure-sending))。

検証 (Swift 6.2)— global actor (capture 不要):
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

検証 (Swift 6.2)— actor instance (capture の有無で isolation が変わる):
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

`@Sendable` closure は `toCapability(@ι)` で型チェックする:

```text
Γ_{captured} ⊆ Γ
¬inheritActorContext({ e })    ¬isPassedToSendingParameter({ e })
isAllSendable(Γ_{captured})
@κ_{cl} = toCapability(@ι)
Γ_{captured}; @κ_{cl}; α' ⊢ e : B at ρ_{ret}  ⊣  Γ'_{cl}
──────────────────────────────────────────────────────────────── (closure-no-inherit-parent)
Γ; @κ; α ⊢ { e } : @Sendable @ι () α' → B at _  ⊣  Γ
```

結論の `@Sendable @ι` はコンテキスト型 (期待型) から来る。コンパイラは contextual type の `@Sendable` を closure の型に伝播する (`CSApply.cpp`)。

前提の意味:
- `¬inheritActorContext` — `@_inheritActorContext` が付いていない (付いている場合は `@Sendable` でも [`closure-inherit-parent`](#closure-inherit-parent) が適用される)
- `¬isPassedToSendingParameter` — `sending` パラメータに渡されていない (渡されている場合は [`closure-sending`](#closure-sending) が担当)
- `isAllSendable(Γ_{captured})` — capture 環境がすべて `Sendable`
- `toCapability(@ι)` — closure の capability `@κ_{cl}` を `@ι` から決定

closure の capability の例:
- `@ι = @nonisolated` → `toCapability(@nonisolated) = @nonisolated`
- `@ι = @MainActor` → `toCapability(@MainActor) = @MainActor`

`α'` は closure body の sync/async mode。

Note (コンパイラ対応):
- `inheritActorContext` ≈ `inheritsActorContext()` (`Expr.h`)、`@_inheritActorContext` attribute が source
- `isPassedToSendingParameter` ≈ `isPassedToSendingParameter()` (`Expr.h`)、`CSApply.cpp` で設定
- `@Sendable` はコンテキスト型から伝播 (`CSApply.cpp:7637-7650`)→ `isSendable() = true`

検証 (Swift 6.2):
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

`sending` パラメータに渡されるクロージャは、常に同じ振る舞いをするわけではない。
Swift 6.2 では、**same concrete actor isolation が証明できる inherited-task case** と、**それ以外の transfer case** を分けて考える必要がある。

まず `@_inheritActorContext` により closure が caller の actor isolation を継承し、かつ caller 自身が actor-isolated なら、same-isolation `sending` と同じ理由で capture は消費されない:

```text
f : (sending (@κ_{cl} () α' → T)) → R
Γ_{captured} ⊆ Γ
inheritActorContext({ e })    isActorIsolated(@κ)    @κ_{cl} = @κ
∀ (x : U at ρ) ∈ Γ_{captured}.  ρ ∈ capturable(@κ)
Γ_{captured}; @κ_{cl}; α' ⊢ e : T at ρ_{ret}  ⊣  Γ'_{cl}
────────────────────────────────────────────────────────────── (closure-sending-noconsume)
Γ; @κ; α ⊢ f({ e }) : R at _  ⊣  Γ
```

一方、same actor を証明できない場合は transfer として扱い、`~Sendable` capture は `disconnected` でなければならず、caller 側からは消費される:

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

読み方:
- `f({ e })` は `sending` パラメータを持つ関数 `f` に closure `{ e }` を渡す呼び出し
- `closure-sending-noconsume` は same concrete actor isolation が証明できる inherited-task case を表す。capture は通常の same-isolation closure と同じく環境に残る
- `closure-sending-consume` は transfer case を表す。`Γ \ Γ'` が "消費された (=送られた) NonSendable capture" に一致する (要求: すべて disconnected)

**`@κ_{cl}` の決まり方**: `sending` パラメータを受け取る関数のシグネチャによって決まる。
ここで `@κ_{cl}` は closure の capability (`@nonisolated | @isolated(a)`) を表す:

| 構文 | `@κ_{cl}` | 理由 |
|------|-------------|------|
| `Task { ... }` | caller の `@κ` を継承 | `@_inheritActorContext` により caller の isolation を継承 |
| `Task.detached { ... }` | `@nonisolated` | `@_inheritActorContext` なし → `toCapability(@isolated(any)) = @nonisolated` |
| 一般の `f(sending closure)` | シグネチャに依存 | `sending` パラメータの型の `@ι` から `toCapability` で決まる |

Note: `Task.init` と `Task.detached` はどちらも `sending @escaping @isolated(any) () async throws -> Success` を受け取る。
違いは `Task.init` に `@_inheritActorContext` が付いていること。これにより `Task.init` は call-site の isolation を closure に継承させるが、`Task.detached` は継承しない。
したがって `Task.init` は **常に consume** ではない。actor-isolated caller からの `Task { ... }` は `closure-sending-noconsume` に入り得るが、nonisolated caller からの `Task { ... }` や `Task.detached { ... }` は `closure-sending-consume` 側に落ちる。

検証 (Swift 6.2):
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

    // @MainActor など same concrete actor isolation が証明できる Task.init は消費しない
    Task {
        _ = x.value // ✅ disconnected な NonSendable を capture できる
    }

    _ = x.value // ✅ same-actor inherited task ではまだ使える

    let y = NonSendable() // disconnected

    // Task.detached は transfer case なので capture を caller から切り離す
    Task.detached {
        _ = y.value
    }

    // _ = y.value // ❌ error: use-after-send (消費済み)
}

func taskCapture_nonisolatedTaskInitConsumesExample() {
    let x = NonSendable()

    Task {
        _ = x.value
    }

    // _ = x.value // ❌ nonisolated caller では data-race risk
}

@MainActor
var mainActorBound = NonSendable()

func detachedCannotCaptureActorBoundExample() {
    // Task.detached { _ = mainActorBound.value } // ❌ error: actor-bound は disconnected でないため capture 不可
}
```


---

### 5.8 `async let`

`async let` は構造化並行性 (structured concurrency) の基本要素であり、子タスクで初期化式を並行実行し、結果を `await` で取得する。
型システムの観点では `async let` は以下の特徴を持つ:

1. **子タスク境界**: 初期化式は暗黙の `AutoClosureExpr` (kind `AsyncLet`) でラップされ、常に `nonisolated async` として型チェックされる
2. **Sendability boundary**: autoclosure は `@Sendable` ではないが、SIL レベルの region isolation で capture の送信を追跡する (Sema レベルの `@Sendable` チェックは defer される)
3. **一時的消費 (temporary consumption)**: `~Sendable` capture は `async let` 宣言時点で子タスクに送信され、`await` 後に caller 側に戻る (SIL レベルの `undoSend`)
4. **変数アクセスの効果**: バインドされた変数 `x` の型は `T` (`Task<T, ...>` ではない) だが、アクセスには `await` が必要 (初期化式が throw 可能なら `try` も必要)

コンパイラ実装:
- 宣言: `CSApply.cpp` `wrapAsyncLetInitializer()` — autoclosure wrapping
- 境界判定: `TypeCheckConcurrency.cpp` `isSendingBoundaryForConcurrency()` — `AsyncLet` は常に boundary
- Capture: `TypeCheckConcurrency.cpp` `checkSendableInstanceMethodCaptures()` 付近 — region isolation に defer
- 効果: `TypeCheckEffects.cpp` `classifyDeclEffect()` — アクセスを async (+ throws) として分類
- SIL region: `RegionAnalysis.cpp` `translateSILPartialApplyAsyncLetBegin()` / `translateAsyncLetGet()` — send / undoSend

`Task { ... }` との違い:
- `Task.init` は `@_inheritActorContext` により caller の isolation を子タスクに継承できるが、`async let` の autoclosure は常に nonisolated 境界として扱われる
- `Task.init` で same-actor 証明ができる場合は capture が消費されない ([`closure-sending-noconsume`](#closure-sending)) が、`async let` は常に capture を送信する
- `Task.init` の消費は永続的だが、`async let` の消費は `await` 後に `undoSend` される

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

読み方:
- 結論部が `Γ; @κ; async ⊢ ...` なので、`async let` は async コンテキスト内でのみ使用可能
- 3 行目の条件は capture 制約。`~Sendable` capture は `disconnected` でなければならない。actor-bound (`isolated(a)`) な値は capture できない
- `Γ_{captured}; @nonisolated; async ⊢ expr : T ...` — 初期化式 `expr` は **nonisolated async** として子タスク内で型チェックされる。`@κ = @nonisolated` であるため、子タスク内で `@MainActor` 等の isolated state にアクセスするには `await` が必要 (cross-isolation)
- `Γ_{sent}` は `~Sendable` capture を環境から除去した結果。宣言後、`await x` までの間、capture された `~Sendable` 値は "sent" 状態であり使用できない
- `Γ'_{child}` — 初期化式 `expr` を子タスク環境で型チェックした後の出力環境。子タスク内で cross-isolation 呼び出しが発生すると、capture が consume され `Γ'_{child}` から除去される (例: `mainActorAsyncInt(x)` は nonisolated → @MainActor の cross-isolation で `x` を consume → `x ∉ dom(Γ'_{child})`)。この情報は [`async-let-access`](#async-let-access) の `undoSend` 判定で使用する
- `ρ_x` — バインドされた変数の region。`T : Sendable` なら `_`、それ以外は `disconnected` (子タスクの結果は caller にとって新鮮な値)

**`undoSend`**: `await x` (async let get) の時点で、子タスク内で cross-isolation 消費されなかった capture を caller の環境に復元する:

```text
undoSend(Γ, x) = Γ ∪ { y : U at disconnected | y ∈ sent_{async-let}(x) ∧ y ∈ dom(Γ'_{child}) }
```

ここで `dom(Γ)` は環境 `Γ` に含まれる変数名の集合 (domain) を表す。すなわち `y ∈ dom(Γ) ⇔ ∃ T, ρ. y : T at ρ ∈ Γ` である。
また、`sent_{async-let}(x)` は `async-let` 規則で `Γ` から `Γ_{sent}` に移行する際に除去された変数集合、`Γ'_{child}` は同規則の子タスク出力環境である。
条件 `y ∈ dom(Γ'_{child})` は capture `y` が子タスク内で cross-isolation consume されなかったことを表す:

| 初期化式 | `y ∈ dom(Γ'_{child})`? | 理由 |
|----------|------------------------|------|
| `nonisolatedAsyncInt(x)` | ✅ | same-isolation (nonisolated → nonisolated) — consume しない |
| `mainActorAsyncInt(x)` | ❌ | cross-isolation (nonisolated → @MainActor) — `x` は [`call-nonsendable-consume`](#call-nonsendable-consume) で consume |

この `undoSend` は SIL パス `RegionAnalysis.cpp` の `translateAsyncLetGet()` で実装されている。

#### async-let-access

`async let` でバインドされた変数へのアクセスは、通常の変数参照と異なり `await` が必要である (子タスクの完了を待つため)。同時に `undoSend` を適用し、子タスク内で cross-isolation 消費されなかった capture を復元する:

```text
(x : T at ρ) ∈ Γ    isAsyncLet(x)
Γ' = undoSend(Γ, x)
──────────────────────────────────────── (async-let-access)
Γ; @κ; async ⊢ await x : T at ρ  ⊣  Γ'
```

- この規則は結論部で `Γ; @κ; async ⊢ ...` を要求するため、`await` は async 文脈でのみ書ける
- 初期化式が throw 可能な場合は `try await x` が必要 (効果は `TypeCheckEffects.cpp` で管理)
- `ρ` は宣言時に決まった region (`_` or `disconnected`)
- `Γ' = undoSend(Γ, x)` — 子タスク内で cross-isolation 消費されなかった capture を `disconnected` として復元する。子タスク内で cross-isolation 送信された capture (`y ∉ dom(Γ'_{child})`) は復元されない

検証 (Swift 6.2):
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
// [async-let] basic: disconnected ~Sendable capture → child task に送信
func asyncLet_captureDisconnectedNonSendable_compiles() async {
    let x = NonSendable()             // x : NonSendable at disconnected
    async let y = nonisolatedAsyncInt(x)
    let _ = await y
    // After await: undoSend により x は使用可能 (nonisolated → no cross-iso send in body)
    _ = x.value  // ✅
}

// [async-let] Sendable capture は消費されない
func asyncLet_sendableCapture_doesNotConsume() async {
    let s = MySendable()
    async let y = nonisolatedAsyncInt(s)
    _ = s.value   // ✅ Sendable capture → 消費されない
    let _ = await y
    _ = s.value   // ✅
}

// [async-let] 結果型は T (Task<T, ...> ではない)
func asyncLet_resultTypeIsT_notTask() async {
    async let y: Int = nonisolatedAsyncInt(42)
    let result: Int = await y  // ✅ type of y is Int, not Task<Int, Never>
    _ = result
}

// [async-let] ~Sendable result は disconnected
// result を別の async let に再 capture できる (async let capture は disconnected を要求)
func asyncLet_nonSendableResult_isDisconnected() async {
    async let y = nonisolatedAsyncIdentity(NonSendable())
    let result = await y
    async let z = nonisolatedAsyncInt(result) // ✅ re-capture requires disconnected
    let _ = await z
}

// [async-let] scope 分離で async let result を cross-isolation 送信可能
// SIL region analysis は同一 scope 内で async let binding と result を同一 region に結びつけるため、
// do { ... } で scope を切ると region link が切れ送信可能になる
func asyncLet_nonSendableResult_scopeSeparated_canSend() async {
    let result: NonSendable
    do {
        async let y: NonSendable = NonSendable()
        result = await y
    } // async let y goes out of scope → region link severed
    await OtherActor().useNonSendableSending(result) // ✅ disconnected
}

// [async-let] @MainActor caller でも async let は nonisolated 境界
// Consumption verified by: NEGATIVE_ASYNCLET_CROSS_ISO_USE_AFTER_AWAIT
@MainActor
func asyncLet_mainActorCaller_capturesConsumed() async {
    let x = NonSendable()
    async let y = mainActorAsyncInt(x)
    let _ = await y
    // Child task は nonisolated → mainActorAsyncInt は cross-isolation → x は consume
    // undoSend は x ∉ dom(Γ'_{child}) のため復元しない
}

// ❌ await 前の使用はエラー (parent と child task の data race)
func negative_asyncLet_useBeforeAwait_isError() async {
    let x = NonSendable()
    async let y = nonisolatedAsyncInt(x)
    // _ = x.value  // ❌ sending 'x' risks causing data races
    let _ = await y
}

// ❌ cross-isolation send within body → await 後でもエラー (undoSend: x ∉ dom(Γ'_{child}))
func negative_asyncLet_crossIsolation_useAfterAwait_isError() async {
    let x = NonSendable()
    async let y = mainActorAsyncInt(x)  // child: nonisolated → @MainActor (cross-iso → x consumed)
    let _ = await y
    // _ = x.value  // ❌ x was sent to MainActor within child task
}

// ❌ task region capture: nonisolated async param (at task) は async let に capture 不可
func negative_asyncLet_taskRegionCapture_isError(_ x: NonSendable) async {
    // async let y = nonisolatedAsyncInt(x)  // ❌ task-region value cannot be sent to child task
    // let _ = await y
}

// ❌ actor-bound capture: @MainActor global (at isolated(MainActor)) は async let に capture 不可
@MainActor
func negative_asyncLet_actorBoundCapture_isError() async {
    let g = mainActorConnectedVar
    // async let y = nonisolatedAsyncInt(g)  // ❌ actor-bound value cannot exit isolation context
    // let _ = await y
}
```

---

### 5.9 Sendable Inference (SE-0418)

[SE-0418](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0418-inferring-sendable-for-methods.md) は、関数参照および KeyPath リテラルに対して `@Sendable` / `& Sendable` を推論するルールを定める。キャプチャが `Sendable` であれば (またはキャプチャが存在しなければ)`@Sendable` が推論される。

コンパイラ実装: `lib/Sema/TypeOfReference.cpp` `getTypeOfMethodReferencePost()` および `lib/Sema/ConstraintSystem.cpp` `inferKeyPathLiteralCapability()`。

#### infer-sendable-nonlocal

Non-local (トップレベル関数、static メソッド) の関数参照は、キャプチャを持たないため無条件に `@Sendable` が推論される。結果の region は `_` (Sendable)。static メソッドは宣言元の型の Sendability に関係なく `@Sendable` となる (metatype は常に `Sendable`)。

```text
isNonLocal(f)
f : (A₁, …, Aₙ) α → R
────────────────────────────────────────────────────────── (infer-sendable-nonlocal)
Γ; @κ; α' ⊢ f : @Sendable (A₁, …, Aₙ) α → R  at _  ⊣  Γ
```

検証 (Swift 6.2):
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

Unapplied メソッド参照 `T.m` は 2 段階のカリー化型 `(T) → ((A₁,…) α → R)` を持つ。コンパイラは以下の 2 つの判定を行う:

1. **外側の関数型**: 常に `@Sendable` (self はパラメータでありキャプチャではない — "fully uncurried type doesn't capture anything")
2. **内側の関数型**: `T : Sendable` の場合のみ `@Sendable` (内側の closure が `self` をキャプチャするため)

`T : Sendable` の場合、両方が `@Sendable` となる:

```text
T : Sendable
m ∈ instanceMethods(T)
m : (A₁, …, Aₙ) α → R
──────────────────────────────────────────────────────────────────────────────── (infer-sendable-method-sendable)
Γ; @κ; α' ⊢ T.m : @Sendable (T) → @Sendable ((A₁, …, Aₙ) α → R)  at _  ⊣  Γ
```

検証 (Swift 6.2):
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

`T : ~Sendable` の場合、外側は `@Sendable` (キャプチャなし) だが、内側は `@Sendable` ではない (non-Sendable な `self` をキャプチャするため):

```text
T : ~Sendable
m ∈ instanceMethods(T)
m : (A₁, …, Aₙ) α → R
────────────────────────────────────────────────────────────────── (infer-sendable-method-non-sendable)
Γ; @κ; α' ⊢ T.m : @Sendable (T) → ((A₁, …, Aₙ) α → R)  at _  ⊣  Γ
```

検証 (Swift 6.2):
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

KeyPath リテラルが actor-isolated な component を含まず、すべてのキャプチャが `Sendable` である場合、`& Sendable` が推論される。

コンパイラ実装: `ConstraintSystem.cpp` `inferKeyPathLiteralCapability()` が `isSendable` フラグを管理し、各 component を走査する。actor isolation は `ActorInstance` と `GlobalActor` のみが non-Sendable を引き起こす (`Nonisolated`, `NonisolatedUnsafe`, `CallerIsolationInheriting` は影響しない)。

```text
kp = \T.path
¬hasIsolatedKeyPathComponent(kp)
isAllSendable(captures(kp))
─────────────────────────────────────────────────────────── (infer-sendable-keypath)
Γ; @κ; α ⊢ kp : any KeyPath<T, V> & Sendable  at _  ⊣  Γ
```

検証 (Swift 6.2):
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

// 条件を満たさない場合 (& Sendable は推論されない):
// let _: any KeyPath<UserProfile, Int> & Sendable = \.age          // ❌ actor-isolated component
// let _: any KeyPath<UserProfile, String> & Sendable = \.[info]    // ❌ non-Sendable capture
```

---

---

## 6. 例 (Examples)

### 例 1: 同一 isolation (nonsending は束縛、消費しない)

- [`call-same-nonsendable-merge`](#call-same-nonsendable-merge) により `x` は消費されず、環境側で `x : ... at isolated(MainActor)` に更新される
- その結果、以後 `disconnected` を前提にする `sending` 転送 ([`call-nonsendable-consume`](#call-nonsendable-consume) 等) が成立しなくなる

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

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_merge_thenCrossSend_isError()` (`NEGATIVE_SEND_AFTER_MAINACTOR_USE`)

### 例 2: 同一 isolation (`sending` は消費しない — Same vs Cross)

[`call-nonsendable-noconsume`](#call-nonsendable-noconsume) / [`call-nonsendable-consume`](#call-nonsendable-consume) の具体例: `sending` パラメータへの渡しは `isActorIsolated(@κ) ∧ @κ = @ι` が成り立てば消費されない。これが崩れると消費が発生する。

```swift
@MainActor func useSending(_ x: sending NonSendable) {}

@MainActor
func example_sameVsCross() async {
    let x = NonSendable()

    // (1) Same isolation: call-nonsendable-noconsume → Γ₂ (消費なし)
    useSending(x)       // ✅ same isolation: not consumed
    useSending(x)       // ✅ still accessible

    // (2) Cross isolation: call-nonsendable-consume → Γ₂ \ {x} (消費)
    let other = OtherActor()
    await other.useNonSendableSending(x) // ✅ consumed here
    _ = x.value                          // ❌ error: use-after-send
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_actorBound_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_thenUse_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_thenCrossSend_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `noconsume_sameIsoSyncSending_twice_compiles()`

### 例 3: 異なる isolation (implicit transfer は消費)

`sending` キーワードがなくても、cross-isolation で `~Sendable` 値を渡すと暗黙的に消費される ([`call-nonsendable-consume`](#call-nonsendable-consume)、`canSend` の暗黙 transfer 条件)。

```swift
@MainActor
func consume_crossIsoImplicit() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendable(x)

    _ = x.value  // ❌ error: use-after-consume
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_crossIsoImplicit_compiles()`

### 例 4: 異なる isolation (explicit `sending` は消費)

明示 `sending` パラメータへの cross-isolation 渡しも同様にアフィン消費される ([`call-nonsendable-consume`](#call-nonsendable-consume))。

```swift
@MainActor
func consume_crossIsoExplicitSending() async {
    let x = NonSendable()
    let other = OtherActor()

    await other.useNonSendableSending(x)

    _ = x.value  // ❌ error: use-after-consume
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `consume_crossIsoExplicitSending_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_consume_crossIsoExplicitSending_useAfter_isError()` (`NEGATIVE_USE_AFTER_EXPLICIT_SENDING`)

### 例 5: `Task` capture (same-actor `Task.init` は保持、それ以外は consume)

`Task.init` の operation パラメータは `sending` だが、`@_inheritActorContext` により same concrete actor isolation が証明できる場合は [`closure-sending-noconsume`](#closure-sending) 側に入り、capture は消費されない。
一方、nonisolated caller の `Task.init` や `Task.detached` は [`closure-sending-consume`](#closure-sending) 側に入り、`~Sendable` capture は transfer として扱われる:

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

    // ❌ nonisolated caller では sending data-race risk
    _ = x.value
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_sameActorDisconnectedCaptureDoesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `taskInit_sameActorBoundCaptureDoesNotConsume()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskInit_useAfterSend_isError()` (`NEGATIVE_TASKINIT_USE_AFTER_SEND`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_taskDetached_useAfterSend_isError()` (`NEGATIVE_TASKDETACHED_USE_AFTER_SEND`)

### 例 6: nonisolated async 引数は `task` 的に振る舞う (SE-0461)

[`decl-fun`](#31-async-関数本体-α-の導入境界) の `ρᵢ = task` 条件 (`@ι = @nonisolated ∧ α = async ∧ Aᵢ : ~Sendable ⇒ ρᵢ = task`) により、`nonisolated async` 関数では `~Sendable` パラメータは `task` region として扱われる。
[`capturable(@κ)`](#capture-可否-capturableκ) の定義から、`task` region は nonisolated / `@isolated(any)` クロージャではキャプチャ可能だが、`@MainActor` クロージャではキャプチャできない:

```swift
// ✅ nonisolated async 内で task-isolated パラメータを nonisolated closure にキャプチャ
nonisolated func helper(_ x: NonSendable) async {
    let noniso: () -> Void = { _ = x.value }
    let isoAny: @isolated(any) () -> Void = { _ = x.value }
    _ = (noniso, isoAny)
}

// ❌ task-isolated パラメータを @MainActor closure にキャプチャ → error
nonisolated func negative(_ x: NonSendable) async {
    let _: @MainActor () -> Void = { _ = x.value }  // ❌
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedAsync_paramBehavesLikeTaskRegion()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedAsync_parameterCannotBeCapturedByMainActorClosure_isError()` (`NEGATIVE_NONISOLATED_ASYNC_PARAM_MAINACTOR_CAPTURE`)

### 例 7: `@isolated(any)` 呼び出しは sync 形でも `await` が必要 (SE-0431)

`@isolated(any)` は常に cross-isolation 的に扱われるため、既存の [`call-cross-sendable`](#call-cross-sendable) / [`call-cross-sending-result`](#call-cross-sending-result) がそのまま適用される (`@ι = @isolated(any)` として `@κ ≠ @ι` が常に成立)。
実行時まで isolation が確定しないため、sync シグネチャであっても呼び出しに `await` が必要:

```swift
@MainActor
func isolatedAny_requiresAwait() async {
    let f: @isolated(any) () -> Void = { @MainActor in }

    // @isolated(any) → 静的に isolation が不明 → await 必須
    await f()  // ✅ await required even though f is sync
}

@MainActor
func isolatedAny_returnSendingNonSendable() async {
    let f: @isolated(any) () -> sending NonSendable = { @MainActor in NonSendable() }

    let x = await f()  // ✅ sending return → safe to receive cross-isolation
    _ = x.value
}
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_call_coercedFromMainActor_requiresAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedAny_call_returnSendingNonSendable_compiles()`

### 例 8: `isolated` パラメータ — sync access + cross-isolation await (SE-0313)

[`decl-fun-isolated-param`](#decl-fun-isolated-param) により、`isolated` パラメータから `@κ = @isolated(actor)` が導出される。
(1) 同一 actor の state への sync access は [`var`](#var) 規則 + [`accessible(@κ)`](#23-region-access-accessibleκ) で許可され、 (2) 異なる actor への呼び出しは [`call-cross-sendable`](#call-cross-sendable) により `await` が必要:

```swift
// (1) isolated パラメータにより same-isolation の sync access が可能
func isolatedParam_syncAccess(actor: isolated LocalActor) {
    _ = actor.state // ✅ sync access (no `await`)
}

// (2) cross-isolation では await が必要
@MainActor
func isolatedParam_crossIsolation() async {
    let actor = LocalActor()
    _ = await actor.getState() // ✅ cross-iso → await
}
```

```text
// 導出概略:
//
// Γ₀ = { actor : LocalActor at _ }
// @κ = @isolated(actor)
//
// (1) actor.state — var: isolated(actor) ∈ accessible(@isolated(actor)) ✅ (sync, no await)
// (2) other.getState() — call-cross-sendable: @κ = @isolated(actor) ≠ @ι = @isolated(other) → await 必須
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_syncAccessInSameIsolation()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolatedParam_crossIsolation_requiresAwait()`

### 例 9: Cross-isolation NonSendable result without `sending` → error

[`call-cross-nonsending-result-error`](#call-cross-nonsending-result-error) により、`~Sendable` な結果を `sending` なしに cross-isolation で返すことは導出不能:

```swift
@MainActor
func negative_crossActor_nonSendingResult() async {
    let actor = NonSendingResultActor()

    // ❌ non-Sendable result crosses isolation boundary without `sending`
    let nonSendingResult = await actor.make()
}
```

```text
// 導出概略:
//
// @κ = @isolated(MainActor)
// @ι = @isolated(NonSendingResultActor)  (= 別 actor)
// f : @ι () → NonSendable
// NonSendable : ~Sendable, return position has no `sending`
//
// → [call-cross-nonsending-result-error](#call-cross-nonsending-result-error) 適用 → derivation fails
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_crossActor_nonSendingResult_isError()` (`NEGATIVE_RESULT`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_isolatedAny_call_returnNonSendable_isError()` (`NEGATIVE_ISOLATED_ANY_NON_SENDABLE_RESULT`)

### 例 10: `#isolation` で `@Sendable` 不要 + `inout` アクセス (SE-0420)

`#isolation` は caller の isolation を callee に伝播し、call site で `@ι = @κ` となるため [`call-same-*`](#call-same-sync-sendable) が適用される (isolation boundary なし)。
closure は non-`@Sendable` であるため [`closure-inherit-parent`](#closure-inherit-parent) により親の isolation を継承し、`@Sendable` が不要になり `inout` 変数のキャプチャも安全に行える:

```swift
// `#isolation` を使った helper 関数 (SE-0420)
func measureTime<T, E: Error>(
    _ f: () async throws(E) -> T,
    isolation: isolated (any Actor)? = #isolation
) async throws(E) -> T {
    try await f()
}

@MainActor
func isolationMacro_example() async {
    // (1) closure に @Sendable が不要
    await measureTime {
        print("same isolation as caller")
    }

    // (2) inout 変数のキャプチャが安全
    var progress = 0
    await measureTime {
        progress += 1       // ✅ inout access (same isolation)
        await Task.yield()
    }
    _ = progress

    // (3) non-Sendable キャプチャも消費されない
    let x = NonSendable()
    await measureTime {
        _ = x.value // ✅ non-Sendable captured without @Sendable
    }
    _ = x.value // ✅ still usable (same isolation)
}
```

```text
// 導出概略:
//
// caller: @κ = @isolated(MainActor), α = async
// measureTime の型: (isolation: isolated (any Actor)? = #isolation, () async throws -> T) async rethrows -> T
//
// (1) #isolation → MainActor.shared に展開
//     → callee は call site で @ι = @κ = @isolated(MainActor) として扱われる
//     → call-same-* が適用 (isolation boundary なし)
//
// (2) closure { progress += 1; await Task.yield() } は non-@Sendable
//     → [closure-inherit-parent](#closure-inherit-parent) により @κ = @isolated(MainActor) を継承
//     → mutable local `progress` の capture が安全 (same isolation)
//
// (3) measureTime 呼び出し — call-same-async(effectively)
//     → non-Sendable capture も消費されない
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_closureDoesNotNeedSendable()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_inoutVarAccessible()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `isolationMacro_nonSendableNotConsumed()`

### 例 11: Nonisolated sync — "callable from" ≠ "convertible to" (call vs capture)

[`call-nonisolated-sync`](#call-nonisolated-sync) により nonisolated sync 関数は任意の actor-isolated context から `await` なしに呼び出し可能である。しかし、この call-site の性質は関数型変換 ([`func-conv`](#func-conv)) の辺にはならない。

Closure wrapping `{ g() }` には **2 つの独立したチェック** がある:

1. **Capture check**: `g` の region が closure の isolation を跨げるか (region 依存)
2. **Call check**: closure body (`@κ`) から `g()` を呼べるか → `call-nonisolated-sync` により常に ✅

| `g` の region | `@MainActor` closure への capture | 理由 |
|---|---|---|
| `disconnected` (ローカル変数) | ✅ binding | disconnected は任意の region に束縛可能 |
| `disconnected` (`sending` パラメータ) | ✅ binding | `sending` は `disconnected` を保証 |
| `task` (通常パラメータ) | ❌ | task region は cross-isolation capture 不可 |
| `isolated(MainActor)` | ✅ same-isolation | 同一 isolation |

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
// 導出概略:
//
// (1) call-nonisolated-sync:
//     @κ = @isolated(MainActor), @ι = @nonisolated, sync
//     @κ ≠ @nonisolated ✅ → no await, no boundary crossing
//
// (3) disconnected wrapping — 2 independent checks:
//     Capture: g at disconnected → @MainActor closure = binding (disconnected は任意 region に束縛可)
//     Call:    @κ = @MainActor body → g() nonisolated sync = call-nonisolated-sync ✅
//
// (4) parameter wrapping — capture blocks:
//     Capture: g at task → @MainActor closure = cross-isolation ❌ (task は特定 actor に束縛不可)
//     Call:    would be ✅ (call-nonisolated-sync) but capture check fails first
//
// (4') sending parameter wrapping — capture succeeds:
//     Capture: g at disconnected (sending) → @MainActor closure = binding ✅
//     Call:    call-nonisolated-sync ✅
```

検証 (Swift 6.2):
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_callFromMainActor_noAwait()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_nonSendableArg_noBinding()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_sameIsolationClosureWrapping_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_disconnectedClosureWrapping_compiles()`
- `swift/Sources/concurrency-type-check/TypingRules.swift` `negative_nonisolatedSync_paramClosureWrapping_isError()` (`NEGATIVE_NONISOLATED_SYNC_PARAM_CLOSURE_WRAPPING`)
- `swift/Sources/concurrency-type-check/TypingRules.swift` `nonisolatedSync_sendingParamClosureWrapping_compiles()`
- `swift/Sources/concurrency-type-check/FuncConversionRules.swift` `CompileSyncConversionTest` `normalToMainActor` (❌ commented out)
