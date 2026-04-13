# Swift Concurrency Type System - try! Swift Tokyo 2026

Formal typing rules and presentation materials for Swift 6.2's concurrency type system, focusing on **Capability** (where code runs) and **Region** (where data lives).

Presented at [try! Swift Tokyo 2026](https://tryswift.jp/).

Slide (HTML): https://inamiy.github.io/swift-concurrency-type-system/slide.html

## Outputs

| Format | File | Description |
|--------|------|-------------|
| Slide (PDF) | [swift-concurrency-type-system-slide.pdf](swift-concurrency-type-system-slide.pdf) | Marp slide deck |
| Paper (PDF) | [swift-concurrency-type-system-paper.pdf](swift-concurrency-type-system-paper.pdf) | LaTeX paper (ACM sigplan format) |
| Typing Rules (JA) | [docs/typing-rules-ja.md](docs/typing-rules-ja.md) | Source of truth (Japanese) |
| Typing Rules (EN) | [docs/typing-rules-en.md](docs/typing-rules-en.md) | English translation |

## Key Concepts

The judgment form central to the type system:

```
Γ; @κ; α ⊢ e : T at ρ  ⊣  Γ'
```

| Symbol | Role | Examples |
|--------|------|----------|
| `@κ` (Capability) | Where code **runs** | `@nonisolated`, `@MainActor` |
| `ρ` (Region) | Where data **lives** | `disconnected`, `isolated(a)`, `task` |
| `Γ → Γ'` | Affine discipline | Region merge refines, transfer shrinks |

Covers function conversion rules, `sending` as affine transfer, region merge as context refinement, and closure isolation inference.

## Key Swift Evolution Proposals

| Proposal | Title |
|----------|-------|
| [SE-0414](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md) | Region-based Isolation |
| [SE-0430](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md) | `sending` parameter and result values |
| [SE-0431](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md) | `@isolated(any)` function types |
| [SE-0461](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0461-async-function-isolation.md) | Nonisolated nonsending by default |

## Project Structure

```
./
├── docs/                   # Formal typing rules & conversion diagrams
│   ├── typing-rules-ja.md  # Source of truth (Japanese)
│   ├── typing-rules-en.md  # English translation (must be kept in sync with -ja)
│   ├── scripts/             # Helper scripts (markdown-toc, Mermaid splitter)
│   └── diagrams/            # Mermaid diagram sources
├── swift/                  # SwiftPM package (swift-tools-version: 6.2, Swift 6 mode)
│   ├── Sources/
│   │   └── concurrency-type-check/  # Isolation/region/sending experiments
│   └── Tests/
│       └── concurrency-type-checkTests/
├── swift-sil/              # SIL dump analysis (Swift source + emitted SIL pairs)
│   └── docs/               # SIL reading guides
├── slide/                  # Marp-based presentation (md -> html via marp-cli)
│   ├── src/                # Slide source (md, themes, assets)
│   └── scripts/            # Build scripts (mermaid splitter, TTS)
├── paper/                  # LaTeX paper (ACM sigplan format via tectonic)
└── swiftlang/              # Git submodules (read-only reference, git-ignored)
    ├── swift/              # Official Swift compiler source
    └── swift-evolution/    # Swift Evolution proposals
```

## Commands

| Command | Description |
|---------|-------------|
| `make setup` | Install npm deps and generate Mermaid diagrams |
| `make -C slide html` | Build slide HTML into `slide/dist/` |
| `make -C slide pdf` | Build slide PDF into `slide/dist/` |
| `make -C paper pdf` | Build paper PDF via tectonic |
| `make markdown-toc` | Regenerate table of contents in typing rules docs |
| `make diagrams` | Regenerate Mermaid diagrams only |
| `make clean` | Remove all build artifacts |
| `cd swift && swift build` | Build Swift package |
| `cd swift && swift test` | Run Swift tests |

## Guidelines [CRITICAL]

- [Typing Rules Workflow](./.agents/docs/typing-rules-workflow.md) — Rules for creating/modifying typing rules and verification
- For Swift internals, type checker behavior, SIL, or language evolution, consult the `swiftlang/` directory.
- Use English as a default language for any file output except filenames suffixed with `-{lang}.{ext}`.
- Avoid section-number cross-references (e.g. "(§3.8.1)") in documentation; prefer heading titles or rule names.
- Use ASCII parentheses `()` instead of full-width parentheses `（）` in all documentation files.
- In `docs` markdown files, DO NOT manually edit "Table of Contents" sections unless explicitly requested, which is auto-generated.

## License

[MIT](LICENSE)
