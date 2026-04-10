# Swift SIL: Actor Isolation Documentation

This directory contains documentation about how Swift's actor isolation is represented in SIL (Swift Intermediate Language).

## Documents

| File | Description |
|------|-------------|
| [01-SIL-Basics.md](01-SIL-Basics.md) | SIL stages, OSSA, basic concepts |
| [02-Actor-Isolation.md](02-Actor-Isolation.md) | How actor isolation appears in SIL |
| [03-Advanced-Patterns.md](03-Advanced-Patterns.md) | `@isolated(any)`, `sending`, `@concurrent` |
| [04-Isolation-Macro.md](04-Isolation-Macro.md) | `#isolation` compiler implementation |
| [05-Ownership-Sending.md](05-Ownership-Sending.md) | `sending` with ~Copyable ownership modifiers |

## Quick Reference

### Generate SIL

```bash
# Raw SIL (OSSA form)
swiftc -emit-silgen MyFile.swift > MyFile-silgen.sil

# Canonical SIL (recommended for research)
swiftc -emit-sil MyFile.swift > MyFile-canonical.sil
```

### Key SIL Patterns

| Swift | SIL |
|-------|-----|
| `@MainActor func` | `// Isolation: global_actor. type: MainActor` |
| `actor` method | `@sil_isolated @guaranteed MyActor` |
| `sending` param | `@sil_sending @owned` |
| `@isolated(any)` | `function_extract_isolation` |
| executor switch | `hop_to_executor %actor` |

## References

- [SE-0420: Inheritance of actor isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0420-inheritance-of-actor-isolation.md)
- [SE-0430: `sending` parameter and result values](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md)
- [SE-0431: `@isolated(any)` Function Types](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any-functions.md)
- [SE-0414: Region-based Isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md)
