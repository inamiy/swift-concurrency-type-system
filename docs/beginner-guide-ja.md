# Type Theory Beginner Guide (Japanese)

この文書は、logic (論理学) や type theory (型理論) の記法に初めて触れる人向けの最小限の導入である。
目標は proof theory (証明論) を体系的に学ぶことではなく、`Γ` や `⊢` のような記号を見ても止まらずに読めるようになることである。

## 1. 基本の形

型理論の文書では、まず次の形がよく現れる。

```text
Γ ⊢ e : T
```

これは judgment (判定文) であり、読みは「文脈 `Γ` のもとで、式 `e` は型 `T` を持つ」である。
記号 1 つずつの意味は次の通りである。

- `Γ` (Gamma): いま使ってよい変数とその型を並べた context / environment (文脈 / 環境)
- `e`: expression (式)
- `T`: type (型)
- `⊢`: turnstile (ターンスタイル / 導出記号)。「これらの前提のもとで、この judgment (判定文) を導く」の意味
- `:`: 「この式はこの型を持つ」

例えば `Γ` の中に `x : Int` が入っていれば、`x` は `Int` として読めるので、
`Γ ⊢ x : Int` と書ける。

## 2. `Γ` は何者か

`Γ` は「いま何を仮定してよいか」を集めた箱だと思えばよい。
中身は例えば次のような束縛である。

```text
Γ = x : Int, y : Bool
```

このとき `Γ` の中では `x` を `Int` として使ってよく、`y` を `Bool` として使ってよい。

programmer (プログラマ) 向けの直感としては、`Γ` は compiler (コンパイラ) がその時点で保持している
「名前から型への dictionary (辞書)」だと思ってよい。
この入門ではまず `name -> type` の対応として見るのが分かりやすい。

例えば Swift の次の関数を考える。

```swift
func example() {
    let count = 42
    let title = "hello"
    let isReady = true

    _ = (count, title, isReady)
}
```

この本質だけを見ると、compiler (コンパイラ) は概念的には次のような dictionary (辞書) を持っていると思える。

```text
Γ = {
  count : Int,
  title : String,
  isReady : Bool
}
```

ここで `{` と `}` は、集合の中身を囲むための記号である。

つまり `Γ` は「いまこの program point (プログラム上の地点) で、どの名前がどの型として使えるか」を表している。
通常の入門的な型システムでは、この `Γ` は固定された前提として使われ、次の行や次の式に進んでもそのまま変化しないことが多い。
一方で、式を 1 つ処理するごとに `Γ` が変わる体系もあり、そのような見方が後で触れる affine type system (アファイン型システム) につながっていく。

## 3. premise と conclusion (前提と結論)

型付け規則は、たいてい次の形の inference rule (推論規則) で書かれる。

```text
premise 1    premise 2
────────────────────── (rule-name)
conclusion
```

横線の上は premise (前提)、横線の下は conclusion (結論) である。
読み方は単純で、「上の前提がすべて成り立つなら、下の結論を導いてよい」である。

末尾の `(rule-name)` は rule name (規則名) であり、後でその規則を参照するためのラベルである。

## 4. Simply typed lambda calculus (単純型付きラムダ計算)

Simply typed lambda calculus (単純型付きラムダ計算) は、型付き関数の最小モデルだと思えばよい。
ここでは 3 つだけ押さえれば十分である。

### 4.1 Variable (変数)

```text
x : T ∈ Γ
────────── (var)
Γ ⊢ x : T
```

`Γ` に束縛 `x : T` が入っているなら、現在の文脈では名前 `x` を式として評価 / 参照 / 使用してよく、その結果の型は `T` になる。
したがって `var` 規則は、「宣言済みの名前は、その型どおりに使える」という最も基本の規則だと思えばよい。
ここで `∈` は、集合論の記号として「...は ... の要素である」を表す。

### 4.2 Lambda abstraction (ラムダ抽象)

```text
Γ, x : A ⊢ e : B
──────────────────────── (abs)
Γ ⊢ λx : A. e : A → B
```

仮に `x` を `A` として使って body (本体) `e` をチェックし、その結果が `B` なら、
関数 `λx : A. e` は `A → B` 型になる。

ここで `λ` は lambda (ラムダ) 記号であり、「anonymous function (無名関数) を作る」という意味だと思えばよい。
`λx : A. e` は、ざっくり言えば「引数 `x` を受け取り、本体 `e` を返す関数」を表している。

部分ごとに読むと、次のようになる。

- `λ`: いまから関数を作る、という印
- `x : A`: 引数 `x` の型は `A`
- `.`: 引数宣言と本体の区切り
- `e`: その関数の body (本体)
- `A → B`: その関数全体の型。`A` を受け取って `B` を返す

`A → B` は、「A から B への関数型」と読めばよい。
つまり「入力が `A` で、出力が `B` の関数」という意味である。
Swift でいえば `(A) -> B` に対応する。

Swift で最も近い直感は closure (クロージャ) である。
例えば

```text
λx : Int. x + 1
```

は、Swift では概念的には次のような closure に近い。

```swift
let f: (Int) -> Int = { (x: Int) in
    x + 1
}
```

つまり、simply typed lambda calculus の lambda abstraction は、
Swift で言えば「名前のない関数値」や「closure literal」にかなり近い。
もちろん Swift には capture、effect、ownership など追加要素があるが、
初学者の入口としては「`λ` は closure を書く記号」と捉えて良い。

### 4.3 Application (適用)

```text
Γ ⊢ f : A → B    Γ ⊢ a : A
─────────────────────────── (app)
Γ ⊢ f a : B
```

関数 `f` が `A → B` 型で、引数 `a` が `A` 型なら、適用 `f a` は `B` 型になる。

この 3 つが読めれば、多くの型理論文書の最初の数ページは追えることが多い。

## 5. よく出る専門用語

- judgment (判定文): 「ある前提のもとで成り立つ文」
- context / environment (文脈 / 環境): 変数と型の仮定の集まり
- premise (前提): 規則の上にある前提
- conclusion (結論): 規則の下にある結論
- derivation (導出): 規則を積み重ねて結論を導くこと
- metavariable (メタ変数): `Γ`, `e`, `T`, `A`, `B` のように、具体的な構文そのものではなく「何かが入る場所」を表す記号

## 6. 最低限の読み方まとめ

次の 3 点だけ覚えておけば、初学者としては十分な出発点になる。

1. `Γ ⊢ e : T` は「`Γ` のもとで `e` は `T` 型」である。
2. 横線の上は premise (前提)、下は conclusion (結論) である。
3. 横線は、「上の前提から下の結論を導く」という規則の形を表している。

ここまで理解できれば、より複雑な type-system の文書でも、まず記号の意味で止まらずに読み始められる。

## 7. `docs/typing-rules-ja.md` への sneak peek

ここまでは、`Γ` を「compiler (コンパイラ) がいま持っている `name -> type` の dictionary (辞書)」と見る単純な話に絞った。
ただし、この repository (リポジトリ) の本編である `docs/typing-rules-ja.md` では、
その dictionary が **式を 1 行読むごとに変化する**ところまで追跡する。

そこで judgment (判定文) の形も少し豊かになる。

```text
Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'
```

ここでの `Γ` は「式を読む前」の environment (環境)、`Γ'` は「式を読んだ後」の environment (環境) である。
つまり compiler (コンパイラ) の dictionary (辞書) が line by line で更新される様子を、そのまま記号に出している。

その直感をつかむうえでは、Swift Concurrency よりも Swift Ownership (所有権) のほうが分かりやすい。
例えば NonCopyable (非コピー可能) な値を `consuming` パラメータへ渡すと、caller (呼び出し側) ではその値をもう使えない。

```swift
struct Token: ~Copyable {}

func take(_ token: consuming Token) {}

func example() {
    let token = Token()
    take(token)
    // _ = token // ❌ already consumed
}
```

直感的には、compiler (コンパイラ) の dictionary (辞書) は次のように変わると見なせる。

```text
Γ₀ = { token : Token }
Γ₀ ⊢ take(token) ⊣ Γ₁
Γ₁ = Γ₀ \ { token : Token }
```

ここで `\` は set difference (差集合) を表す。
つまり `Γ₀ \ { token : Token }` は、「`Γ₀` から束縛 `token : Token` を取り除いたもの」という意味である。

最初は `token` が dictionary (辞書) に入っているが、ownership (所有権) を渡した後は `token` をそのまま再利用できないので、
出力側の `Γ₁` では `token` が消えている。
この「使うと環境が縮みうる」という性質が、`docs/typing-rules-ja.md` で出てくる **Affine Type System (アファイン型システム)** の入口である。

本編ではこの直感を、Swift Concurrency の `sending`、region (領域)、isolation (隔離) まで含めて、より formal (形式的) に追跡する。
つまり ownership (所有権) で見た「consume (消費) すると environment (環境) から消える」という形が、concurrency の規則でも再登場する。

この beginner guide ではここまでを sneak peek に留める。
本編では、この `Γ → Γ'` の変化を rule (規則) ごとに formal (形式的) に書いていく。

## 8. もっと学ぶには

この文書が読めたあとに、型理論をもう少し体系的に学びたければ、次の順で学ぶのがおすすめである。

1. [Swift and Logic, and Category Theory](https://speakerdeck.com/inamiy/swift-and-logic-and-category-theory)
   Swift と論理学とのつながりを理解するためのスライド（圏論の章は飛ばして良い）。
2. **「記号論理学」「型付きラムダ計算」** 等のキーワードについて AI に質問したり、
   **専門家が書いた PDF 資料や講義ノート** をネット検索して読みながら AI と壁打ち
3. *Types and Programming Languages* (Benjamin C. Pierce)
   型付き言語の標準的な入門書。typing rule、operational semantics、type safety を本格的に学ぶ最初の 1 冊としてよい。
4. *Advanced Topics in Types and Programming Languages* (Benjamin C. Pierce)
   *Types and Programming Languages* の次に進むための上級編。 Swift Concurrency の理解に必要な Affine Types や Region の話題が登場する。

最初の専門的な 1 冊を購入するなら、まずは *Types and Programming Languages* が最も自然である。
