# Swift Concurrency as a Capability-Region Type System (LaTeX)

LaTeX paper derived from `docs/typing-rules-ja.md`.

## Prerequisites

```bash
brew install tectonic   # already installed
```

Tectonic auto-downloads all required LaTeX packages (`acmart`, `mathpartir`, `mdframed`, etc.) on first build.

## Build

```bash
make pdf     # build → build/main.pdf
make clean   # remove artifacts
```

## Structure

```
paper/
├── main.tex              # Root document (acmart sigplan,nonacm)
├── preamble.sty          # Custom macros (inference rules, boxed envs, shorthands)
├── sections/             # One .tex per section (13 files)
├── snippets/ → symlink   # Swift code listings (shared with Typst version)
├── figures/  → symlink   # PNG figures (shared with Typst version)
├── references.bib        # Bibliography
├── Makefile              # tectonic-based build
└── .gitignore
```

## Key packages

| Package | Purpose |
|---------|---------|
| `acmart` (sigplan, nonacm) | ACM PL-community document class |
| `mathpartir` | Inference rules (`\inferrule`) |
| `listings` | Swift code listings |
| `mdframed` | Boxed theorem-like environments |
| `cleveref` | Smart cross-references (`\Cref`) |
