# Slide

Marp-based presentation slides for "Swift Concurrency Type System" talk at try! Swift Tokyo 2026.
The main content is a single Markdown file that Marp CLI converts to HTML.

Main file is in @src/swift-concurrency-type-system-slide.md which you first need to read it thoroughly.

## Commands

```bash
# Build HTML from Markdown
make

# Watch mode (auto-rebuild on save, opens browser)
make watch

# Extract speaker notes
make speaker-note

# Generate TTS audio (setup first with: make install-tts-kokoro)
make mp3 FILE=dist/speaker-note/speaker-note.txt

# Clean generated HTML
make clean
```

All commands use locally installed `./node_modules/.bin/marp` (install via `npm install`).

## Architecture

- `src/swift-concurrency-type-system-slide.md` — The sole slide source. Uses Marp front matter (`marp: true`, `math: katex`, `theme: tryswift`). Slides are separated by `---`. Speaker notes go in `<!-- -->` comments.
- `src/themes/tryswift.css` — Custom Marp theme extending `uncover`. Defines CSS classes used in slides:
  - `lead`, `small-code`, `tiny-code`, `diagram`, `big-picture`, `keyword-wall` — applied via `_class:` directive
  - `.columns` — two-column grid layout
  - `.kw`, `.ty`, `.at`, `.str`, `.cm`, `.num` — inline code syntax coloring utilities
- `src/assets/` — Media files (video, images) referenced from slides. Diagram files (SVG/PNG) are symlinks to `../docs/generated/` — run `make diagrams` from project root to generate and symlink them.
- `scripts/tts-kokoro/` — Kokoro TTS setup for generating speech audio from speaker notes

## Workflow

- **After every slide change**, regenerate all slide images into `pngs/` by running:
  ```bash
  make pngs
  ```
  This produces per-slide PNGs (`*.001.png`, `*.002.png`, …) in the `pngs/` directory. Use this to double-check visual changes and make sure styling is correct.

## Slide Authoring Conventions

- Marp directives use HTML comments: `<!-- _class: lead -->`, `<!-- _paginate: false -->`
- KaTeX math is enabled for type-system notation (e.g., `$\Gamma \vdash e : \tau$`)
- Code blocks use Swift syntax highlighting; inline colored spans use the CSS utility classes (`.kw`, `.ty`, etc.)
- The `.gitignore` excludes `*.html` — only the Markdown source and theme directory are tracked
- Local images must use HTML `<img>` tags (not Marp `![]()` syntax) for PNG export compatibility

### Conversion Table Conventions

- **Abbreviations**: `~iso` = nonisolated, `@S` = @Sendable, `@MA` = @MainActor, `@iso?` = @isolated(any), `@conc` = @concurrent, `iso(a)` = isolated LocalActor
- **Column order**: Sync table columns first (`~iso`, `@S`, `@MA`, `@MA @S`, `@iso?`, `@iso? @S`, `iso(a)`, `iso(a) @S`). Async table appends async-only columns (`@conc`, `@conc @S`) at the end.
- **Async table omits `iso(a)` rows/columns**: Same pattern as sync (self-only), noted in footnote instead

## Data Sources

- **Conversion diagrams**: Run `make diagrams` from the project root to generate sync-only, async-only, and mixed (full) conversion rule diagrams. Use `--allow-local-files` when exporting slides to PNG for preview.
- **Conversion tables**: Build sync/async function conversion rule tables from `../swift/Sources/concurrency-type-check/FuncConversionRules.swift`. Extract ✅/❌/⚠️ results from the commented-out (❌) and active (✅) function definitions.

## Parent Project

This `slide/` directory is part of a larger project (`../AGENTS.md`). The parent contains:
- `swift/` — Swift package with code examples used in slides
- `docs/` — Formal typing rules referenced by the presentation
- `swiftlang/` — Swift compiler and evolution proposal submodules for reference
