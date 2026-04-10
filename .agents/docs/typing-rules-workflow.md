# Typing Rules Workflow

## Goal

Make **very robust typing rules** in `docs/typing-rules-ja.md` (source of truth) and `docs/typing-rules-en.md` (English translation):

- Explicit preconditions in each rule (type constraints, capability constraints, region constraints)
- Output context discipline: Every rule that consumes variables shows `⊣ Γ'`
- Cross-references between related rules
- Verification notes with `-emit-sil` requirements where applicable

## Key Swift Evolution Proposals

| Proposal | Title | Relevant Files |
|----------|-------|----------------|
| SE-0414 | Region-based isolation | `swift/Sources/concurrency-type-check/RegionBasedIsolation.swift` |
| SE-0430 | `sending` parameter and result values | `swift/Sources/concurrency-type-check/Sending.swift` |
| SE-0431 | `@isolated(any)` function types | `swift/Tests/concurrency-type-checkTests/IsolatedAnyIsolationTests.swift` |
| SE-0461 | Nonisolated nonsending by default | `swift/Sources/concurrency-type-check/FuncConversionRules.swift` |

## CRITICAL: Function Conversion Rules — Ground Truth

Do NOT invent typing rules based on intuition or SE proposals alone — verify against actual Swift compiler behavior.

## CRITICAL: Verification Workflow

When adding/modifying typing rules in `docs/typing-rules-ja.md` (and propagating to `docs/typing-rules-en.md`):

1. Add/update a corresponding minimal experiment under `swift/Sources/concurrency-type-check/` (keep "positive" experiments always compiling under default `swift build`).
2. In the doc, add a `Verified in:` list near the relevant rule, linking to the experiment file and the exact function name.
3. In the doc, **also paste the extracted Swift snippet** so the rule + PoC is self-contained.
4. Verify with `swift build` (not `swiftc -typecheck`), because region-based isolation diagnostics can be SIL-pass dependent.
5. For expected-error checks, gate code with `#if NEGATIVE_*` and run:
   - `swift build -Xswiftc -D -Xswiftc NEGATIVE_*`

## CRITICAL: Five-Target Synchronization

Changes to typing rules touch **five targets** that must stay in sync:

| Target | Role |
|--------|------|
| `docs/typing-rules-ja.md` | **Source of truth** (Japanese). Formal rules, definitions, verification references |
| `docs/typing-rules-en.md` | English translation — must be updated whenever `-ja` changes |
| `swift/Sources/concurrency-type-check/TypingRules.swift` | Swift experiments referenced by doc |
| `slide/src/swift-concurrency-type-system-slide.md` | Marp slide (KaTeX formulas) |
| `paper/sections/*.tex` | LaTeX paper (ACM format). Key sections: `model.tex` (judgment form, definitions), `conversion-rules.tex` (conversion analysis), `kernel-rules.tex` (typing rules), `appendix-*.tex` (full rule inventory) |

### Approval-gated propagation (default)

Use this flow by default for typing-rule changes:

1. Update **only** `docs/typing-rules-ja.md` and `swift` code experiments.
2. Stop and ask for user approval/review of the `-ja` diff.
3. After explicit approval, propagate to `docs/typing-rules-en.md`, `slide`, and `paper`.
4. Do not preemptively edit `docs/typing-rules-en.md`, slide, or paper before that approval.

### Propagation flow

1. **Japanese doc is the source of truth.** Make changes in `docs/typing-rules-ja.md` (and `swift` code if needed) first.
2. **Get approval on `-ja` diff.** Ask the user to review/approve before touching other files.
3. **Translate to English.** After approval, check diff to update `docs/typing-rules-en.md` to reflect the changes in `-ja`.
4. **Propagate to slide.** After approval, check diff to apply corresponding changes to the `slide` md. The slide uses KaTeX (`$...$`) while the doc uses plain-text notation — translate accordingly.
5. **Propagate to paper.** After approval, check diff to update the relevant LaTeX sections under `paper/sections/`. The paper uses LaTeX math (`$...$`, `\textsf{}`, `\texttt{}`) and custom macros from `preamble.sty`. Key mapping: definitions/model → `model.tex`, conversion rules → `conversion-rules.tex`, typing rules → `kernel-rules.tex`, full rule inventory → `appendix-full-typing-rules.tex`, examples → `appendix-examples.tex`.
